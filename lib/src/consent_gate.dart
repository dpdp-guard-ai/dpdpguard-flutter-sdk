/// Pure helper for gating a feature/tracker on an existing consent decision -
/// e.g. `if (!hasConsent(consents, 'Analytics')) return;` before firing an
/// analytics event. Never calls the network; combine with [DpdpGuardClient]'s
/// reads or your own cached consent state.
class ConsentRecord {
  final String purpose;

  /// Non-null when the decision was withdrawn; `null` means still active.
  final int? withdrawnAt;

  const ConsentRecord({required this.purpose, this.withdrawnAt});
}

/// `true` iff [consents] contains an active (non-withdrawn) record for
/// [purpose].
bool hasConsent(List<ConsentRecord> consents, String purpose) {
  return consents.any((c) => c.purpose == purpose && c.withdrawnAt == null);
}
