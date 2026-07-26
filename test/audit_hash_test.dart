import 'dart:convert';
import 'dart:io';

import 'package:dpdpguard_flutter/dpdpguard_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// ADR-002 D5: this SDK must run the `@dpdpguard/contract` golden vectors as
/// a required release gate. `test/fixtures/audit-hash-vectors.json` is
/// copied verbatim from `conformance/audit-hash-vectors.json` — do not
/// hand-edit it.
void main() {
  final fixtureFile = File('test/fixtures/audit-hash-vectors.json');
  final fixture = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
  final testSecret = fixture['testSecret'] as String;
  final vectors = fixture['vectors'] as List<dynamic>;

  group('audit-hash golden vectors (conformance/audit-hash-vectors.json)', () {
    for (final vectorDynamic in vectors) {
      final vector = vectorDynamic as Map<String, dynamic>;
      final name = vector['name'] as String;
      final input = vector['input'] as Map<String, dynamic>;
      final expectedCanonical = vector['expectedCanonical'] as String;
      final expectedHash = vector['expectedHash'] as String;

      test(name, () {
        final dataTypes = (input['dataTypes'] as List<dynamic>)
            .map((e) => e as String)
            .toList();
        final auditInput = AuditHashInput(
          organizationId: input['organizationId'] as String,
          noticeId: input['noticeId'] as String,
          noticeVersion: input['noticeVersion'] as int,
          purpose: input['purpose'] as String,
          dataTypes: dataTypes,
          givenAt: input['givenAt'] as int,
          source: input['source'] as String?,
        );

        expect(canonicalizeAuditEvent(auditInput), expectedCanonical);
        expect(computeAuditHash(auditInput, testSecret), expectedHash);
      });
    }
  });
}
