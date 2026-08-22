/// How a capture reached the ledger.
enum CaptureSource { voice, typed, quick }

/// The eight transaction kinds. Exactly eight — a ninth requires removing
/// one, per the master specification.
enum EntryKind {
  orePurchase,
  fuel,
  milling,
  goldYield,
  wages,
  loan,
  repayment,
  sale,
}

/// Physical quantity units a trader actually speaks in.
enum QuantityUnit { sack, tin, litre, kilogram, gram, piece }

/// Fields an interpreter may be unsure of on a single entry.
enum EntryField { amount, quantity, counterparty }

/// The four roles. Same engine, different vocabulary and one destination.
enum UserRole { miner, sponsor, buyer, trader }

/// Supported interface languages.
enum AppLanguage {
  swahili('sw'),
  english('en');

  const AppLanguage(this.code);

  final String code;
}
