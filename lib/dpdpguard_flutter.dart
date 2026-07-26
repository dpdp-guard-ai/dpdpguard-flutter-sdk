/// DPDP Guard Flutter SDK — a typed Dart client for the DPDP Guard
/// `/api/v1` surface (org/notice/banner-config reads, principal token
/// brokering, anonymous consent linking, DSR requests, grievances, and
/// successor nominations), plus the audit-hash canonicalization used to
/// verify `consentAuditTrail.auditHash` rows client-side.
export 'src/audit_hash.dart';
export 'src/client.dart';
export 'src/consent_gate.dart';
export 'src/error_catalog.dart';
export 'src/models.dart';

const String version = '0.1.0';
