from datetime import datetime

from reconcile import PartyEntry, reconcile


def _entry(**overrides):
    defaults = dict(id="a1", kind="loan", occurred_at=datetime(2026, 8, 12), amount_minor_units=200000, counterparty="Salimu")
    defaults.update(overrides)
    return PartyEntry(**defaults)


def test_matches_two_identical_entries():
    a = [_entry(id="a1")]
    b = [_entry(id="b1")]
    matches, unmatched_a, unmatched_b = reconcile(a, b)
    assert len(matches) == 1
    assert matches[0].agrees is True
    assert unmatched_a == []
    assert unmatched_b == []


def test_surfaces_a_disagreement_rather_than_silently_picking_one():
    a = [_entry(id="a1", amount_minor_units=200000)]
    b = [_entry(id="b1", amount_minor_units=180000)]
    matches, _, _ = reconcile(a, b)
    assert len(matches) == 1
    assert matches[0].agrees is False
    assert "200000" in matches[0].reason
    assert "180000" in matches[0].reason


def test_an_entry_with_no_counterpart_is_unmatched():
    a = [_entry(id="a1")]
    b: list[PartyEntry] = []
    matches, unmatched_a, unmatched_b = reconcile(a, b)
    assert matches == []
    assert len(unmatched_a) == 1
    assert unmatched_b == []


def test_does_not_match_entries_of_different_kinds():
    a = [_entry(id="a1", kind="loan")]
    b = [_entry(id="b1", kind="repayment")]
    matches, unmatched_a, unmatched_b = reconcile(a, b)
    assert matches == []
    assert len(unmatched_a) == 1
    assert len(unmatched_b) == 1


def test_does_not_double_match_one_b_entry_to_two_a_entries():
    a = [_entry(id="a1"), _entry(id="a2")]
    b = [_entry(id="b1")]
    matches, unmatched_a, _ = reconcile(a, b)
    assert len(matches) == 1
    assert len(unmatched_a) == 1
