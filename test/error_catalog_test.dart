import 'package:dpdpguard_flutter/dpdpguard_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('errorCatalog', () {
    test('lists all 10 ADR-002 D2 codes in the documented order', () {
      final codes = errorCatalog.map((entry) => entry.code).toList();
      expect(codes, [
        'MINOR_TRACKING_BLOCKED',
        'NOTICE_NOT_PUBLISHED',
        'ALREADY_CONSENTED',
        'NOT_ASSOCIATED_WITH_ORG',
        'INVALID_STATUS_TRANSITION',
        'SDK_VERSION_UNSUPPORTED',
        'NOT_FOUND',
        'UNAUTHORIZED',
        'RATE_LIMITED',
        'VALIDATION_ERROR',
      ]);
    });
  });

  group('ApiErrorCode', () {
    test('fromWireValue resolves known codes', () {
      expect(ApiErrorCode.fromWireValue('NOT_FOUND'), ApiErrorCode.notFound);
      expect(ApiErrorCode.fromWireValue('RATE_LIMITED'), ApiErrorCode.rateLimited);
    });

    test('fromWireValue returns null for a code this SDK does not know about', () {
      expect(ApiErrorCode.fromWireValue('SOME_FUTURE_CODE'), isNull);
    });
  });

  group('DpdpGuardApiError', () {
    test('carries the raw code, message, and HTTP status', () {
      final error = DpdpGuardApiError('NOT_FOUND', 'No such organization', 404);
      expect(error.code, 'NOT_FOUND');
      expect(error.message, 'No such organization');
      expect(error.status, 404);
      expect(error.toString(), contains('NOT_FOUND'));
    });
  });
}
