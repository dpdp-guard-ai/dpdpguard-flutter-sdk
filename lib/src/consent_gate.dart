/// Pure helper for gating a feature/tracker on an existing consent decision —
/// e.g. `if (!hasConsent(consents, "Analytics")) return;` before firing an
/// analytics event. Does not call the network; combine with
/// `DpdpGuardClient`'s reads or your own cached consent state. Ported from
/// the Node reference SDK's `consentGate.ts`.
class ConsentRecord {
  final String purpose;

  /// Set when the decision was withdrawn; `null` means still active.
  final int? withdrawnAt;

  const ConsentRecord({required this.purpose, this.withdrawnAt});
}

/// Returns `true` if [consents] contains an active (non-withdrawn) decision
/// for [purpose].
bool hasConsent(List<ConsentRecord> consents, String purpose) {
  return consents.any((c) => c.purpose == purpose && c.withdrawnAt == null);
}
