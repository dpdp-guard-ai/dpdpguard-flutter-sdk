# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-07-26

Initial release. A pure-Dart `DpdpGuardClient` over DPDP Guard's public
`/api/v1` (notices, DSR requests, grievances, nomination, anonymous
consent), plus `hasConsent` and the ADR-002 error catalog — no platform
channel, mirroring `dpdpguard-react-native-sdk`'s design.
