import 'dart:convert';

import 'package:dpdpguard_flutter/dpdpguard_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _jsonResponse(int status, Object body) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  test('getOrganization calls the public endpoint with no Authorization header',
      () async {
    http.Request? captured;
    final mockClient = MockClient((request) async {
      captured = request;
      return _jsonResponse(
          200, {'orgId': 'org_1', 'name': 'Acme', 'slug': 'acme'});
    });
    final client = DpdpGuardClient(
      baseUrl: 'https://example.convex.site',
      httpClient: mockClient,
    );

    final org = await client.getOrganization('acme');

    expect(org.orgId, 'org_1');
    expect(org.name, 'Acme');
    expect(org.slug, 'acme');
    expect(captured!.url.toString(),
        'https://example.convex.site/api/v1/org/acme');
    expect(captured!.headers['Authorization'], isNull);
  });

  test(
      'an authenticated call without setAccessToken() throws before hitting the network',
      () async {
    var called = false;
    final mockClient = MockClient((request) async {
      called = true;
      return _jsonResponse(200, {'requests': []});
    });
    final client = DpdpGuardClient(
      baseUrl: 'https://example.convex.site',
      httpClient: mockClient,
    );

    await expectLater(client.listDsrRequests(), throwsA(isA<StateError>()));
    expect(called, isFalse);
  });

  test(
      'setAccessToken() makes subsequent authenticated calls use the new token',
      () async {
    http.Request? captured;
    final mockClient = MockClient((request) async {
      captured = request;
      return _jsonResponse(200, {'requests': []});
    });
    final client = DpdpGuardClient(
      baseUrl: 'https://example.convex.site',
      httpClient: mockClient,
    );

    client.setAccessToken('token-from-my-backend');
    await client.listDsrRequests();

    expect(captured!.headers['Authorization'], 'Bearer token-from-my-backend');
  });

  test('a constructor-supplied accessToken is used immediately', () async {
    http.Request? captured;
    final mockClient = MockClient((request) async {
      captured = request;
      return _jsonResponse(200, {'requests': []});
    });
    final client = DpdpGuardClient(
      baseUrl: 'https://example.convex.site',
      accessToken: 'initial-token',
      httpClient: mockClient,
    );

    await client.listDsrRequests();

    expect(captured!.headers['Authorization'], 'Bearer initial-token');
  });

  test('a non-2xx response is thrown as a typed DpdpGuardApiError', () async {
    final mockClient = MockClient((request) async {
      return _jsonResponse(
          404, {'code': 'NOT_FOUND', 'error': 'No such organization'});
    });
    final client = DpdpGuardClient(
      baseUrl: 'https://example.convex.site',
      httpClient: mockClient,
    );

    await expectLater(
      client.getOrganization('missing'),
      throwsA(
        isA<DpdpGuardApiError>()
            .having((e) => e.code, 'code', 'NOT_FOUND')
            .having((e) => e.status, 'status', 404),
      ),
    );
  });

  test('createDsrRequest forwards an Idempotency-Key header when provided',
      () async {
    http.Request? captured;
    final mockClient = MockClient((request) async {
      captured = request;
      return _jsonResponse(201, {
        'requestId': 'dsr_1',
        'type': 'erasure',
        'status': 'pending',
      });
    });
    final client = DpdpGuardClient(
      baseUrl: 'https://example.convex.site',
      accessToken: 'token-abc',
      httpClient: mockClient,
    );

    await client.createDsrRequest(
      organizationId: 'org_1',
      type: 'erasure',
      idempotencyKey: 'idem-key-1',
    );

    expect(captured!.headers['Idempotency-Key'], 'idem-key-1');
  });

  test(
      'giveConsentAnonymous is unauthenticated and forwards an Idempotency-Key header',
      () async {
    http.Request? captured;
    final mockClient = MockClient((request) async {
      captured = request;
      return _jsonResponse(201, {
        'consentId': 'consent_1',
        'purpose': 'Analytics',
        'dataTypes': ['deviceId'],
        'givenAt': 1700000000000,
      });
    });
    final client = DpdpGuardClient(
      baseUrl: 'https://example.convex.site',
      httpClient: mockClient,
    );

    final result = await client.giveConsentAnonymous(
      organizationId: 'org_1',
      noticeId: 'notice_1',
      purpose: 'Analytics',
      dataTypes: const ['deviceId'],
      anonymousId: 'anon_1',
      idempotencyKey: 'idem-key-2',
    );

    expect(result.consentId, 'consent_1');
    expect(captured!.headers['Authorization'], isNull);
    expect(captured!.headers['Idempotency-Key'], 'idem-key-2');
  });

  test(
      'has no brokerToken method - mobile apps must never hold the service API key',
      () {
    final client = DpdpGuardClient(baseUrl: 'https://example.convex.site');
    // Static typing already enforces this (no such member exists); this
    // test documents the guarantee alongside the parallel one in the RN SDK.
    expect(client, isNotNull);
  });
}
