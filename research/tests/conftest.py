"""Shared pytest fixtures for StackWise Phase 0 test suite."""
import json
import pytest
from pathlib import Path


@pytest.fixture
def tmp_canonical(tmp_path):
    """A minimal canonical_names.json fixture for testing."""
    data = {
        "_comment": "Test fixture",
        "vitamin_d3": ["cholecalciferol", "vitamin d", "vitamin d3", "vitamin d-3"],
        "magnesium": ["magnesium glycinate", "magnesium citrate", "mag"],
        "atorvastatin": ["lipitor", "atorvastatin calcium"],
    }
    path = tmp_path / "canonical_names.json"
    path.write_text(json.dumps(data, indent=2))
    return data, path


@pytest.fixture
def sample_record():
    """A minimal valid interaction record for testing."""
    return {
        "compound_a": "vitamin_d3",
        "compound_b": "atorvastatin",
        "compound_a_type": "supplement",
        "compound_b_type": "drug",
        "interaction_type": "absorption_competition",
        "severity": "advisory",
        "mechanism": "CYP3A4 competition",
        "direction": "bidirectional",
        "effect": "May reduce atorvastatin efficacy",
        "suggested_action": "Take vitamin_d3 at least 4 hours away from atorvastatin.",
        "timing_relevant": True,
        "timing_window_hours": 4,
        "citations": ["https://ods.od.nih.gov/factsheets/VitaminD-HealthProfessional/"],
        "confidence": "medium",
        "date_added": "2026-05-05",
        "conflict_note": None,
    }
