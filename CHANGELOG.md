# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-08-12

### Added

- `contract/CONTRACT_VERSION` — a plain-text, single-line marker (`1.5.0`)
  pinning which `@dpdpguard/contract` release this repo's vendored files
  were last synced against. This repo previously had no version marker at
  all; that gap is fixed here, not deferred.

### Changed

- Synced `contract/conformance/error-catalog.json` to
  `@dpdpguard/contract@1.5.0`'s catalog (unchanged since `1.2.0`; this
  repo's copy dated to the `0.2.0`-era initial vendoring and had drifted).
  Eleven new codes were added, all specific to the `/mcp/v1` agent surface
  (ADR-007) that this SDK's `/api/v1`-only `DpdpGuardClient` never calls and
  never receives in practice: `SCOPE_INSUFFICIENT`, `TOOL_NOT_AVAILABLE`,
  `ORG_DISABLED`, `APPROVAL_REQUIRED`, `APPROVAL_BACKLOG_FULL`,
  `PROPOSAL_EXPIRED`, `SECOND_REVIEWER_REQUIRED`, `PROPOSAL_ALREADY_REVIEWED`,
  `DATA_VOLUME_EXCEEDED`, `PLAN_LIMIT_REACHED`, `AGENT_WRITE_BLOCKED`.
  Added matching `ErrorCatalogEntry` / `ApiErrorCode` enum cases and wire
  mappings in `lib/src/error_catalog.dart` so the catalog stays byte-for-byte
  with upstream and `test/error_catalog_test.dart`'s drift guard keeps
  passing. `DpdpGuardApiError.typedCode`'s existing `null`-fallback for
  unrecognized codes (the ADR-002 tolerant-reader rule) already covered
  forward-compatibility even before this sync — no behavior change there.
- Minor version bump (contract sync since `1.0.0`'s vendoring was purely
  additive per ADR-002 D4: new error codes, and — across `1.1.0`–`1.5.0` of
  `@dpdpguard/contract` — new read-only `/api/v1` partner/offline/Consent-Gate
  routes and a documentation-only audit-hash key-versioning note, none of
  which this SDK implements or is affected by). No audit-hash
  canonicalization or algorithm change was found in the diff (ADR-002 D5);
  no DPO sign-off was required.

### Notes / follow-ups

- This repo does not vendor `openapi/v1.yaml` (by design — see README
  "Contract" section: request/response shapes are hand-ported into
  `lib/src/models.dart` instead). None of the new endpoints added upstream
  between `1.1.0` and `1.5.0` (`/api/v1/retention/due`, `/api/v1/breaches`,
  `/api/v1/cross-border/transfers`, `/api/v1/offline-consent/links`,
  `/api/v1/offline/*`, `/api/v1/consent/verify`, `/api/v1/consent/gate/*`)
  are implemented by this SDK's `DpdpGuardClient`; implementing any of them
  is a separate, deliberate feature addition, not part of this sync.
- The audit-hash spec's `f5f941c` "Key versions" addition (contract `1.5.0`)
  and the `dpdpcca/2` capture-artifact canonicalization (contract `1.4.0`)
  are both out of scope here: neither is active by default, this SDK ships
  no audit-hash or capture-signing code (README "Deliberately excluded"),
  and no vector file for either is vendored in this repo.

## [1.0.0] - 2026-07-29

### Changed

Major version bump forced by the upstream `@dpdpguard/contract` 1.0.0
breaking change (tightened request-body validation on several fields,
optional `Idempotency-Key` on grievance filing). No functional changes
to this SDK's own code.

## [0.1.0] - 2026-07-26

Initial release. A pure-Dart `DpdpGuardClient` over DPDP Guard's public
`/api/v1` (notices, DSR requests, grievances, nomination, anonymous
consent), plus `hasConsent` and the ADR-002 error catalog — no platform
channel, mirroring `dpdpguard-react-native-sdk`'s design.
