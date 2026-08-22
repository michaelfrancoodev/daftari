"""
Same test cases as flutter/daftari/test/gap_detector_test.dart, run against
this server-side Python port. Keeping both suites in sync is what
guarantees the device and the cloud never disagree about what counts as a
gap.
"""

from datetime import datetime, timedelta

from gaps import Entry, detect

NOW = datetime(2026, 8, 20)


def test_flags_ore_bought_more_than_3_days_ago_with_no_milling_at_all():
    entries = [Entry(id="e", kind="orePurchase", occurred_at=NOW - timedelta(days=4))]
    kinds = [g.kind for g in detect(entries, NOW)]
    assert "oreNeverMilled" in kinds


def test_does_not_flag_ore_bought_less_than_3_days_ago():
    entries = [Entry(id="e", kind="orePurchase", occurred_at=NOW - timedelta(days=1))]
    assert detect(entries, NOW) == []


def test_does_not_flag_once_any_milling_has_been_recorded():
    entries = [
        Entry(id="1", kind="orePurchase", occurred_at=NOW - timedelta(days=5)),
        Entry(id="2", kind="milling", occurred_at=NOW - timedelta(days=1)),
    ]
    kinds = [g.kind for g in detect(entries, NOW)]
    assert "oreNeverMilled" not in kinds


def test_flags_a_mill_run_over_a_day_old_with_no_yield():
    entries = [Entry(id="e", kind="milling", occurred_at=NOW - timedelta(days=2))]
    kinds = [g.kind for g in detect(entries, NOW)]
    assert "millingWithoutYield" in kinds


def test_does_not_flag_once_a_yield_exists_anywhere():
    entries = [
        Entry(id="1", kind="milling", occurred_at=NOW - timedelta(days=2)),
        Entry(id="2", kind="goldYield", occurred_at=NOW),
    ]
    kinds = [g.kind for g in detect(entries, NOW)]
    assert "millingWithoutYield" not in kinds


def test_flags_a_loan_over_60_days_old_with_no_repayment():
    entries = [Entry(id="e", kind="loan", occurred_at=NOW - timedelta(days=61), counterparty="Salimu")]
    kinds = [g.kind for g in detect(entries, NOW)]
    assert "loanNeverRepaid" in kinds


def test_does_not_flag_a_loan_under_60_days_old():
    entries = [Entry(id="e", kind="loan", occurred_at=NOW - timedelta(days=10), counterparty="Salimu")]
    assert detect(entries, NOW) == []


def test_does_not_flag_once_that_counterparty_has_a_repayment():
    entries = [
        Entry(id="1", kind="loan", occurred_at=NOW - timedelta(days=90), counterparty="Salimu"),
        Entry(id="2", kind="repayment", occurred_at=NOW - timedelta(days=5), counterparty="Salimu"),
    ]
    assert detect(entries, NOW) == []


def test_a_loan_with_no_counterparty_is_never_flagged():
    entries = [Entry(id="e", kind="loan", occurred_at=NOW - timedelta(days=90), counterparty=None)]
    assert detect(entries, NOW) == []


def test_a_voided_entry_never_raises_a_gap():
    entries = [Entry(id="e", kind="orePurchase", occurred_at=NOW - timedelta(days=10), is_live=False)]
    assert detect(entries, NOW) == []
