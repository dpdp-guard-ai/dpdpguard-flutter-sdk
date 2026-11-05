# dpdpguard-flutter-sdk

DPDP Guard Flutter SDK - typed HTTP client over DPDP Guard's public `/api/v1` surface.

Package: `dpdpguard_flutter`

Part of the DPDP Guard SDK family. See the design spec:
https://github.com/chintans/dpdpbot/blob/main/docs/specs/mobile-server-sdk.md

## What's here vs. what's not

This repo was originally scaffolded (by hand — `flutter create` failed in
that environment) on the assumption it would become a platform-channel
plugin bridging over the native Android/iOS consent engines (ADR-005). On
review that's the wrong shape: `dpdpguard-android-sdk` and
`dpdpguard-ios-sdk` are separate, independently-versioned native libraries
(ADR-003), and bridging to them would tie every Flutter release to whatever
native SDK versions happen to be vendored alongside it, for no benefit —
none of this SDK's functionality needs on-device native code.

What's implemented instead is the **HTTP client layer**: a typed
`DpdpGuardClient` over DPDP Guard's public `/api/v1` (spec §4.2), using
`package:http`, following the same pattern as
`dpdpguard-server-sdk`/`dpdpguard-js-sdk`/`dpdpguard-react-native-sdk` — no
platform channel, no native folders, no generated plugin registrant. This
mirrors `dpdpguard-react-native-sdk`'s design exactly, for consistency
across both hybrid SDKs.

**Deliberately excluded, for security, not by omission:**

- **No `brokerToken()`.** Minting a brokered access token (ADR-004 D1/D2)
  requires a service API key (`convex/apiKeys.ts`), which must never ship
  inside a mobile app bundle — it's extractable from any app binary.
  Brokering stays server-side: your own backend holds the API key, calls
  DPDP Guard's `/api/v1/auth/broker-token`, and hands the resulting
  short-lived access token to the app. `DpdpGuardClient` takes that token
  via `setAccessToken()` / the constructor, nothing more.
- **No audit-hash or webhook-signature code.** Both require the platform's
  HMAC secret (`DPDP_AUDIT_HASH_HMAC_SECRET` / a webhook endpoint's own
  secret) — server-only concerns, irrelevant to and unsafe inside a mobile
  client.

## Usage

```dart
import 'package:dpdpguard_flutter/dpdpguard_flutter.dart';

final client = DpdpGuardClient(
  baseUrl: 'https://<your-deployment>.convex.site',
);

// Get a token from YOUR OWN backend (which holds the service API key and
// calls /api/v1/auth/broker-token), then:
client.setAccessToken(tokenFromMyBackend);

final requests = await client.listDsrRequests();
await client.createDsrRequest(organizationId: orgId, type: 'erasure');

// Public reads need no auth at all.
final org = await client.getOrganization('acme');
final notices = await client.getNotices(org.orgId);

// Recording consent from a banner shown *before* login (ADR-004 D6) needs
// no auth either — just a client-generated anonymousId. Reconcile it into
// the signed-in user's profile later with linkAnonymousConsent().
await client.giveConsentAnonymous(
  organizationId: org.orgId,
  noticeId: notices.first.id,
  purpose: 'Analytics',
  dataTypes: ['deviceId'],
  anonymousId: anonymousId,
);
```

Every non-2xx response throws a `DpdpGuardApiError` with a `code` from the
ADR-002 error catalog (`err.code`, e.g. `"NOT_FOUND"`) and the HTTP
`status`.

`hasConsent(consents, purpose)` (from `consent_gate.dart`) is a pure,
network-free helper for gating a feature/tracker on a consent decision you
already have in memory — combine it with `DpdpGuardClient`'s reads or your
own cached consent state.

## Contract

There is no published Dart/pub.dev contract package yet (unlike
`@dpdpguard/contract` for JS/RN), so this SDK hand-ports the pieces it
needs from `openapi/v1.yaml` — same tradeoff `dpdpguard-android-sdk` and
`dpdpguard-ios-sdk` make:

- `contract/CONTRACT_VERSION` — the `@dpdpguard/contract` release the files
  below were last synced against: **1.9.0**.
- `lib/src/models.dart` — request/response shapes, hand-ported from the
  OpenAPI spec.
- `lib/src/error_catalog.dart` — the ADR-002 D2 error catalog, hand-copied
  from `contract/conformance/error-catalog.json` (vendored into this repo
  at `contract/conformance/error-catalog.json`). `test/error_catalog_test.dart`
  pins the two against each other so they can never silently drift apart.

## Testing

```bash
flutter pub get
flutter test
```

`test/client_test.dart` uses `package:http/testing.dart`'s `MockClient` —
no network access needed.

Published on pub.dev as [`dpdpguard_flutter`](https://pub.dev/packages/dpdpguard_flutter).
Releases after `0.1.0` are tag-triggered via `.github/workflows/publish.yml`
(pub.dev's OIDC "Automated publishing", the same trusted-publisher pattern
`dpdpguard-react-native-sdk` uses for npm) — push a `v*` tag to publish.
