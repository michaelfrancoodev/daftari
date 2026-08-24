import 'package:intl/intl.dart';

/// Currency held as whole minor units.
///
/// Tanzanian shillings have no fractional unit in practice, so one unit is
/// one shilling. This type exists to make it impossible to hold money in a
/// double: 0.1 + 0.2 != 0.3, and a rounding error nobody can explain would
/// destroy the only thing this product sells, which is trust.
///
/// Immutable, const-constructible and cheap to copy.
final class Money implements Comparable<Money> {
  /// Creates an amount from whole minor units.
  const Money(this.units);

  /// The additive identity.
  static const Money zero = Money(0);

  /// The amount in whole minor units. Never fractional, never a double.
  final int units;

  /// Parses user or machine input such as `500,000`, `500 000` or `500.000`.
  ///
  /// A dot, comma, or space is only ever treated as a *thousands grouping*
  /// separator, never a decimal point — Tanzanian shillings have no
  /// fractional unit, so `500.5` is not "500 point 5 shillings", it is an
  /// amount this parser cannot make sense of. Grouping is validated
  /// properly: every group after the first must be exactly three digits
  /// (`500.000` groups as `500` + `000`), which is what correctly tells
  /// `500.000` (five hundred thousand) apart from `500.5` (not a valid
  /// grouping at all, since `5` is not three digits) — an earlier version
  /// of this method stripped every separator unconditionally and silently
  /// misread `500.5` as `5005`.
  ///
  /// Returns null rather than guessing. A caller receiving null must ask the
  /// user; substituting a default would mean inventing a figure, which is
  /// the one thing this ledger may never do.
  static Money? tryParse(String input) {
    final String trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final bool negative = trimmed.startsWith('-');
    final String body = negative ? trimmed.substring(1) : trimmed;
    if (body.isEmpty) return null;

    if (!RegExp(r'^[\d.,\s]+$').hasMatch(body)) return null;

    final List<String> groups = body.split(RegExp(r'[.,\s]+'));
    if (groups.any((String g) => g.isEmpty)) return null;

    final int digits;
    if (groups.length == 1) {
      // No separators at all — a plain integer.
      final int? value = int.tryParse(groups.single);
      if (value == null) return null;
      digits = value;
    } else {
      // With separators: the first group is 1–3 digits, and every group
      // after it must be exactly three — anything else (like the lone "5"
      // in "500.5") is not a valid thousands grouping and is refused.
      if (groups.first.isEmpty || groups.first.length > 3) return null;
      if (groups.skip(1).any((String g) => g.length != 3)) return null;
      final int? value = int.tryParse(groups.join());
      if (value == null) return null;
      digits = value;
    }

    return Money(negative ? -digits : digits);
  }

  bool get isZero => units == 0;

  bool get isNegative => units < 0;

  bool get isPositive => units > 0;

  /// The magnitude, discarding sign.
  Money get abs => units < 0 ? Money(-units) : this;

  Money operator +(Money other) => Money(units + other.units);

  Money operator -(Money other) => Money(units - other.units);

  Money operator *(int factor) => Money(units * factor);

  Money operator -() => Money(-units);

  /// Divides by a physical quantity, rounding to the nearest whole unit.
  ///
  /// This is how cost per gram is derived. Returns null when the quantity is
  /// zero or not finite, because a batch with no yield recorded yet is an
  /// ordinary state rather than an error and must never throw.
  Money? dividedBy(num quantity) {
    if (quantity == 0 || !quantity.isFinite) return null;
    return Money((units / quantity).round());
  }

  /// This amount as a whole percentage of [reference].
  ///
  /// A generic utility — e.g. "this batch is 40% milled" — used wherever
  /// one amount needs to be expressed as a share of another. Returns null
  /// when the reference is zero, since a percentage of nothing is not a
  /// number, and guessing one would violate Rule #1.
  int? percentOf(Money reference) {
    if (reference.units == 0) return null;
    return ((units * 100) / reference.units).round();
  }

  /// Formats for display in the caller's locale.
  ///
  /// Grouping comes from [locale]. No currency symbol is attached, because
  /// the unit is stated once in the surrounding label rather than repeated
  /// beside every figure on the screen.
  String format({String locale = 'sw'}) => NumberFormat.decimalPattern(locale).format(units);

  @override
  int compareTo(Money other) => units.compareTo(other.units);

  bool operator <(Money other) => units < other.units;

  bool operator >(Money other) => units > other.units;

  bool operator <=(Money other) => units <= other.units;

  bool operator >=(Money other) => units >= other.units;

  @override
  bool operator ==(Object other) => other is Money && other.units == units;

  @override
  int get hashCode => units.hashCode;

  @override
  String toString() => 'Money($units)';
}

/// Sums a sequence without an intermediate double at any point.
Money sumMoney(Iterable<Money> values) => values.fold(Money.zero, (Money running, Money next) => running + next);
