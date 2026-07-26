import 'dart:convert';

import 'package:http/http.dart' as http;

import 'error_catalog.dart';
import 'models.dart';

enum _AuthMode { none, apiKey, bearer }

/// Constructor options for [DpdpGuardClient].
class DpdpGuardClientOptions {
  /// e.g. `"https://trustworthy-alligator-303.convex.site"`. A trailing
  /// slash is stripped automatically.
  final String baseUrl;

  /// Service API key (see the server's `convex/apiKeys.ts`) — required for
  /// [DpdpGuardClient.brokerToken].
  final String? apiKey;

  /// A brokered principal access token, if one has already been minted
  /// (e.g. restored from secure storage).
  final String? accessToken;

  /// Override for testing (e.g. `package:http/testing.dart`'s `MockClient`);
  /// defaults to a fresh `http.Client()`.
  final http.Client? httpClient;

  const DpdpGuardClientOptions({
    required this.baseUrl,
    this.apiKey,
    this.accessToken,
    this.httpClient,
  });
}

/// Thin typed client over DPDP Guard's public `/api/v1` surface
/// (`docs/specs/mobile-server-sdk.md` §4). Ported from the Node reference
/// SDK's `client.ts`. Maps every non-2xx response to a [DpdpGuardApiError]
/// keyed by the ADR-002 error catalog's `code`.
class DpdpGuardClient {
  final String _baseUrl;
  final String? _apiKey;
  String? _accessToken;
  final http.Client _httpClient;

  DpdpGuardClient(DpdpGuardClientOptions options)
      : _baseUrl = _stripTrailingSlash(options.baseUrl),
        _apiKey = options.apiKey,
        _accessToken = options.accessToken,
        _httpClient = options.httpClient ?? http.Client();

  static String _stripTrailingSlash(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Set/replace the brokered principal access token (e.g. after
  /// re-brokering on expiry).
  void setAccessToken(String token) {
    _accessToken = token;
  }

  /// Releases the underlying `http.Client`'s resources. Only call this if
  /// this [DpdpGuardClient] owns its `httpClient` (i.e. you did not pass one
  /// in via [DpdpGuardClientOptions.httpClient] that you still need
  /// elsewhere).
  void close() {
    _httpClient.close();
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Object? body,
    _AuthMode auth = _AuthMode.bearer,
    Map<String, String>? headers,
  }) async {
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
    };
    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    if (auth == _AuthMode.apiKey) {
      final key = _apiKey;
      if (key == null) {
        throw StateError(
          'DpdpGuardClient: this call requires `apiKey` to be set in the constructor.',
        );
      }
      requestHeaders['Authorization'] = 'Bearer $key';
    } else if (auth == _AuthMode.bearer) {
      final token = _accessToken;
      if (token == null) {
        throw StateError(
          'DpdpGuardClient: this call requires an access token - call '
          'brokerToken() first, or pass `accessToken` in the constructor.',
        );
      }
      requestHeaders['Authorization'] = 'Bearer $token';
    }

    final uri = Uri.parse('$_baseUrl$path');
    final request = http.Request(method, uri);
    request.headers.addAll(requestHeaders);
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    final text = response.body;
    dynamic json;
    if (text.isNotEmpty) {
      json = jsonDecode(text);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      var code = 'VALIDATION_ERROR';
      var message = 'Request failed with status ${response.statusCode}';
      if (json is Map<String, dynamic>) {
        final codeValue = json['code'];
        if (codeValue != null) {
          code = codeValue.toString();
        }
        final errorValue = json['error'];
        if (errorValue != null) {
          message = errorValue.toString();
        }
      }
      throw DpdpGuardApiError(code, message, response.statusCode);
    }

    return json;
  }

  // --- Public reads (no auth) ---

  /// `GET /api/v1/org/{slug}` — resolve an organization by slug.
  Future<OrgSummary> getOrganization(String slug) async {
    final json = await _request(
      'GET',
      '/api/v1/org/${Uri.encodeComponent(slug)}',
      auth: _AuthMode.none,
    );
    return OrgSummary.fromJson(json as Map<String, dynamic>);
  }

  /// `GET /api/v1/org/{orgId}/notices` — list published notices for an org.
  Future<List<Notice>> getNotices(String orgId) async {
    final json = await _request(
      'GET',
      '/api/v1/org/${Uri.encodeComponent(orgId)}/notices',
      auth: _AuthMode.none,
    );
    final map = json as Map<String, dynamic>;
    final notices = map['notices'] as List<dynamic>? ?? const [];
    return notices.map((n) => Notice.fromJson(n as Map<String, dynamic>)).toList();
  }

  /// `GET /api/v1/notices/{noticeId}` — fetch a single notice.
  Future<Notice> getNotice(String noticeId) async {
    final json = await _request(
      'GET',
      '/api/v1/notices/${Uri.encodeComponent(noticeId)}',
      auth: _AuthMode.none,
    );
    return Notice.fromJson(json as Map<String, dynamic>);
  }

  /// `GET /api/v1/org/{orgId}/banner-config` — resolve banner config for a
  /// web domain (`domain`), native app (`appId`), or org-default (neither).
  Future<BannerConfig> getBannerConfig(
    String orgId, {
    String? domain,
    String? appId,
  }) async {
    final queryParams = <String, String>{};
    if (domain != null && domain.isNotEmpty) {
      queryParams['domain'] = domain;
    }
    if (appId != null && appId.isNotEmpty) {
      queryParams['appId'] = appId;
    }
    final query = queryParams.isEmpty ? '' : Uri(queryParameters: queryParams).query;
    final path = '/api/v1/org/${Uri.encodeComponent(orgId)}/banner-config'
        '${query.isEmpty ? '' : '?$query'}';
    final json = await _request('GET', path, auth: _AuthMode.none);
    return BannerConfig.fromJson(json as Map<String, dynamic>);
  }

  // --- Auth (ADR-004) ---

  /// `POST /api/v1/auth/broker-token` — mints a brokered principal access
  /// token using the service API key, and stores it for subsequent
  /// authenticated calls.
  Future<BrokeredToken> brokerToken(String externalId) async {
    final json = await _request(
      'POST',
      '/api/v1/auth/broker-token',
      body: {'externalId': externalId},
      auth: _AuthMode.apiKey,
    );
    final result = BrokeredToken.fromJson(json as Map<String, dynamic>);
    _accessToken = result.accessToken;
    return result;
  }

  /// `POST /api/v1/link-anonymous-consent` — reconcile a guest's anonymous
  /// consent trail into the now-known principal (ADR-004 D3).
  Future<LinkAnonymousConsentResult> linkAnonymousConsent(String anonymousId) async {
    final json = await _request(
      'POST',
      '/api/v1/link-anonymous-consent',
      body: {'anonymousId': anonymousId},
    );
    return LinkAnonymousConsentResult.fromJson(json as Map<String, dynamic>);
  }

  // --- DSR (spec §4.2) ---

  /// `GET /api/v1/dsr` — list the caller's own DSR requests.
  Future<List<DsrRequest>> listDsrRequests() async {
    final json = await _request('GET', '/api/v1/dsr');
    final map = json as Map<String, dynamic>;
    final requests = map['requests'] as List<dynamic>? ?? const [];
    return requests.map((r) => DsrRequest.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// `POST /api/v1/dsr` — file a Data Subject Request. Pass [idempotencyKey]
  /// to set the `Idempotency-Key` header so a retried call after a network
  /// timeout returns the original response instead of double-filing.
  Future<DsrRequest> createDsrRequest({
    required String organizationId,
    required String type,
    String? details,
    String? idempotencyKey,
  }) async {
    final body = <String, dynamic>{
      'organizationId': organizationId,
      'type': type,
    };
    if (details != null) {
      body['details'] = details;
    }
    final json = await _request(
      'POST',
      '/api/v1/dsr',
      body: body,
      headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
    );
    return DsrRequest.fromJson(json as Map<String, dynamic>);
  }

  // --- Grievances (spec §4.2) ---

  /// `GET /api/v1/grievances` — list the caller's own grievances.
  Future<List<Grievance>> listGrievances() async {
    final json = await _request('GET', '/api/v1/grievances');
    final map = json as Map<String, dynamic>;
    final grievances = map['grievances'] as List<dynamic>? ?? const [];
    return grievances.map((g) => Grievance.fromJson(g as Map<String, dynamic>)).toList();
  }

  /// `POST /api/v1/grievances` — file a grievance.
  Future<Grievance> createGrievance({
    required String organizationId,
    required String subject,
    required String description,
  }) async {
    final json = await _request(
      'POST',
      '/api/v1/grievances',
      body: {
        'organizationId': organizationId,
        'subject': subject,
        'description': description,
      },
    );
    return Grievance.fromJson(json as Map<String, dynamic>);
  }

  // --- Nomination (spec §4.2) ---

  /// `GET /api/v1/nomination` — fetch the caller's current successor
  /// nomination, or `null` if none is set.
  Future<Nomination?> getNomination() async {
    final json = await _request('GET', '/api/v1/nomination');
    if (json == null) {
      return null;
    }
    return Nomination.fromJson(json as Map<String, dynamic>);
  }

  /// `PUT /api/v1/nomination` — set or replace the caller's successor
  /// nomination.
  Future<Nomination> upsertNomination({
    required String nomineeName,
    required String nomineeContact,
  }) async {
    final json = await _request(
      'PUT',
      '/api/v1/nomination',
      body: {
        'nomineeName': nomineeName,
        'nomineeContact': nomineeContact,
      },
    );
    return Nomination.fromJson(json as Map<String, dynamic>);
  }

  /// `DELETE /api/v1/nomination` — revoke the caller's successor nomination.
  /// A no-op (still returns `true`-shaped success) if none was active.
  Future<bool> revokeNomination() async {
    final json = await _request('DELETE', '/api/v1/nomination');
    final map = json as Map<String, dynamic>;
    return map['revoked'] as bool;
  }
}
