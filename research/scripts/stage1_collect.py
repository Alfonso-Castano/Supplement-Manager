#!/usr/bin/env python3
"""
Stage 1: Collection — NIH ODS, MedlinePlus, MSK
Reads research/target_list.json, fetches source pages, saves to research/raw/.
Fully resumable: already_collected() skips existing non-empty files.
Rate limit: 1s between requests (government/academic resources).
"""
import json
import os
import sys
import time
from pathlib import Path
import requests
from bs4 import BeautifulSoup

# Add project root to sys.path so 'research.scripts.utils' resolves
sys.path.insert(0, str(Path(__file__).parents[2]))
from research.scripts.utils import already_collected, load_checkpoint, save_checkpoint, save_json_atomic

RESEARCH_DIR = Path("research")
RAW_DIR = RESEARCH_DIR / "raw"
TARGET_LIST_PATH = RESEARCH_DIR / "target_list.json"

HEADERS = {
    "User-Agent": "StackWise-Research/1.0 (supplement interaction database; contact: alfonsocastano486@gmail.com)"
}


def fetch_text(url: str, session: requests.Session) -> str | None:
    """Fetch a URL and return its plain text content, or None on error."""
    try:
        resp = session.get(url, headers=HEADERS, timeout=30)
        resp.raise_for_status()
        soup = BeautifulSoup(resp.text, "lxml")
        return soup.get_text(separator='\n').strip()
    except Exception as e:
        print(f"  ERROR fetching {url}: {e}")
        return None


def save_raw(output_dir: Path, filename: str, url: str, content: str) -> None:
    """Save source URL as line 1, then content. Uses atomic write."""
    output_dir.mkdir(parents=True, exist_ok=True)
    path = output_dir / filename
    tmp = path.with_suffix(".tmp")
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(url + "\n")
        f.write(content)
    os.replace(tmp, path)


def collect_nih_ods(target_list: dict, session: requests.Session) -> dict:
    """Fetch NIH ODS fact sheets for supplements that have nih_ods_url set."""
    out_dir = RAW_DIR / "nih_ods"
    results = {"collected": [], "skipped": [], "missing": [], "errors": []}

    for compound in target_list["supplements"]:
        name = compound["canonical_name"]
        url = compound.get("nih_ods_url")

        if not url:
            results["missing"].append(name)
            continue

        if already_collected(out_dir, name):
            results["skipped"].append(name)
            print(f"  SKIP (exists): nih_ods/{name}.txt")
            continue

        print(f"  Fetching NIH ODS: {name}")
        content = fetch_text(url, session)
        if content:
            save_raw(out_dir, f"{name}.txt", url, content)
            results["collected"].append(name)
        else:
            results["errors"].append(name)
        time.sleep(1)

    return results


def collect_medlineplus(target_list: dict, session: requests.Session) -> dict:
    """Fetch MedlinePlus herb index and collect pages for target supplements."""
    out_dir = RAW_DIR / "medlineplus"
    results = {"collected": [], "skipped": [], "not_found": [], "errors": []}

    index_url = "https://medlineplus.gov/druginfo/herb_All.html"
    print(f"  Fetching MedlinePlus index: {index_url}")
    try:
        resp = session.get(index_url, headers=HEADERS, timeout=30)
        resp.raise_for_status()
        soup = BeautifulSoup(resp.text, "lxml")
    except Exception as e:
        print(f"  ERROR fetching MedlinePlus index: {e}")
        return results

    # Collect all herb links from the index
    # Links go to nccih.nih.gov/health/ and ODS Consumer pages
    herb_links = {}
    for a in soup.find_all("a", href=True):
        href = a["href"]
        text = a.get_text().strip().lower()
        if not text:
            continue
        # MedlinePlus herb index links to NCCIH and ODS Consumer pages
        if (
            "nccih.nih.gov/health/" in href
            or "/druginfo/natural/" in href
            or ("/factsheets/" in href and "Consumer" in href)
            or "cancer.gov/about-cancer/treatment/cam" in href
        ):
            herb_links[text] = href if href.startswith("http") else f"https://medlineplus.gov{href}"

    time.sleep(1)

    # Load canonical_names to resolve supplement names to index entries
    with open(RESEARCH_DIR / "canonical_names.json") as f:
        canonical = json.load(f)

    target_names = {c["canonical_name"] for c in target_list["supplements"]}

    for name in sorted(target_names):
        if already_collected(out_dir, name):
            results["skipped"].append(name)
            print(f"  SKIP (exists): medlineplus/{name}.txt")
            continue

        # Try to find the herb by canonical name or aliases
        raw_val = canonical.get(name, [])
        aliases = raw_val.get("aliases", []) if isinstance(raw_val, dict) else raw_val
        all_names = [name.replace("_", " ")] + [a.replace("_", " ") for a in aliases]
        found_url = None
        for variant in all_names:
            variant_lower = variant.lower()
            # 1. Exact match first
            if variant_lower in herb_links:
                found_url = herb_links[variant_lower]
                break
            # 2. Partial match: link_text starts with our name (avoid false positives)
            for link_text, link_url in herb_links.items():
                # Only match if the link text starts with or exactly equals the variant
                # This prevents "nac" from matching "niacin", "vitamin b" matching "vitamin b12", etc.
                if link_text.startswith(variant_lower) or variant_lower.startswith(link_text):
                    # Reject if lengths differ too much (e.g. "nac" matching "niacin")
                    if abs(len(link_text) - len(variant_lower)) <= 5:
                        found_url = link_url
                        break
            if found_url:
                break

        if not found_url:
            results["not_found"].append(name)
            continue

        print(f"  Fetching MedlinePlus: {name} -> {found_url}")
        content = fetch_text(found_url, session)
        if content:
            save_raw(out_dir, f"{name}.txt", found_url, content)
            results["collected"].append(name)
        else:
            results["errors"].append(name)
        time.sleep(1)

    return results


def collect_msk(target_list: dict, session: requests.Session) -> dict:
    """Crawl MSK About Herbs: paginate index, collect herb URLs, fetch each."""
    out_dir = RAW_DIR / "msk"
    results = {"collected": [], "skipped": [], "not_found": [], "errors": []}
    base = "https://www.mskcc.org"

    # Step 1: Collect all herb URLs from paginated index (pages 0-30)
    herb_urls: dict = {}  # herb_name_slug -> full_url
    print("  Collecting MSK herb index (pages 0-30)...")
    for page in range(31):
        page_url = f"{base}/cancer-care/diagnosis-treatment/symptom-management/integrative-medicine/herbs/search?page={page}"
        try:
            resp = session.get(page_url, headers=HEADERS, timeout=30)
            resp.raise_for_status()
            soup = BeautifulSoup(resp.text, "lxml")
            for a in soup.find_all("a", href=True):
                href = a["href"]
                if "/cancer-care/integrative-medicine/herbs/" in href and href != "/cancer-care/integrative-medicine/herbs/search":
                    slug = href.rstrip("/").split("/")[-1]
                    full_url = href if href.startswith("http") else base + href
                    herb_urls[slug] = full_url
        except Exception as e:
            print(f"  ERROR fetching MSK page {page}: {e}")
        time.sleep(1)

    print(f"  MSK index collected: {len(herb_urls)} herb URLs found")

    # Load canonical_names for alias resolution
    with open(RESEARCH_DIR / "canonical_names.json") as f:
        canonical = json.load(f)

    target_names = {c["canonical_name"] for c in target_list["supplements"]}

    # Step 2: Match target compounds to collected herb URLs
    for name in sorted(target_names):
        if already_collected(out_dir, name):
            results["skipped"].append(name)
            print(f"  SKIP (exists): msk/{name}.txt")
            continue

        # Try canonical name and aliases as URL slugs
        raw_val = canonical.get(name, [])
        aliases = raw_val.get("aliases", []) if isinstance(raw_val, dict) else raw_val
        all_variants = [name.replace("_", "-"), name.replace("_", " ")]
        all_variants += [a.replace(" ", "-").lower() for a in aliases]

        # First: try direct msk_url from target_list (most reliable)
        found_url = None
        for compound in target_list["supplements"]:
            if compound["canonical_name"] == name and compound.get("msk_url"):
                found_url = compound["msk_url"]
                print(f"  Using msk_url from target_list for {name}: {found_url}")
                break

        # Second: try exact slug match from index
        if not found_url:
            for variant in all_variants:
                if variant in herb_urls:
                    found_url = herb_urls[variant]
                    break

        if not found_url:
            results["not_found"].append(name)
            continue

        print(f"  Fetching MSK: {name} -> {found_url}")
        content = fetch_text(found_url, session)
        if content:
            save_raw(out_dir, f"{name}.txt", found_url, content)
            results["collected"].append(name)
        else:
            results["errors"].append(name)
        time.sleep(1)

    return results


def print_gate_summary(nih_results, ml_results, msk_results):
    print("\n" + "=" * 60)
    print("=== Stage 1 (HTML Sources) Complete — Human Gate ===")
    print("=" * 60)
    print(f"\nNIH ODS:")
    print(f"  Collected: {len(nih_results['collected'])}")
    print(f"  Skipped (existed): {len(nih_results['skipped'])}")
    print(f"  No ODS URL in target list: {len(nih_results['missing'])}")
    if nih_results['missing']:
        for m in nih_results['missing']:
            print(f"    - {m}")
    print(f"  Errors: {len(nih_results['errors'])}")
    if nih_results['errors']:
        for e in nih_results['errors']:
            print(f"    - {e}")

    print(f"\nMedlinePlus:")
    print(f"  Collected: {len(ml_results['collected'])}")
    print(f"  Skipped (existed): {len(ml_results['skipped'])}")
    print(f"  Not found in index: {len(ml_results['not_found'])}")
    if ml_results['not_found']:
        for m in ml_results['not_found']:
            print(f"    - {m}")
    print(f"  Errors: {len(ml_results['errors'])}")

    print(f"\nMSK About Herbs:")
    print(f"  Collected: {len(msk_results['collected'])}")
    print(f"  Skipped (existed): {len(msk_results['skipped'])}")
    print(f"  Not found in herb index: {len(msk_results['not_found'])}")
    if msk_results['not_found']:
        for m in msk_results['not_found']:
            print(f"    - {m}")
    print(f"  Errors: {len(msk_results['errors'])}")

    print(f"\nRaw files on disk:")
    nih_count = len(list((RAW_DIR / 'nih_ods').glob('*.txt')))
    ml_count = len(list((RAW_DIR / 'medlineplus').glob('*.txt')))
    msk_count = len(list((RAW_DIR / 'msk').glob('*.txt')))
    print(f"  research/raw/nih_ods/: {nih_count} files")
    print(f"  research/raw/medlineplus/: {ml_count} files")
    print(f"  research/raw/msk/: {msk_count} files")

    # Compounds not found in ANY HTML source
    nih_found = set(nih_results['collected'] + nih_results['skipped'])
    ml_found = set(ml_results['collected'] + ml_results['skipped'])
    msk_found = set(msk_results['collected'] + msk_results['skipped'])
    all_found = nih_found | ml_found | msk_found

    # Get all target names from nih_results + ml_results + msk_results
    all_targets = set(
        nih_results['collected'] + nih_results['skipped'] + nih_results['missing'] + nih_results['errors'] +
        ml_results['collected'] + ml_results['skipped'] + ml_results['not_found'] + ml_results['errors'] +
        msk_results['collected'] + msk_results['skipped'] + msk_results['not_found'] + msk_results['errors']
    )
    not_in_any = all_targets - all_found
    if not_in_any:
        print(f"\nNOT FOUND in any HTML source ({len(not_in_any)} compounds):")
        print("  (These will need PubMed gap-filling in Stage 3)")
        for c in sorted(not_in_any):
            print(f"    - {c}")


if __name__ == "__main__":
    with open(TARGET_LIST_PATH) as f:
        target_list = json.load(f)

    session = requests.Session()

    print("=== Stage 1: Collection (NIH ODS + MedlinePlus + MSK) ===")
    print(f"Target: {len(target_list['supplements'])} supplements\n")

    print("\n--- NIH ODS ---")
    nih_results = collect_nih_ods(target_list, session)

    print("\n--- MedlinePlus ---")
    ml_results = collect_medlineplus(target_list, session)

    print("\n--- MSK About Herbs ---")
    msk_results = collect_msk(target_list, session)

    print_gate_summary(nih_results, ml_results, msk_results)
