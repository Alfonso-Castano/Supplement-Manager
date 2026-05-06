"""
Stage 0 Pre-flight setup script.
Generates target_list.json, canonical_names.json, action_templates.json, and checkpoint.json.

Usage:
    python research/scripts/stage0_setup.py           # create if not exists
    python research/scripts/stage0_setup.py --force   # overwrite even if exists
    python research/scripts/stage0_setup.py --verify  # verify artifacts only, no write
"""

import argparse
import json
import sys
from pathlib import Path

# Allow running from project root
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from research.scripts.utils import load_checkpoint, save_checkpoint, save_json_atomic

RESEARCH_DIR = Path("research")

# ---------------------------------------------------------------------------
# Target list data
# ---------------------------------------------------------------------------

SUPPLEMENTS = [
    # Tier 1 — Confirmed top supplements by ConsumerLab 2025 survey
    {
        "canonical_name": "vitamin_d3",
        "item_type": "supplement",
        "category": "vitamin",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/VitaminD-HealthProfessional/",
        "msk_url": None,
        "notes": None,
    },
    {
        "canonical_name": "magnesium",
        "item_type": "supplement",
        "category": "mineral",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/Magnesium-HealthProfessional/",
        "msk_url": None,
        "notes": None,
    },
    {
        "canonical_name": "omega_3_fatty_acids",
        "item_type": "supplement",
        "category": "fatty_acid",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/Omega3FattyAcids-HealthProfessional/",
        "msk_url": None,
        "notes": None,
    },
    {
        "canonical_name": "vitamin_c",
        "item_type": "supplement",
        "category": "vitamin",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/VitaminC-HealthProfessional/",
        "msk_url": None,
        "notes": None,
    },
    {
        "canonical_name": "vitamin_b12",
        "item_type": "supplement",
        "category": "vitamin",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/VitaminB12-HealthProfessional/",
        "msk_url": None,
        "notes": None,
    },
    {
        "canonical_name": "zinc",
        "item_type": "supplement",
        "category": "mineral",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/Zinc-HealthProfessional/",
        "msk_url": None,
        "notes": None,
    },
    {
        "canonical_name": "probiotic",
        "item_type": "supplement",
        "category": "probiotic",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/Probiotics-HealthProfessional/",
        "msk_url": None,
        "notes": "Single canonical entry representing common Lactobacillus/Bifidobacterium strains per D-13. Known interactions (antibiotic timing) apply generically.",
    },
    {
        "canonical_name": "melatonin",
        "item_type": "supplement",
        "category": "hormone",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/Melatonin-HealthProfessional/",
        "msk_url": None,
        "notes": None,
    },
    {
        "canonical_name": "ashwagandha",
        "item_type": "supplement",
        "category": "botanical",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/Ashwagandha-HealthProfessional/",
        "msk_url": None,
        "notes": None,
    },
    {
        "canonical_name": "coenzyme_q10",
        "item_type": "supplement",
        "category": "antioxidant",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/Coenzyme_Q10-HealthProfessional/",
        "msk_url": None,
        "notes": None,
    },
    {
        "canonical_name": "iron",
        "item_type": "supplement",
        "category": "mineral",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/Iron-HealthProfessional/",
        "msk_url": None,
        "notes": None,
    },
    {
        "canonical_name": "vitamin_e",
        "item_type": "supplement",
        "category": "vitamin",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/VitaminE-HealthProfessional/",
        "msk_url": None,
        "notes": None,
    },
    {
        "canonical_name": "turmeric_curcumin",
        "item_type": "supplement",
        "category": "botanical",
        "nih_ods_url": None,
        "msk_url": "https://www.mskcc.org/cancer-care/integrative-medicine/herbs/turmeric",
        "notes": "NIH ODS covers turmeric via MedlinePlus; MSK is primary source",
    },
    {
        "canonical_name": "vitamin_a",
        "item_type": "supplement",
        "category": "vitamin",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/VitaminA-HealthProfessional/",
        "msk_url": None,
        "notes": None,
    },
    {
        "canonical_name": "collagen",
        "item_type": "supplement",
        "category": "amino_acid",
        "nih_ods_url": None,
        "msk_url": "https://www.mskcc.org/cancer-care/integrative-medicine/herbs/collagen",
        "notes": "No NIH ODS fact sheet; MSK is primary source",
    },
    {
        "canonical_name": "biotin",
        "item_type": "supplement",
        "category": "vitamin",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/Biotin-HealthProfessional/",
        "msk_url": None,
        "notes": "Notable for lab test interference (D-09 interaction relevance)",
    },
    {
        "canonical_name": "vitamin_k2",
        "item_type": "supplement",
        "category": "vitamin",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/VitaminK-HealthProfessional/",
        "msk_url": None,
        "notes": "K2 (menaquinone); NIH ODS covers all vitamin K forms together",
    },
    {
        "canonical_name": "folic_acid",
        "item_type": "supplement",
        "category": "vitamin",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/Folate-HealthProfessional/",
        "msk_url": None,
        "notes": "Critical for methotrexate interactions",
    },
    {
        "canonical_name": "vitamin_b6",
        "item_type": "supplement",
        "category": "vitamin",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/VitaminB6-HealthProfessional/",
        "msk_url": None,
        "notes": "Notable for levodopa interactions",
    },
    {
        "canonical_name": "calcium",
        "item_type": "supplement",
        "category": "mineral",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/Calcium-HealthProfessional/",
        "msk_url": None,
        "notes": None,
    },
    {
        "canonical_name": "vitamin_b_complex",
        "item_type": "supplement",
        "category": "vitamin",
        "nih_ods_url": None,
        "msk_url": None,
        "notes": "Composite product; individual B vitamins have separate ODS entries. Interactions apply to constituent vitamins.",
    },
    {
        "canonical_name": "green_tea_extract",
        "item_type": "supplement",
        "category": "botanical",
        "nih_ods_url": None,
        "msk_url": "https://www.mskcc.org/cancer-care/integrative-medicine/herbs/green-tea",
        "notes": None,
    },
    {
        "canonical_name": "berberine",
        "item_type": "supplement",
        "category": "botanical",
        "nih_ods_url": None,
        "msk_url": "https://www.mskcc.org/cancer-care/integrative-medicine/herbs/berberine",
        "notes": "Known drug interactions with metformin (additive effect)",
    },
    {
        "canonical_name": "alpha_lipoic_acid",
        "item_type": "supplement",
        "category": "antioxidant",
        "nih_ods_url": None,
        "msk_url": "https://www.mskcc.org/cancer-care/integrative-medicine/herbs/alpha-lipoic-acid",
        "notes": "Interactions with diabetes medications",
    },
    {
        "canonical_name": "ginkgo_biloba",
        "item_type": "supplement",
        "category": "botanical",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/GinkgoBiloba-HealthProfessional/",
        "msk_url": None,
        "notes": "Major anticoagulant interactions",
    },
    {
        "canonical_name": "st_johns_wort",
        "item_type": "supplement",
        "category": "botanical",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/StJohnsWort-HealthProfessional/",
        "msk_url": None,
        "notes": "Major CYP3A4 inducer — broad drug interactions",
    },
    {
        "canonical_name": "milk_thistle",
        "item_type": "supplement",
        "category": "botanical",
        "nih_ods_url": None,
        "msk_url": "https://www.mskcc.org/cancer-care/integrative-medicine/herbs/milk-thistle",
        "notes": "CYP450 interactions",
    },
    {
        "canonical_name": "valerian",
        "item_type": "supplement",
        "category": "botanical",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/Valerian-HealthProfessional/",
        "msk_url": None,
        "notes": "CNS depressant interactions",
    },
    {
        "canonical_name": "black_cohosh",
        "item_type": "supplement",
        "category": "botanical",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/BlackCohosh-HealthProfessional/",
        "msk_url": None,
        "notes": "Hormonal medication interactions",
    },
    {
        "canonical_name": "echinacea",
        "item_type": "supplement",
        "category": "botanical",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/Echinacea-HealthProfessional/",
        "msk_url": None,
        "notes": "Immunosuppressant interactions",
    },
    {
        "canonical_name": "glucosamine",
        "item_type": "supplement",
        "category": "amino_acid",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/Glucosamine-HealthProfessional/",
        "msk_url": None,
        "notes": "Anticoagulant interactions",
    },
    {
        "canonical_name": "chondroitin",
        "item_type": "supplement",
        "category": "amino_acid",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/Glucosamine-HealthProfessional/",
        "msk_url": None,
        "notes": "Often paired with glucosamine; same ODS fact sheet",
    },
    {
        "canonical_name": "garlic",
        "item_type": "supplement",
        "category": "botanical",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/Garlic-HealthProfessional/",
        "msk_url": None,
        "notes": "Anticoagulant and antihypertensive interactions",
    },
    {
        "canonical_name": "saw_palmetto",
        "item_type": "supplement",
        "category": "botanical",
        "nih_ods_url": None,
        "msk_url": "https://www.mskcc.org/cancer-care/integrative-medicine/herbs/saw-palmetto",
        "notes": "Anticoagulant and hormone interactions",
    },
    {
        "canonical_name": "rhodiola_rosea",
        "item_type": "supplement",
        "category": "botanical",
        "nih_ods_url": None,
        "msk_url": "https://www.mskcc.org/cancer-care/integrative-medicine/herbs/rhodiola",
        "notes": "Adaptogen; emerging interaction data",
    },
    {
        "canonical_name": "5_htp",
        "item_type": "supplement",
        "category": "amino_acid",
        "nih_ods_url": None,
        "msk_url": "https://www.mskcc.org/cancer-care/integrative-medicine/herbs/5-htp-01",
        "notes": "Serotonin syndrome risk with SSRIs — high priority interaction",
    },
    {
        "canonical_name": "elderberry",
        "item_type": "supplement",
        "category": "botanical",
        "nih_ods_url": None,
        "msk_url": "https://www.mskcc.org/cancer-care/integrative-medicine/herbs/elderberry",
        "notes": "Immune modulator; interactions with immunosuppressants",
    },
    {
        "canonical_name": "creatine",
        "item_type": "supplement",
        "category": "amino_acid",
        "nih_ods_url": None,
        "msk_url": "https://www.mskcc.org/cancer-care/integrative-medicine/herbs/creatine",
        "notes": "Interactions with diuretics and NSAIDs",
    },
    {
        "canonical_name": "nac",
        "item_type": "supplement",
        "category": "amino_acid",
        "nih_ods_url": None,
        "msk_url": "https://www.mskcc.org/cancer-care/integrative-medicine/herbs/n-acetyl-cysteine",
        "notes": "N-acetyl cysteine; interactions with nitroglycerin and antiepileptics",
    },
    {
        "canonical_name": "selenium",
        "item_type": "supplement",
        "category": "mineral",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/Selenium-HealthProfessional/",
        "msk_url": None,
        "notes": "Chemotherapy interactions",
    },
    {
        "canonical_name": "copper",
        "item_type": "supplement",
        "category": "mineral",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/Copper-HealthProfessional/",
        "msk_url": None,
        "notes": "Zinc-copper antagonism",
    },
    {
        "canonical_name": "potassium",
        "item_type": "supplement",
        "category": "mineral",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/Potassium-HealthProfessional/",
        "msk_url": None,
        "notes": "Interactions with ACE inhibitors and diuretics",
    },
    {
        "canonical_name": "phosphatidylserine",
        "item_type": "supplement",
        "category": "amino_acid",
        "nih_ods_url": None,
        "msk_url": "https://www.mskcc.org/cancer-care/integrative-medicine/herbs/phosphatidylserine",
        "notes": "Cognitive supplement; anticoagulant interactions",
    },
    {
        "canonical_name": "lions_mane",
        "item_type": "supplement",
        "category": "botanical",
        "nih_ods_url": None,
        "msk_url": None,
        "notes": "Emerging supplement; minimal interaction data — may rely on PubMed gap-fill",
    },
    {
        "canonical_name": "iodine",
        "item_type": "supplement",
        "category": "mineral",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/Iodine-HealthProfessional/",
        "msk_url": None,
        "notes": "Thyroid medication interactions",
    },
    {
        "canonical_name": "niacin_vitamin_b3",
        "item_type": "supplement",
        "category": "vitamin",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/Niacin-HealthProfessional/",
        "msk_url": None,
        "notes": "Statin interactions (myopathy risk with high-dose niacin)",
    },
    {
        "canonical_name": "nmn",
        "item_type": "supplement",
        "category": "antioxidant",
        "nih_ods_url": None,
        "msk_url": None,
        "notes": "Nicotinamide mononucleotide; emerging longevity supplement; limited interaction data",
    },
    # Positions 48-50: clinically relevant supplements with known drug interactions
    {
        "canonical_name": "chromium",
        "item_type": "supplement",
        "category": "mineral",
        "nih_ods_url": "https://ods.od.nih.gov/factsheets/Chromium-HealthProfessional/",
        "msk_url": None,
        "notes": "Interactions with insulin, metformin, antacids; additive effect with berberine for blood sugar",
    },
    {
        "canonical_name": "resveratrol",
        "item_type": "supplement",
        "category": "antioxidant",
        "nih_ods_url": None,
        "msk_url": "https://www.mskcc.org/cancer-care/integrative-medicine/herbs/resveratrol",
        "notes": "CYP3A4 inhibitor; interactions with warfarin (anticoagulant potentiation), statins",
    },
    {
        "canonical_name": "quercetin",
        "item_type": "supplement",
        "category": "botanical",
        "nih_ods_url": None,
        "msk_url": "https://www.mskcc.org/cancer-care/integrative-medicine/herbs/quercetin",
        "notes": "CYP3A4 inhibitor; interactions with warfarin, cyclosporine, and fluoroquinolone antibiotics",
    },
]

MEDICATIONS = [
    {
        "canonical_name": "atorvastatin",
        "item_type": "drug",
        "category": "statin",
        "brand_aliases": ["Lipitor", "atorvastatin calcium"],
        "key_interactions": ["coenzyme_q10", "niacin_vitamin_b3"],
    },
    {
        "canonical_name": "metformin",
        "item_type": "drug",
        "category": "antidiabetic",
        "brand_aliases": ["Glucophage", "Fortamet", "metformin hydrochloride", "metformin HCl"],
        "key_interactions": ["berberine", "vitamin_b12"],
    },
    {
        "canonical_name": "levothyroxine",
        "item_type": "drug",
        "category": "thyroid_hormone",
        "brand_aliases": ["Synthroid", "Levoxyl", "Tirosint"],
        "key_interactions": ["calcium", "iron", "magnesium"],
    },
    {
        "canonical_name": "lisinopril",
        "item_type": "drug",
        "category": "ace_inhibitor",
        "brand_aliases": ["Zestril", "Prinivil"],
        "key_interactions": ["potassium", "garlic", "coenzyme_q10"],
    },
    {
        "canonical_name": "amlodipine",
        "item_type": "drug",
        "category": "calcium_channel_blocker",
        "brand_aliases": ["Norvasc"],
        "key_interactions": ["st_johns_wort", "magnesium"],
    },
    {
        "canonical_name": "metoprolol",
        "item_type": "drug",
        "category": "beta_blocker",
        "brand_aliases": ["Lopressor", "Toprol XL"],
        "key_interactions": ["coenzyme_q10", "garlic"],
    },
    {
        "canonical_name": "omeprazole",
        "item_type": "drug",
        "category": "ppi",
        "brand_aliases": ["Prilosec"],
        "key_interactions": ["magnesium", "vitamin_b12", "iron"],
    },
    {
        "canonical_name": "losartan",
        "item_type": "drug",
        "category": "arb",
        "brand_aliases": ["Cozaar"],
        "key_interactions": ["potassium", "garlic"],
    },
    {
        "canonical_name": "sertraline",
        "item_type": "drug",
        "category": "ssri",
        "brand_aliases": ["Zoloft", "sertraline HCl"],
        "key_interactions": ["5_htp", "st_johns_wort", "omega_3_fatty_acids"],
    },
    {
        "canonical_name": "gabapentin",
        "item_type": "drug",
        "category": "anticonvulsant",
        "brand_aliases": ["Neurontin"],
        "key_interactions": ["magnesium", "nac"],
    },
    {
        "canonical_name": "escitalopram",
        "item_type": "drug",
        "category": "ssri",
        "brand_aliases": ["Lexapro", "escitalopram oxalate"],
        "key_interactions": ["5_htp", "st_johns_wort", "melatonin"],
    },
    {
        "canonical_name": "rosuvastatin",
        "item_type": "drug",
        "category": "statin",
        "brand_aliases": ["Crestor"],
        "key_interactions": ["coenzyme_q10", "niacin_vitamin_b3"],
    },
    {
        "canonical_name": "pantoprazole",
        "item_type": "drug",
        "category": "ppi",
        "brand_aliases": ["Protonix"],
        "key_interactions": ["magnesium", "vitamin_b12"],
    },
    {
        "canonical_name": "hydrochlorothiazide",
        "item_type": "drug",
        "category": "diuretic",
        "brand_aliases": ["Microzide", "HCTZ"],
        "key_interactions": ["potassium", "magnesium", "zinc", "coenzyme_q10"],
    },
    {
        "canonical_name": "bupropion",
        "item_type": "drug",
        "category": "antidepressant",
        "brand_aliases": ["Wellbutrin", "Zyban"],
        "key_interactions": ["valerian", "st_johns_wort"],
    },
    {
        "canonical_name": "warfarin",
        "item_type": "drug",
        "category": "anticoagulant",
        "brand_aliases": ["Coumadin"],
        "key_interactions": ["vitamin_k2", "omega_3_fatty_acids", "ginkgo_biloba", "garlic", "vitamin_e"],
    },
    {
        "canonical_name": "semaglutide",
        "item_type": "drug",
        "category": "glp1_agonist",
        "brand_aliases": ["Ozempic", "Wegovy"],
        "key_interactions": ["berberine"],
    },
    {
        "canonical_name": "fluoxetine",
        "item_type": "drug",
        "category": "ssri",
        "brand_aliases": ["Prozac"],
        "key_interactions": ["5_htp", "st_johns_wort"],
    },
    {
        "canonical_name": "amoxicillin",
        "item_type": "drug",
        "category": "antibiotic",
        "brand_aliases": ["Amoxil"],
        "key_interactions": ["probiotic", "zinc"],
    },
    {
        "canonical_name": "montelukast",
        "item_type": "drug",
        "category": "leukotriene_inhibitor",
        "brand_aliases": ["Singulair"],
        "key_interactions": ["st_johns_wort", "ginkgo_biloba"],
    },
]

# ---------------------------------------------------------------------------
# Canonical names data
# ---------------------------------------------------------------------------

CANONICAL_NAMES = {
    "_comment": (
        "Keys are canonical names (lowercase_underscores, NIH ODS authority per D-13). "
        "Values are alias arrays. Every compound encountered during extraction MUST appear "
        "here before a record is written."
    ),
    # --- Supplements ---
    "vitamin_d3": ["cholecalciferol", "vitamin d", "vitamin d3", "vitamin d-3", "calcitriol"],
    "magnesium": [
        "magnesium glycinate", "magnesium citrate", "magnesium oxide", "mag",
        "magnesium bisglycinate", "magnesium malate", "magnesium l-threonate",
    ],
    "omega_3_fatty_acids": [
        "fish oil", "omega-3", "omega 3", "epa", "dha", "epa/dha",
        "fish oil concentrate", "omega-3 fatty acids",
    ],
    "vitamin_c": [
        "ascorbic acid", "ascorbate", "l-ascorbic acid", "vitamin c",
        "sodium ascorbate", "calcium ascorbate",
    ],
    "vitamin_b12": [
        "cobalamin", "cyanocobalamin", "methylcobalamin", "adenosylcobalamin",
        "vitamin b-12", "vitamin b 12",
    ],
    "zinc": ["zinc gluconate", "zinc picolinate", "zinc citrate", "zinc sulfate", "zinc acetate"],
    "probiotic": [
        "lactobacillus", "bifidobacterium", "probiotic supplement", "probiotics",
        "lactobacillus acidophilus", "lactobacillus rhamnosus",
    ],
    "melatonin": ["n-acetyl-5-methoxytryptamine"],
    "ashwagandha": ["withania somnifera", "indian ginseng", "winter cherry"],
    "coenzyme_q10": ["coq10", "ubiquinol", "ubiquinone", "co-enzyme q10", "co q10", "coenzyme q-10"],
    "iron": [
        "ferrous sulfate", "ferrous gluconate", "ferric iron", "ferrous fumarate",
        "iron supplement", "ferrous bisglycinate",
    ],
    "vitamin_e": [
        "tocopherol", "alpha-tocopherol", "tocotrienol", "d-alpha tocopherol",
        "dl-alpha tocopherol", "mixed tocopherols",
    ],
    "turmeric_curcumin": ["turmeric", "curcumin", "curcuma longa", "diferuloylmethane"],
    "vitamin_a": [
        "retinol", "retinyl palmitate", "retinyl acetate", "beta-carotene",
        "preformed vitamin a", "provitamin a",
    ],
    "collagen": [
        "collagen peptides", "hydrolyzed collagen", "collagen protein",
        "marine collagen", "bovine collagen", "type i collagen", "type ii collagen",
    ],
    "biotin": ["vitamin h", "vitamin b7", "d-biotin", "coenzyme r"],
    "vitamin_k2": [
        "menaquinone", "mk-7", "mk-4", "vitamin k", "phylloquinone",
        "menatetrenone", "menaquinone-7",
    ],
    "folic_acid": [
        "folate", "vitamin b9", "l-methylfolate", "5-mthf",
        "methylfolate", "pteroylglutamic acid",
    ],
    "vitamin_b6": [
        "pyridoxine", "pyridoxal", "pyridoxamine", "pyridoxal-5-phosphate",
        "p5p", "vitamin b-6",
    ],
    "calcium": [
        "calcium carbonate", "calcium citrate", "calcium gluconate",
        "calcium phosphate", "calcium malate",
    ],
    "vitamin_b_complex": [
        "b complex", "b-complex", "vitamin b complex", "b vitamins",
        "b-vitamins", "b vitamin complex",
    ],
    "green_tea_extract": [
        "egcg", "epigallocatechin gallate", "camellia sinensis",
        "green tea", "green tea polyphenols",
    ],
    "berberine": ["berberine hcl", "berberine hydrochloride", "berberis"],
    "alpha_lipoic_acid": [
        "ala", "thioctic acid", "alpha lipoic acid", "lipoic acid",
        "r-lipoic acid", "r-ala",
    ],
    "ginkgo_biloba": [
        "ginkgo", "maidenhair tree", "ginkgo biloba extract", "egb 761",
        "ginkgo biloba leaf extract",
    ],
    "st_johns_wort": [
        "hypericum perforatum", "st. john's wort", "hypericin",
        "hyperforin", "saint john's wort",
    ],
    "milk_thistle": [
        "silymarin", "silybum marianum", "milk thistle extract",
        "silybin", "silibinin",
    ],
    "valerian": [
        "valeriana officinalis", "valerian root", "valerian extract",
        "valerenic acid",
    ],
    "black_cohosh": [
        "cimicifuga racemosa", "actaea racemosa", "black cohosh extract",
        "remifemin",
    ],
    "echinacea": [
        "echinacea purpurea", "echinacea angustifolia", "purple coneflower",
        "echinacea extract",
    ],
    "glucosamine": [
        "glucosamine sulfate", "glucosamine hcl", "glucosamine hydrochloride",
        "n-acetyl glucosamine",
    ],
    "chondroitin": [
        "chondroitin sulfate", "chondroitin sulfate sodium",
        "bovine chondroitin",
    ],
    "garlic": [
        "allium sativum", "garlic extract", "aged garlic extract",
        "allicin", "garlic oil", "kyolic garlic",
    ],
    "saw_palmetto": [
        "serenoa repens", "sabal palm", "saw palmetto extract",
        "saw palmetto berry",
    ],
    "rhodiola_rosea": [
        "arctic root", "golden root", "rhodiola", "rosavin",
        "salidroside", "rhodiola extract",
    ],
    "5_htp": ["5-hydroxytryptophan", "5-htp", "l-5-htp", "oxitriptan"],
    "elderberry": [
        "sambucus nigra", "black elderberry", "elderberry extract",
        "sambucol", "elderberry syrup",
    ],
    "creatine": [
        "creatine monohydrate", "creatine ethyl ester", "creatine hcl",
        "creatine phosphate", "phosphocreatine",
    ],
    "nac": [
        "n-acetyl cysteine", "n-acetylcysteine", "acetylcysteine",
        "n-acetyl-l-cysteine",
    ],
    "selenium": [
        "selenium yeast", "selenomethionine", "sodium selenite",
        "selenium selenate", "l-selenomethionine",
    ],
    "copper": [
        "copper gluconate", "copper sulfate", "cupric sulfate",
        "copper bisglycinate",
    ],
    "potassium": [
        "potassium chloride", "potassium citrate", "potassium gluconate",
        "potassium bicarbonate",
    ],
    "phosphatidylserine": [
        "ps", "phosphatidyl serine", "soy phosphatidylserine",
        "sunflower phosphatidylserine",
    ],
    "lions_mane": [
        "hericium erinaceus", "lion's mane mushroom", "lion's mane extract",
        "yamabushitake",
    ],
    "iodine": [
        "potassium iodide", "sodium iodide", "kelp", "iodide",
        "lugol's iodine",
    ],
    "niacin_vitamin_b3": [
        "niacin", "nicotinic acid", "nicotinamide", "vitamin b3",
        "niacinamide", "flush-free niacin", "inositol hexanicotinate",
    ],
    "nmn": [
        "nicotinamide mononucleotide", "beta-nmn", "b-nmn",
        "nad+ precursor",
    ],
    "chromium": [
        "chromium picolinate", "chromium polynicotinate", "chromium gtf",
        "trivalent chromium",
    ],
    "resveratrol": [
        "trans-resveratrol", "resveratrol extract", "polygonum cuspidatum",
        "grape skin extract",
    ],
    "quercetin": [
        "quercetin dihydrate", "quercetin phytosome", "bioflavonoid",
        "quercetin 3-glucoside",
    ],
    # --- Medications (generic canonical, brand aliases per D-14) ---
    "atorvastatin": ["lipitor", "atorvastatin calcium"],
    "metformin": ["glucophage", "fortamet", "metformin hydrochloride", "metformin hcl"],
    "levothyroxine": ["synthroid", "levoxyl", "tirosint"],
    "lisinopril": ["zestril", "prinivil"],
    "amlodipine": ["norvasc"],
    "metoprolol": ["lopressor", "toprol xl", "toprol-xl"],
    "omeprazole": ["prilosec"],
    "losartan": ["cozaar"],
    "sertraline": ["zoloft", "sertraline hcl"],
    "gabapentin": ["neurontin"],
    "escitalopram": ["lexapro", "escitalopram oxalate"],
    "rosuvastatin": ["crestor"],
    "pantoprazole": ["protonix"],
    "hydrochlorothiazide": ["microzide", "hctz"],
    "bupropion": ["wellbutrin", "zyban", "wellbutrin xl", "wellbutrin sr"],
    "warfarin": ["coumadin"],
    "semaglutide": ["ozempic", "wegovy", "rybelsus"],
    "fluoxetine": ["prozac", "sarafem"],
    "amoxicillin": ["amoxil", "trimox"],
    "montelukast": ["singulair"],
}

# ---------------------------------------------------------------------------
# Action templates
# ---------------------------------------------------------------------------

ACTION_TEMPLATES = {
    "_comment": (
        "7 baseline suggested-action templates from D-12. Add new templates here "
        "(not inline) when no existing template fits during extraction."
    ),
    "templates": [
        {
            "id": 1,
            "template": "Take [compound_a] at least [N] hours away from [compound_b].",
        },
        {
            "id": 2,
            "template": "Take [compound_a] with food to reduce interaction risk with [compound_b].",
        },
        {
            "id": 3,
            "template": (
                "Avoid combining [compound_a] with [compound_b]. "
                "Consider replacing [compound_a] with [alternative] if possible."
            ),
        },
        {
            "id": 4,
            "template": (
                "Consider reducing your [compound_a] dose when taking alongside [compound_b]."
            ),
        },
        {
            "id": 5,
            "template": (
                "[compound_a] and [compound_b] are well-paired. No timing adjustment needed."
            ),
        },
        {
            "id": 6,
            "template": (
                "Take [compound_a] in the morning and [compound_b] in the evening "
                "to minimize conflict."
            ),
        },
        {
            "id": 7,
            "template": (
                "Monitor for [effect] when combining [compound_a] with [compound_b]. "
                "Consult your doctor if concerned."
            ),
        },
    ],
}


# ---------------------------------------------------------------------------
# Setup logic
# ---------------------------------------------------------------------------

def create_artifacts(force: bool = False) -> dict:
    """Create all Stage 0 artifacts. Returns counts dict."""
    results = {}

    target_list_path = RESEARCH_DIR / "target_list.json"
    canonical_path = RESEARCH_DIR / "canonical_names.json"
    templates_path = RESEARCH_DIR / "action_templates.json"

    # target_list.json
    if not target_list_path.exists() or force:
        target_list = {
            "supplements": SUPPLEMENTS,
            "medications": MEDICATIONS,
        }
        save_json_atomic(target_list, target_list_path)
        results["target_list"] = f"{len(SUPPLEMENTS)} supplements + {len(MEDICATIONS)} medications"
    else:
        results["target_list"] = "SKIPPED (already exists; use --force to overwrite)"

    # canonical_names.json
    if not canonical_path.exists() or force:
        save_json_atomic(CANONICAL_NAMES, canonical_path)
        non_comment = [k for k in CANONICAL_NAMES if not k.startswith("_")]
        results["canonical_names"] = f"{len(non_comment)} entries"
    else:
        results["canonical_names"] = "SKIPPED (already exists; use --force to overwrite)"

    # action_templates.json
    if not templates_path.exists() or force:
        save_json_atomic(ACTION_TEMPLATES, templates_path)
        results["action_templates"] = f"{len(ACTION_TEMPLATES['templates'])} templates"
    else:
        results["action_templates"] = "SKIPPED (already exists; use --force to overwrite)"

    # checkpoint.json — initialize then mark stage0_complete
    checkpoint = load_checkpoint()
    checkpoint["stage0_complete"] = True
    save_checkpoint(checkpoint)
    results["checkpoint"] = "stage0_complete = True"

    return results


def verify_artifacts() -> bool:
    """Verify all Stage 0 artifacts meet acceptance criteria. Returns True on pass."""
    import json
    all_pass = True

    target_list_path = RESEARCH_DIR / "target_list.json"
    canonical_path = RESEARCH_DIR / "canonical_names.json"
    templates_path = RESEARCH_DIR / "action_templates.json"
    checkpoint_path = RESEARCH_DIR / "checkpoint.json"

    print("=== Stage 0 Artifact Verification ===\n")

    # target_list.json
    if not target_list_path.exists():
        print("FAIL: target_list.json missing")
        all_pass = False
    else:
        with open(target_list_path) as f:
            tl = json.load(f)
        s_count = len(tl.get("supplements", []))
        m_count = len(tl.get("medications", []))
        s_ok = s_count == 50
        m_ok = m_count == 20
        print(f"target_list.json: {s_count} supplements {'PASS' if s_ok else 'FAIL (expected 50)'}, "
              f"{m_count} medications {'PASS' if m_ok else 'FAIL (expected 20)'}")
        if not (s_ok and m_ok):
            all_pass = False
        # Check brand_aliases
        missing_aliases = [m["canonical_name"] for m in tl.get("medications", [])
                           if not m.get("brand_aliases")]
        if missing_aliases:
            print(f"  FAIL: medications missing brand_aliases: {missing_aliases}")
            all_pass = False
        else:
            print("  All 20 medications have brand_aliases: PASS")

    # canonical_names.json
    if not canonical_path.exists():
        print("FAIL: canonical_names.json missing")
        all_pass = False
    else:
        with open(canonical_path) as f:
            cn = json.load(f)
        non_comment = [k for k in cn if not k.startswith("_")]
        c_ok = len(non_comment) == 70
        print(f"canonical_names.json: {len(non_comment)} entries {'PASS' if c_ok else 'FAIL (expected 70)'}")
        if not c_ok:
            all_pass = False
        has_comment = "_comment" in cn
        print(f"  _comment key present: {'PASS' if has_comment else 'FAIL'}")
        if not has_comment:
            all_pass = False

    # action_templates.json
    if not templates_path.exists():
        print("FAIL: action_templates.json missing")
        all_pass = False
    else:
        with open(templates_path) as f:
            at = json.load(f)
        t_count = len(at.get("templates", []))
        t_ok = t_count == 7
        print(f"action_templates.json: {t_count} templates {'PASS' if t_ok else 'FAIL (expected 7)'}")
        if not t_ok:
            all_pass = False
        # Check template 7 contains "Monitor for [effect]"
        if t_count >= 7:
            t7 = at["templates"][6]["template"]
            t7_ok = "Monitor for [effect]" in t7
            print(f"  Template 7 contains 'Monitor for [effect]': {'PASS' if t7_ok else 'FAIL'}")
            if not t7_ok:
                all_pass = False

    # checkpoint.json
    if not checkpoint_path.exists():
        print("FAIL: checkpoint.json missing")
        all_pass = False
    else:
        with open(checkpoint_path) as f:
            cp = json.load(f)
        s0_ok = cp.get("stage0_complete") is True
        print(f"checkpoint.json: stage0_complete = {cp.get('stage0_complete')} {'PASS' if s0_ok else 'FAIL'}")
        if not s0_ok:
            all_pass = False

    print(f"\n{'=== ALL CHECKS PASSED ===' if all_pass else '=== SOME CHECKS FAILED ==='}")
    return all_pass


def main():
    parser = argparse.ArgumentParser(description="Stage 0 setup — generate working artifacts")
    parser.add_argument("--force", action="store_true", help="Overwrite existing files")
    parser.add_argument("--verify", action="store_true", help="Verify artifacts only, no write")
    args = parser.parse_args()

    if args.verify:
        ok = verify_artifacts()
        sys.exit(0 if ok else 1)

    results = create_artifacts(force=args.force)

    # Re-count from written files for accurate reporting
    import json
    with open(RESEARCH_DIR / "target_list.json") as f:
        tl = json.load(f)
    with open(RESEARCH_DIR / "canonical_names.json") as f:
        cn = json.load(f)
    with open(RESEARCH_DIR / "action_templates.json") as f:
        at = json.load(f)

    supp_count = len(tl["supplements"])
    med_count = len(tl["medications"])
    canon_count = len([k for k in cn if not k.startswith("_")])
    tmpl_count = len(at["templates"])

    print("\n=== Stage 0 Artifacts Created ===")
    print(f"target_list.json: {supp_count} supplements + {med_count} medications")
    print(f"canonical_names.json: {canon_count} entries (excluding _comment key)")
    print(f"action_templates.json: {tmpl_count} templates")
    print(f"checkpoint.json: stage0_complete = True")
    print()
    print("ACTION REQUIRED: Review target_list.json and approve before Stage 1 begins (D-04).")
    print("Edit any canonical names, categories, or NIH ODS URLs as needed.")
    print("When approved, continue to Plan 02 (Stage 1 -- Collection).")


if __name__ == "__main__":
    main()
