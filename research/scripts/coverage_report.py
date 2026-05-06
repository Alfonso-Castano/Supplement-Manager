#!/usr/bin/env python3
import json
from collections import Counter

with open("research/interactions.json") as f:
    records = json.load(f)

with open("research/target_list.json") as f:
    tl = json.load(f)

meds = [m["canonical_name"] for m in tl["medications"]]
supps = [s["canonical_name"] for s in tl["supplements"]]

print("Total records: " + str(len(records)))
print()

print("=== MEDICATIONS (20 in scope) ===")
for med in sorted(meds):
    hits = [r for r in records if r.get("compound_b") == med or r.get("compound_a") == med]
    supplements_involved = set()
    for r in hits:
        other = r["compound_a"] if r["compound_b"] == med else r["compound_b"]
        supplements_involved.add(other)
    supps_str = ", ".join(sorted(supplements_involved)) if supplements_involved else "none"
    print("  " + med + ": " + str(len(hits)) + " records  [" + supps_str + "]")

print()
print("=== SUPPLEMENTS (50 in scope) ===")
covered = 0
zero = []
for s in sorted(supps):
    hits = [r for r in records if r.get("compound_a") == s or r.get("compound_b") == s]
    if hits:
        covered += 1
    else:
        zero.append(s)
print("Covered: " + str(covered) + "/50")
print("Zero coverage: " + ", ".join(zero))

print()
print("=== BY CONFIDENCE ===")
c = Counter(r.get("confidence") for r in records)
print(str(dict(c)))
print("=== BY INTERACTION TYPE ===")
t = Counter(r.get("interaction_type") for r in records)
print(str(dict(t)))
