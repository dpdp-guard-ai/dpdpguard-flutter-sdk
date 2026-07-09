# dpdpguard-flutter-sdk

DPDP Guard Flutter plugin - platform-channel bridge over the native consent engines

Package: `dpdpguard_flutter`

Part of the DPDP Guard SDK family. See the design spec:
https://github.com/chintans/dpdpbot/blob/main/docs/specs/mobile-server-sdk.md

> **Note:** lutter create failed in this environment (the local Flutter
> toolchain reports "Unable to find git in your PATH" even for lutter
> doctor, unrelated to this script — likely a broken Flutter install). This
> is a minimal hand-written skeleton. Once Flutter is working, regenerate with:
> `
> flutter create --template=plugin --org ai.dpdpguard --project-name dpdpguard_flutter -a kotlin -i swift dpdpguard-flutter-sdk
> `
"@
    New-CiWorkflow E:\Github\chintans\dpdpguard-flutter-sdk @"
name: CI
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
