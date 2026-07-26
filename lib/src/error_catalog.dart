/// ADR-002 D2's machine-readable error catalog - mirrored 1:1 from
/// `contract/conformance/error-catalog.json` (which itself mirrors
/// `convex/lib/apiErrors.ts`'s `API_ERROR_CODES`). Every non-2xx `/api/v1`
/// response's `code` field is one of these 10 values (or, per the tolerant-
/// reader rule, a future additional code this SDK doesn't know about yet -
/// see [DpdpGuardApiError.typedCode]).
///
/// Kept as a plain hand-copied list (rather than loaded from an installable
/// contract package, as the JS/RN SDKs do from `@dpdpguard/contract`)
/// because there is no equivalent published Dart/pub.dev contract artifact
/// yet - same tradeoff the Android/iOS SDKs make. The catalog is pinned
/// against a verbatim copy of the source JSON
/// (`contract/conformance/error-catalog.json`) in `test/error_catalog_test.dart`
/// so the two can never silently drift apart.
class ErrorCatalogEntry {
  final String code;
  final String description;

  const ErrorCatalogEntry({required this.code, required this.description});
}

const List<ErrorCatalogEntry> errorCatalog = [
  ErrorCatalogEntry(
    code: 'MINOR_TRACKING_BLOCKED',
    description:
        'Tracking/analytics consent is disabled for a verified minor and cannot be granted.',
  ),
  ErrorCatalogEntry(
    code: 'NOTICE_NOT_PUBLISHED',
    description:
        'The referenced notice exists but is not in a published state.',
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
    description:
        'The request was rejected because the caller exceeded a rate limit.',
  ),
  ErrorCatalogEntry(
    code: 'VALIDATION_ERROR',
    description:
        'The request failed validation and no more specific code applies; the human-readable error message has details.',
  ),
];

/// Stable machine-readable codes from [errorCatalog], as a closed enum for
/// convenience.
enum ApiErrorCode {
  minorTrackingBlocked,
  noticeNotPublished,
  alreadyConsented,
  notAssociatedWithOrg,
  invalidStatusTransition,
  sdkVersionUnsupported,
  notFound,
  unauthorized,
  rateLimited,
  validationError,
}

const Map<String, ApiErrorCode> _wireValueToApiErrorCode = {
  'MINOR_TRACKING_BLOCKED': ApiErrorCode.minorTrackingBlocked,
  'NOTICE_NOT_PUBLISHED': ApiErrorCode.noticeNotPublished,
  'ALREADY_CONSENTED': ApiErrorCode.alreadyConsented,
  'NOT_ASSOCIATED_WITH_ORG': ApiErrorCode.notAssociatedWithOrg,
  'INVALID_STATUS_TRANSITION': ApiErrorCode.invalidStatusTransition,
  'SDK_VERSION_UNSUPPORTED': ApiErrorCode.sdkVersionUnsupported,
  'NOT_FOUND': ApiErrorCode.notFound,
  'UNAUTHORIZED': ApiErrorCode.unauthorized,
  'RATE_LIMITED': ApiErrorCode.rateLimited,
  'VALIDATION_ERROR': ApiErrorCode.validationError,
};

/// Returns the matching [ApiErrorCode], or `null` if the server sent a code
/// newer than this SDK knows about.
ApiErrorCode? apiErrorCodeFromWireValue(String value) =>
    _wireValueToApiErrorCode[value];

/// Thrown by [DpdpGuardClient] for any non-2xx `/api/v1` response.
///
/// [code] is kept as the raw `String` from the wire (not the [ApiErrorCode]
/// enum) so a server response using a code newer than this SDK knows about
/// still produces a usable error instead of a decoding failure - see
/// [typedCode] for the typed lookup when you want it.
class DpdpGuardApiError implements Exception {
  final String code;
  final String message;
  final int status;

  DpdpGuardApiError(this.code, this.message, this.status);

  /// The typed [ApiErrorCode], or `null` if [code] isn't one of the 10 known
  /// values.
  ApiErrorCode? get typedCode => apiErrorCodeFromWireValue(code);

  @override
  String toString() => 'DpdpGuardApiError($code, $status): $message';
}
