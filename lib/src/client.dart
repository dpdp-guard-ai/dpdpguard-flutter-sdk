import 'dart:convert';

import 'package:http/http.dart' as http;

import 'error_catalog.dart';
import 'models.dart';

enum _AuthMode { none, bearer }

class _RequestOptions {
  final Object? body;
  final _AuthMode auth;
  final Map<String, String>? headers;

  const _RequestOptions(
      {this.body, this.auth = _AuthMode.bearer, this.headers});
}

/// Thin typed client over DPDP Guard's public `/api/v1` (spec §4.2), for use
/// from a Flutter app. Wraps the OpenAPI-described request/response shapes
/// (`models.dart`) in ergonomic methods, and maps every non-2xx response to
/// a [DpdpGuardApiError] keyed by the ADR-002 error catalog's `code`.
///
/// This is a pure-Dart HTTP client - there is no platform channel and no
/// native Android/iOS code involved. `dpdpguard-android-sdk` and
/// `dpdpguard-ios-sdk` are separate, independently-versioned native
/// libraries (ADR-003); bridging to them would tie every Flutter release to
/// whatever native SDK versions happen to be vendored, for no benefit, since
/// none of this SDK's functionality needs on-device native code. This
/// mirrors `dpdpguard-react-native-sdk`'s design, for consistency across
/// both hybrid SDKs.
///
/// Deliberately excluded, for security, not by omission:
///
/// - No `brokerToken()`. Minting a brokered access token (ADR-004 D1/D2)
///   requires a service API key (`convex/apiKeys.ts`), which must never ship
///   inside a mobile app bundle - it's extractable from any app binary.
///   Brokering stays server-side: your own backend holds the API key, calls
///   DPDP Guard's `/api/v1/auth/broker-token`, and hands the resulting
///   short-lived access token to the app. [DpdpGuardClient] takes that token
///   via [setAccessToken] / the constructor, nothing more.
/// - No audit-hash or webhook-signature code. Both require the platform's
///   HMAC secret (`DPDP_AUDIT_HASH_HMAC_SECRET` / a webhook endpoint's own
///   secret) - server-only concerns, irrelevant to and unsafe inside a
///   mobile client.
class DpdpGuardClient {
  final String _baseUrl;
  String? _accessToken;
  final http.Client _httpClient;

  DpdpGuardClient({
    required String baseUrl,
    String? accessToken,
    http.Client? httpClient,
  })  : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
        _accessToken = accessToken,
        _httpClient = httpClient ?? http.Client();

  /// Set/replace the brokered principal access token (e.g. after your
  /// backend re-brokers on expiry).
  void setAccessToken(String token) {
    _accessToken = token;
  }

  Future<T> _request<T>(
    String method,
    String path,
    T Function(dynamic json) decode, {
    _RequestOptions options = const _RequestOptions(),
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...?options.headers,
    };

    if (options.auth == _AuthMode.bearer) {
      final token = _accessToken;
      if (token == null) {
        throw StateError(
          'DpdpGuardClient: this call requires an access token - call setAccessToken() with a token from your own backend first.',
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }

    final uri = Uri.parse('$_baseUrl$path');
    final body = options.body != null ? jsonEncode(options.body) : null;
    final response = await _send(method, uri, headers, body);

    final text = response.body;
    final dynamic json = text.isNotEmpty ? jsonDecode(text) : null;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final code = (json is Map && json['code'] != null)
          ? json['code'].toString()
          : 'VALIDATION_ERROR';
      final message = (json is Map && json['error'] != null)
          ? json['error'].toString()
          : 'Request failed with status ${response.statusCode}';
      throw DpdpGuardApiError(code, message, response.statusCode);
    }

    return decode(json);
  }

  Future<http.Response> _send(
    String method,
    Uri uri,
    Map<String, String> headers,
    String? body,
  ) {
    switch (method) {
      case 'GET':
        return _httpClient.get(uri, headers: headers);
      case 'DELETE':
        return _httpClient.delete(uri, headers: headers, body: body);
      case 'POST':
        return _httpClient.post(uri, headers: headers, body: body ?? '');
      case 'PUT':
        return _httpClient.put(uri, headers: headers, body: body ?? '');
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  // --- Public reads (no auth) ---

  Future<OrgSummary> getOrganization(String slug) => _request(
        'GET',
        '/api/v1/org/${Uri.encodeComponent(slug)}',
        (json) => OrgSummary.fromJson(json as Map<String, dynamic>),
        options: const _RequestOptions(auth: _AuthMode.none),
      );

  Future<List<Notice>> getNotices(String orgId) => _request(
        'GET',
        '/api/v1/org/${Uri.encodeComponent(orgId)}/notices',
        (json) =>
            ((json as Map<String, dynamic>)['notices'] as List<dynamic>? ??
                    const [])
                .map((e) => Notice.fromJson(e as Map<String, dynamic>))
                .toList(),
        options: const _RequestOptions(auth: _AuthMode.none),
      );

  Future<Notice> getNotice(String noticeId) => _request(
        'GET',
        '/api/v1/notices/${Uri.encodeComponent(noticeId)}',
        (json) => Notice.fromJson(json as Map<String, dynamic>),
        options: const _RequestOptions(auth: _AuthMode.none),
      );

  Future<BannerConfigResponse> getBannerConfig(
    String orgId, {
    String? domain,
    String? appId,
  }) {
    final query = <String, String>{
      if (domain != null) 'domain': domain,
      if (appId != null) 'appId': appId,
    };
    final qs = query.isEmpty
        ? ''
        : '?${query.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
    return _request(
      'GET',
      '/api/v1/org/${Uri.encodeComponent(orgId)}/banner-config$qs',
      (json) => BannerConfigResponse.fromJson(json as Map<String, dynamic>),
      options: const _RequestOptions(auth: _AuthMode.none),
    );
  }

  // --- Anonymous -> known-user reconciliation (ADR-004 D3) ---

  Future<LinkAnonymousConsentResponse> linkAnonymousConsent(
          String anonymousId) =>
      _request(
        'POST',
        '/api/v1/link-anonymous-consent',
        (json) =>
            LinkAnonymousConsentResponse.fromJson(json as Map<String, dynamic>),
        options: _RequestOptions(body: {'anonymousId': anonymousId}),
      );

  /// Records consent for a not-yet-authenticated guest (ADR-004 D6), e.g.
  /// from a consent banner shown before login. Unauthenticated, rate-limited
  /// public write, keyed by a client-generated `anonymousId`.
  Future<GiveConsentAnonymousResponse> giveConsentAnonymous({
    required String organizationId,
    required String noticeId,
    required String purpose,
    required List<String> dataTypes,
    required String anonymousId,
    String? idempotencyKey,
  }) =>
      _request(
        'POST',
        '/api/v1/consents/anonymous',
        (json) =>
            GiveConsentAnonymousResponse.fromJson(json as Map<String, dynamic>),
        options: _RequestOptions(
          auth: _AuthMode.none,
          body: {
            'organizationId': organizationId,
            'noticeId': noticeId,
            'purpose': purpose,
            'dataTypes': dataTypes,
            'anonymousId': anonymousId,
          },
          headers: idempotencyKey != null
              ? {'Idempotency-Key': idempotencyKey}
              : null,
        ),
      );

  // --- DSR (spec §4.2) ---

  Future<List<DsrRequest>> listDsrRequests() => _request(
        'GET',
        '/api/v1/dsr',
        (json) =>
            ((json as Map<String, dynamic>)['requests'] as List<dynamic>? ??
                    const [])
                .map((e) => DsrRequest.fromJson(e as Map<String, dynamic>))
                .toList(),
      );

  Future<DsrRequest> createDsrRequest({
    required String organizationId,
    required String type,
    String? details,
    String? idempotencyKey,
  }) =>
      _request(
        'POST',
        '/api/v1/dsr',
        (json) => DsrRequest.fromJson(json as Map<String, dynamic>),
        options: _RequestOptions(
          body: {
            'organizationId': organizationId,
            'type': type,
            if (details != null) 'details': details,
          },
          headers: idempotencyKey != null
              ? {'Idempotency-Key': idempotencyKey}
              : null,
        ),
      );

  // --- Grievances (spec §4.2) ---

  Future<List<Grievance>> listGrievances() => _request(
        'GET',
        '/api/v1/grievances',
        (json) =>
            ((json as Map<String, dynamic>)['grievances'] as List<dynamic>? ??
                    const [])
                .map((e) => Grievance.fromJson(e as Map<String, dynamic>))
                .toList(),
      );

  Future<Grievance> createGrievance({
    required String organizationId,
    required String subject,
    required String description,
  }) =>
      _request(
        'POST',
        '/api/v1/grievances',
        (json) => Grievance.fromJson(json as Map<String, dynamic>),
        options: _RequestOptions(
          body: {
            'organizationId': organizationId,
            'subject': subject,
            'description': description,
          },
        ),
      );

  // --- Nomination (spec §4.2) ---

  Future<Nomination?> getNomination() => _request(
        'GET',
        '/api/v1/nomination',
        (json) => json == null
            ? null
            : Nomination.fromJson(json as Map<String, dynamic>),
      );

  Future<Nomination> upsertNomination({
    required String nomineeName,
    required String nomineeContact,
  }) =>
      _request(
        'PUT',
        '/api/v1/nomination',
        (json) => Nomination.fromJson(json as Map<String, dynamic>),
        options: _RequestOptions(
          body: {'nomineeName': nomineeName, 'nomineeContact': nomineeContact},
        ),
      );

  Future<bool> revokeNomination() => _request(
        'DELETE',
        '/api/v1/nomination',
        (json) => (json as Map<String, dynamic>)['revoked'] as bool,
      );
}
