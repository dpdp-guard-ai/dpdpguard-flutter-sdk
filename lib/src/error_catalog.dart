/// ADR-002 D2's typed error-code catalog, ported from
/// `conformance/error-catalog.json` (mirrors the Node reference SDK's
/// `errorCatalog.ts`). Adding a code to the server's catalog is additive
/// (minor) under ADR-002 D4, so [DpdpGuardApiError.code] is deliberately
/// typed as a plain [String] rather than a closed enum — this SDK must
/// never break just because the server started returning a code it didn't
/// know about yet.
library;

/// One entry from the ADR-002 D2 error catalog: a stable machine-readable
/// `code` plus a human-readable `description`.
class ErrorCatalogEntry {
  final String code;
  final String description;

  const ErrorCatalogEntry({required this.code, required this.description});
}

/// The ADR-002 D2 error catalog, verbatim from
/// `conformance/error-catalog.json`. Kept in the same order as the source
/// file.
const List<ErrorCatalogEntry> errorCatalog = [
  ErrorCatalogEntry(
    code: 'MINOR_TRACKING_BLOCKED',
    description:
        'Tracking/analytics consent is disabled for a verified minor and cannot be granted.',
  ),
  ErrorCatalogEntry(
    code: 'NOTICE_NOT_PUBLISHED',
    description: 'The referenced notice exists but is not in a published state.',
  ),
  ErrorCatalogEntry(
    code: 'ALREADY_CONSENTED',
    description:
        'A consent decision already exists for this (user, notice, purpose) and the request would duplicate it.',
  ),
  ErrorCatalogEntry(
    code: 'NOT_ASSOCIATED_WITH_ORG',
    description:
        'The authenticated principal does not belong to the organization the request targets.',
  ),
  ErrorCatalogEntry(
    code: 'INVALID_STATUS_TRANSITION',
    description:
        "The requested status change is not a valid transition from the resource's current status.",
  ),
  ErrorCatalogEntry(
    code: 'SDK_VERSION_UNSUPPORTED',
    description:
        "The calling SDK's version is below the server's configured minimum-supported floor (ADR-002 D6).",
  ),
  ErrorCatalogEntry(
    code: 'NOT_FOUND',
    description:
        'The requested resource does not exist or is not visible to the authenticated principal.',
  ),
  ErrorCatalogEntry(
    code: 'UNAUTHORIZED',
    description:
        'The request is missing valid authentication or the credential does not grant access to this resource.',
  ),
  ErrorCatalogEntry(
    code: 'RATE_LIMITED',
    description: 'The request was rejected because the caller exceeded a rate limit.',
  ),
  ErrorCatalogEntry(
    code: 'VALIDATION_ERROR',
    description:
        'The request failed validation and no more specific code applies; the human-readable error message has details.',
  ),
];

/// Typed convenience wrapper around the wire-level error codes. This is
/// purely additive sugar — [DpdpGuardApiError.code] always carries the raw
/// server string, and [fromWireValue] intentionally returns `null` instead
/// of throwing when the server has already shipped a newer code than this
/// SDK version knows about.
enum ApiErrorCode {
  minorTrackingBlocked('MINOR_TRACKING_BLOCKED'),
  noticeNotPublished('NOTICE_NOT_PUBLISHED'),
  alreadyConsented('ALREADY_CONSENTED'),
  notAssociatedWithOrg('NOT_ASSOCIATED_WITH_ORG'),
  invalidStatusTransition('INVALID_STATUS_TRANSITION'),
  sdkVersionUnsupported('SDK_VERSION_UNSUPPORTED'),
  notFound('NOT_FOUND'),
  unauthorized('UNAUTHORIZED'),
  rateLimited('RATE_LIMITED'),
  validationError('VALIDATION_ERROR');

  final String wireValue;

  const ApiErrorCode(this.wireValue);

  /// Looks up the enum member matching a wire-format code (e.g. `"NOT_FOUND"`),
  /// or `null` if it isn't one this SDK version recognizes.
  static ApiErrorCode? fromWireValue(String value) {
    for (final code in ApiErrorCode.values) {
      if (code.wireValue == value) {
        return code;
      }
    }
    return null;
  }
}

/// Thrown by [DpdpGuardClient] for any non-2xx `/api/v1` response. `code` is
/// the ADR-002 `code` field from the response body (or `"VALIDATION_ERROR"`
/// if the body didn't include one), and `status` is the HTTP status code.
class DpdpGuardApiError implements Exception {
  final String code;
  final String message;
  final int status;

  DpdpGuardApiError(this.code, this.message, this.status);

  @override
  String toString() => 'DpdpGuardApiError($code, status: $status): $message';
}
