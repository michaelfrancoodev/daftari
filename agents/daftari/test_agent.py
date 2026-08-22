"""
Tests for the deterministic Daftari agent logic. Run with: pytest

Deliberately thorough: this is the one agent in the fleet with no model in
the loop, so its correctness can and should be pinned down completely.
"""

from datetime import datetime, timedelta

import pytest

from agent import RawEntry, ValidationError, cost_per_gram, deduplicate, validate_entry


def _entry(**overrides):
    defaults = dict(
        id="e1",
        kind="orePurchase",
        occurred_at=datetime(2026, 8, 12, 9, 0),
        amount_minor_units=500000,
        quantity=None,
        counterparty=None,
        device_id="device-a",
    )
    defaults.update(overrides)
    return RawEntry(**defaults)


class TestValidateEntry:
    def test_accepts_a_well_formed_entry(self):
        validate_entry(_entry())  # Should not raise.

    def test_rejects_an_unknown_kind(self):
        with pytest.raises(ValidationError):
            validate_entry(_entry(kind="notAKind"))

    def test_rejects_a_float_amount(self):
        with pytest.raises(ValidationError):
            validate_entry(_entry(amount_minor_units=500000.5))  # type: ignore[arg-type]

    def test_rejects_a_negative_quantity(self):
        with pytest.raises(ValidationError):
            validate_entry(_entry(kind="goldYield", quantity=-1))

    def test_accepts_no_amount_at_all_since_incomplete_is_legal(self):
        validate_entry(_entry(amount_minor_units=None))


class TestDeduplicate:
    def test_keeps_two_distinct_entries(self):
        entries = [_entry(id="1"), _entry(id="2", amount_minor_units=85000, kind="fuel")]
        kept, dropped = deduplicate(entries)
        assert len(kept) == 2
        assert dropped == []

    def test_drops_the_same_event_synced_from_two_devices(self):
        base = datetime(2026, 8, 12, 9, 0)
        entries = [
            _entry(id="1", device_id="phone-a", occurred_at=base),
            _entry(id="2", device_id="phone-b", occurred_at=base + timedelta(seconds=30)),
        ]
        kept, dropped = deduplicate(entries)
        assert len(kept) == 1
        assert len(dropped) == 1

    def test_keeps_two_identical_purchases_from_the_same_device(self):
        # A miner can genuinely buy two identical sacks minutes apart —
        # same-device repeats are never treated as duplicates.
        base = datetime(2026, 8, 12, 9, 0)
        entries = [
            _entry(id="1", device_id="phone-a", occurred_at=base),
            _entry(id="2", device_id="phone-a", occurred_at=base + timedelta(seconds=30)),
        ]
        kept, dropped = deduplicate(entries)
        assert len(kept) == 2
        assert dropped == []

    def test_does_not_merge_events_outside_the_time_window(self):
        base = datetime(2026, 8, 12, 9, 0)
        entries = [
            _entry(id="1", device_id="phone-a", occurred_at=base),
            _entry(id="2", device_id="phone-b", occurred_at=base + timedelta(minutes=10)),
        ]
        kept, dropped = deduplicate(entries)
        assert len(kept) == 2
        assert dropped == []

    def test_does_not_merge_events_with_different_amounts(self):
        base = datetime(2026, 8, 12, 9, 0)
        entries = [
            _entry(id="1", device_id="phone-a", occurred_at=base, amount_minor_units=500000),
            _entry(id="2", device_id="phone-b", occurred_at=base, amount_minor_units=600000),
        ]
        kept, _ = deduplicate(entries)
        assert len(kept) == 2


class TestCostPerGram:
    def test_matches_the_flutter_ledger_worked_example(self):
        # Same numbers as `ledger_test.dart`'s summariseBatch test.
        entries = [
            _entry(id="1", kind="orePurchase", amount_minor_units=500000),
            _entry(id="2", kind="fuel", amount_minor_units=85000),
            _entry(id="3", kind="wages", amount_minor_units=30000),
            _entry(id="4", kind="goldYield", amount_minor_units=None, quantity=4.2),
        ]
        assert cost_per_gram(entries) == 146429

    def test_is_none_with_no_yield_recorded(self):
        entries = [_entry(id="1", kind="orePurchase", amount_minor_units=500000)]
        assert cost_per_gram(entries) is None
