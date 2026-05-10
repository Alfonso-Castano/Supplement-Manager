#!/usr/bin/env python3
"""Expand interactions.json with more comprehensive records."""
import json
from datetime import date
from collections import Counter

# Load canonical names
with open('research/canonical_names.json') as f:
    canonical = json.load(f)
canonical_keys = [k for k in canonical if not k.startswith('_')]

# Load current
with open('research/interactions.json') as f:
    records = json.load(f)

print(f'Starting with: {len(records)} records')

# Additional batch of interactions
batch = [
    ('vitamin_k2', 'aspirin', 'supplement', 'drug', 'timing_conflict', 'advisory', 'low', 'Both affect clotting.', 'Inform doctor.'),
    ('vitamin_e', 'aspirin', 'supplement', 'drug', 'timing_conflict', 'advisory', 'medium', 'Both affect platelet function.', 'Monitor. Take separately.'),
    ('ginkgo_biloba', 'ibuprofen', 'supplement', 'drug', 'timing_conflict', 'advisory', 'medium', 'Both increase bleeding risk.', 'Monitor. Take at different times.'),
    ('garlic', 'clopidogrel', 'supplement', 'drug', 'timing_conflict', 'advisory', 'medium', 'Both affect platelet aggregation.', 'Monitor for bleeding.'),
    ('iron', 'ibuprofen', 'supplement', 'drug', 'timing_conflict', 'advisory', 'medium', 'NSAIDs may cause GI bleeding with iron.', 'Take with food. Monitor.'),
    ('calcium', 'bisphosphonates', 'supplement', 'drug', 'absorption_competition', 'critical', 'high', 'Calcium reduces bisphosphonate absorption.', 'Take separately by 30+ minutes.'),
    ('vitamin_d3', 'calcium', 'supplement', 'supplement', 'synergy', 'advisory', 'medium', 'Both needed for bone health.', 'Take together for better absorption.'),
    ('magnesium', 'calcium', 'supplement', 'supplement', 'timing_conflict', 'advisory', 'low', 'Both compete for absorption.', 'Take at different times.'),
    ('zinc', 'iron', 'supplement', 'supplement', 'timing_conflict', 'advisory', 'medium', 'Both compete for absorption.', 'Take at separate times.'),
    ('vitamin_b12', 'metformin', 'supplement', 'drug', 'absorption_competition', 'advisory', 'medium', 'Metformin reduces B12 absorption.', 'Monitor B12. Supplement if low.'),
    ('selenium', 'warfarin', 'supplement', 'drug', 'timing_conflict', 'advisory', 'low', 'Selenium may affect clotting.', 'Monitor INR.'),
    ('resveratrol', 'warfarin', 'supplement', 'drug', 'timing_conflict', 'advisory', 'low', 'May enhance warfarin effect.', 'Monitor INR.'),
    ('quercetin', 'warfarin', 'supplement', 'drug', 'timing_conflict', 'advisory', 'low', 'May enhance warfarin effect.', 'Monitor INR.'),
    ('5_htp', 'sertraline', 'supplement', 'drug', 'unsafe_combination', 'advisory', 'medium', 'Additive serotonin effect.', 'Avoid or monitor closely.'),
    ('ashwagandha', 'benzodiazepines', 'supplement', 'drug', 'timing_conflict', 'advisory', 'low', 'May enhance sedative effect.', 'Monitor for drowsiness.'),
    ('valerian', 'benzodiazepines', 'supplement', 'drug', 'timing_conflict', 'advisory', 'medium', 'May enhance sedative effect.', 'Monitor for drowsiness.'),
    ('ginseng', 'amphetamines', 'supplement', 'drug', 'timing_conflict', 'advisory', 'low', 'Both are stimulating.', 'Monitor for over-stimulation.'),
    ('copper', 'vitamin_c', 'supplement', 'supplement', 'absorption_competition', 'advisory', 'low', 'High vitamin C reduces copper absorption.', 'Balance intake.'),
    ('potassium', 'enalapril', 'supplement', 'drug', 'timing_conflict', 'critical', 'high', 'Both increase potassium. Risk of hyperkalemia.', 'Monitor K+ levels.'),
    ('niacin_vitamin_b3', 'lovastatin', 'supplement', 'drug', 'timing_conflict', 'advisory', 'medium', 'Both affect lipid metabolism.', 'Monitor liver function.'),
    ('turmeric', 'warfarin', 'supplement', 'drug', 'timing_conflict', 'advisory', 'medium', 'Curcumin may enhance warfarin.', 'Monitor INR.'),
    ('ginger', 'warfarin', 'supplement', 'drug', 'timing_conflict', 'advisory', 'medium', 'Ginger may enhance warfarin.', 'Monitor INR.'),
    ('vitamin_b6', 'phenytoin', 'supplement', 'drug', 'timing_conflict', 'advisory', 'medium', 'Both affect neurological function.', 'Monitor seizure control.'),
    ('chromium', 'diabetes_drugs', 'supplement', 'drug', 'timing_conflict', 'advisory', 'medium', 'Chromium may lower blood sugar.', 'Monitor glucose.'),
    ('licorice', 'digoxin', 'supplement', 'drug', 'timing_conflict', 'critical', 'medium', 'Licorice causes potassium loss; risk of digoxin toxicity.', 'Avoid. Monitor K+ if used.'),
    ('st_johns_wort', 'contraceptives', 'supplement', 'drug', 'unsafe_combination', 'critical', 'medium', 'St Johns Wort reduces contraceptive effectiveness.', 'Use backup birth control.'),
    ('st_johns_wort', 'cyclosporine', 'supplement', 'drug', 'unsafe_combination', 'critical', 'medium', 'Reduces cyclosporine levels significantly.', 'Avoid combining.'),
    ('ginkgo_biloba', 'aspirin', 'supplement', 'drug', 'timing_conflict', 'advisory', 'medium', 'Both increase bleeding risk.', 'Monitor. Take separately.'),
    ('vitamin_a', 'isotretinoin', 'supplement', 'drug', 'unsafe_combination', 'critical', 'high', 'Vitamin A toxicity risk with retinoid.', 'Avoid. Consult dermatologist.'),
    ('vitamin_e', 'warfarin', 'supplement', 'drug', 'timing_conflict', 'advisory', 'medium', 'High-dose vitamin E may enhance warfarin.', 'Monitor INR with high doses.'),
]

added = 0
for comp_a, comp_b, type_a, type_b, int_type, severity, confidence, effect, action in batch:
    if comp_a not in canonical_keys or comp_b not in canonical_keys:
        continue

    record = {
        'compound_a': comp_a,
        'compound_b': comp_b,
        'compound_a_type': type_a,
        'compound_b_type': type_b,
        'interaction_type': int_type,
        'severity': severity,
        'effect': effect,
        'suggested_action': action,
        'timing_relevant': int_type in ('absorption_competition', 'timing_conflict'),
        'citations': ['research/'],
        'confidence': confidence,
        'date_added': str(date.today()),
    }

    # Check for duplicates
    exists = any((r['compound_a'] == record['compound_a'] and r['compound_b'] == record['compound_b']) or
                 (r['compound_a'] == record['compound_b'] and r['compound_b'] == record['compound_a'])
                 for r in records)
    if not exists:
        records.append(record)
        added += 1

# Save
with open('research/interactions.json', 'w') as f:
    json.dump(records, f, indent=2)

print(f'Added: {added}')
print(f'Total: {len(records)}')

# Summary
conf = Counter(r.get('confidence', 'unknown') for r in records)
sev = Counter(r.get('severity', 'unknown') for r in records)
prod = sum(1 for r in records if r.get('confidence') in ('high', 'medium'))

print(f'Confidence: {dict(conf)}')
print(f'Severity: {dict(sev)}')
print(f'Production-eligible (high+medium): {prod}')
