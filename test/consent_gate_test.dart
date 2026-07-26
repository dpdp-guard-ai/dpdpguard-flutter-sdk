import 'package:dpdpguard_flutter/dpdpguard_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('hasConsent', () {
    test('returns true for an active consent matching the purpose', () {
      final consents = [
        const ConsentRecord(purpose: 'Newsletter'),
        const ConsentRecord(purpose: 'Analytics', withdrawnAt: 1700000000000),
      ];
      expect(hasConsent(consents, 'Newsletter'), isTrue);
    });

    test('returns false when the matching purpose has been withdrawn', () {
      final consents = [
        const ConsentRecord(purpose: 'Analytics', withdrawnAt: 1700000000000),
      ];
      expect(hasConsent(consents, 'Analytics'), isFalse);
    });

    test('returns false when no consent exists for the purpose', () {
      expect(hasConsent(const [], 'Marketing'), isFalse);
    });

    test('is unaffected by an unrelated purpose in the list', () {
      final consents = [const ConsentRecord(purpose: 'Newsletter')];
      expect(hasConsent(consents, 'Marketing'), isFalse);
    });
  });
}
