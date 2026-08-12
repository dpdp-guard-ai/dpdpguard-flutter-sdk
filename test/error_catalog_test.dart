import 'dart:convert';
import 'dart:io';

import 'package:dpdpguard_flutter/dpdpguard_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the hand-copied [errorCatalog] against a verbatim copy of
/// `contract/conformance/error-catalog.json` so the two can never silently
/// drift apart - the same guard `ErrorCatalogTest` provides on Android.
List<Map<String, String>> _loadCatalogFromFixture() {
  final file = File('contract/conformance/error-catalog.json');
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return (json['codes'] as List<dynamic>)
      .map((e) => {
            'code': (e as Map<String, dynamic>)['code'] as String,
            'description': e['description'] as String,
          })
      .toList();
}

void main() {
  test('errorCatalog matches conformance error-catalog.json exactly, in order',
      () {
    final fixture = _loadCatalogFromFixture();
    final actual = errorCatalog
        .map((e) => {'code': e.code, 'description': e.description})
        .toList();
    expect(actual, fixture);
  });

  test('has exactly the 21 documented codes (10 /api/v1 + 11 /mcp/v1 agent surface)',
      () {
    expect(errorCatalog.length, 21);
    expect(errorCatalog.map((e) => e.code).toList(), [
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
      'SCOPE_INSUFFICIENT',
      'TOOL_NOT_AVAILABLE',
      'ORG_DISABLED',
      'APPROVAL_REQUIRED',
      'APPROVAL_BACKLOG_FULL',
      'PROPOSAL_EXPIRED',
      'SECOND_REVIEWER_REQUIRED',
      'PROPOSAL_ALREADY_REVIEWED',
      'DATA_VOLUME_EXCEEDED',
      'PLAN_LIMIT_REACHED',
      'AGENT_WRITE_BLOCKED',
    ]);
  });

  test(
      'apiErrorCodeFromWireValue resolves known codes and returns null for unknown ones',
      () {
    expect(apiErrorCodeFromWireValue('NOT_FOUND'), ApiErrorCode.notFound);
    expect(
        apiErrorCodeFromWireValue(
            'SOME_FUTURE_CODE_THIS_SDK_DOESNT_KNOW_ABOUT'),
        isNull);
  });

  test('DpdpGuardApiError carries code, status, and an optional typed code',
      () {
    final known = DpdpGuardApiError('RATE_LIMITED', 'slow down', 429);
    expect(known.code, 'RATE_LIMITED');
    expect(known.status, 429);
    expect(known.typedCode, ApiErrorCode.rateLimited);

    final unknown =
        DpdpGuardApiError('A_NEW_CODE_FROM_A_NEWER_SERVER', 'surprise', 422);
    expect(unknown.typedCode, isNull);
  });
}
