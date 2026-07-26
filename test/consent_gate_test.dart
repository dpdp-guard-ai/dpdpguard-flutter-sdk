import 'package:dpdpguard_flutter/dpdpguard_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'hasConsent is true for an active (non-withdrawn) record with a matching purpose',
      () {
    final consents = [const ConsentRecord(purpose: 'Analytics')];
    expect(hasConsent(consents, 'Analytics'), isTrue);
  });

  test('hasConsent is false when the matching record was withdrawn', () {
    final consents = [
      const ConsentRecord(purpose: 'Analytics', withdrawnAt: 1700000000000)
    ];
    expect(hasConsent(consents, 'Analytics'), isFalse);
  });

  test('hasConsent is false when there is no record for the purpose', () {
    final consents = [const ConsentRecord(purpose: 'Marketing')];
    expect(hasConsent(consents, 'Analytics'), isFalse);
  });
}
