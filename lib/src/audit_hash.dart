import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Client-side reimplementation of `convex/lib/auditHash.ts`'s
/// canonicalization (`conformance/audit-hash-spec.md`), ported from the Node
/// reference SDK's `auditHash.ts`. Verified against the golden vectors in
/// `conformance/audit-hash-vectors.json` (ADR-002 D5) — see
/// `test/audit_hash_test.dart`.
///
/// Every field is always present in the canonical string; a `null` [source]
/// serializes as the literal string `"null"` rather than being omitted, so
/// "missing" and "explicitly null" never collide.
class AuditHashInput {
  final String organizationId;
  final String noticeId;
  final int noticeVersion;
  final String purpose;
  final List<String> dataTypes;

  /// Unix epoch milliseconds.
  final int givenAt;

  /// One of `"brokered"`, `"direct"`, `"anonymous"`, `"linked"`, or `null`.
  final String? source;

  const AuditHashInput({
    required this.organizationId,
    required this.noticeId,
    required this.noticeVersion,
    required this.purpose,
    required this.dataTypes,
    required this.givenAt,
    this.source,
  });
}

/// Builds the canonical `|`-joined string for [input], sorting `dataTypes`
/// lexicographically and joining them with `,` first.
String canonicalizeAuditEvent(AuditHashInput input) {
  final sortedDataTypes = List<String>.from(input.dataTypes)..sort();
  final source = input.source ?? 'null';
  return [
    input.organizationId,
    input.noticeId,
    input.noticeVersion.toString(),
    input.purpose,
    sortedDataTypes.join(','),
    input.givenAt.toString(),
    source,
  ].join('|');
}

/// Computes `HMAC-SHA256(canonicalizeAuditEvent(input), secret)`, hex-encoded
/// (lowercase).
String computeAuditHash(AuditHashInput input, String secret) {
  final canonical = canonicalizeAuditEvent(input);
  final hmac = Hmac(sha256, utf8.encode(secret));
  final digest = hmac.convert(utf8.encode(canonical));
  return digest.toString();
}
