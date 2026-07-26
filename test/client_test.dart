import 'dart:convert';

import 'package:dpdpguard_flutter/dpdpguard_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _jsonResponse(int status, Object body) {
  return http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );
}

void main() {
  group('DpdpGuardClient', () {
    test('getOrganization calls the public endpoint with no Authorization header', () async {
      http.Request? capturedRequest;
      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return _jsonResponse(200, {
          'orgId': 'org_1',
          'name': 'Acme',
          'slug': 'acme',
        });
      });
      final client = DpdpGuardClient(
        DpdpGuardClientOptions(
          baseUrl: 'https://example.convex.site',
          httpClient: mockClient,
        ),
      );

      final org = await client.getOrganization('acme');

      expect(org.orgId, 'org_1');
      expect(org.name, 'Acme');
      expect(org.slug, 'acme');
      expect(
        capturedRequest!.url.toString(),
        'https://example.convex.site/api/v1/org/acme',
      );
      expect(capturedRequest!.headers.containsKey('Authorization'), isFalse);
    });

    test(
      'brokerToken authenticates with the API key and stores the returned access token',
      () async {
        final capturedRequests = <http.Request>[];
        final mockClient = MockClient((request) async {
          capturedRequests.add(request);
          if (capturedRequests.length == 1) {
            return _jsonResponse(201, {
              'accessToken': 'brokered-token-abc',
              'expiresAt': 1234567890,
              'tokenType': 'Bearer',
            });
          }
          return _jsonResponse(200, {'requests': <dynamic>[]});
        });
        final client = DpdpGuardClient(
          DpdpGuardClientOptions(
            baseUrl: 'https://example.convex.site',
            apiKey: 'svc_key_123',
            httpClient: mockClient,
          ),
        );

        final result = await client.brokerToken('fiduciary-user-1');
        expect(result.accessToken, 'brokered-token-abc');
        expect(capturedRequests[0].headers['Authorization'], 'Bearer svc_key_123');

        // The stored token is now used for subsequent authenticated calls.
        await client.listDsrRequests();
        expect(capturedRequests[1].headers['Authorization'], 'Bearer brokered-token-abc');
      },
    );

    test(
      'an authenticated call without a prior brokerToken() or constructor token throws',
      () async {
        final mockClient = MockClient((request) async {
          return _jsonResponse(200, {'requests': <dynamic>[]});
        });
        final client = DpdpGuardClient(
          DpdpGuardClientOptions(
            baseUrl: 'https://example.convex.site',
            httpClient: mockClient,
          ),
        );

        await expectLater(client.listDsrRequests(), throwsA(isA<StateError>()));
      },
    );

    test('a non-2xx response is thrown as a typed DpdpGuardApiError', () async {
      final mockClient = MockClient((request) async {
        return _jsonResponse(404, {
          'code': 'NOT_FOUND',
          'error': 'No such organization',
        });
      });
      final client = DpdpGuardClient(
        DpdpGuardClientOptions(
          baseUrl: 'https://example.convex.site',
          httpClient: mockClient,
        ),
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

    test('createDsrRequest forwards an Idempotency-Key header when provided', () async {
      http.Request? capturedRequest;
      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return _jsonResponse(201, {
          'requestId': 'dsr_1',
          'type': 'erasure',
          'status': 'pending',
        });
      });
      final client = DpdpGuardClient(
        DpdpGuardClientOptions(
          baseUrl: 'https://example.convex.site',
          accessToken: 'token-abc',
          httpClient: mockClient,
        ),
      );

      await client.createDsrRequest(
        organizationId: 'org_1',
        type: 'erasure',
        idempotencyKey: 'idem-key-1',
      );

      expect(capturedRequest!.headers['Idempotency-Key'], 'idem-key-1');
    });

    test('getNomination returns null when the server responds with JSON null', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          'null',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final client = DpdpGuardClient(
        DpdpGuardClientOptions(
          baseUrl: 'https://example.convex.site',
          accessToken: 'token-abc',
          httpClient: mockClient,
        ),
      );

      final nomination = await client.getNomination();
      expect(nomination, isNull);
    });

    test('revokeNomination parses the boolean revoked field', () async {
      final mockClient = MockClient((request) async {
        return _jsonResponse(200, {'revoked': true});
      });
      final client = DpdpGuardClient(
        DpdpGuardClientOptions(
          baseUrl: 'https://example.convex.site',
          accessToken: 'token-abc',
          httpClient: mockClient,
        ),
      );

      final revoked = await client.revokeNomination();
      expect(revoked, isTrue);
    });
  });
}
