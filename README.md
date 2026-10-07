# antigravity_platformer

Antigravity platformer

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
## iOS IPA GitHub Actions

The workflow at `.github/workflows/build-ipa.yml` builds an Ad Hoc IPA for every push to `main` that changes the Flutter or iOS project files.

### Required GitHub secrets

Set these repository secrets in **Settings → Secrets and variables → Actions**:

- `APPLE_TEAM_ID`: the 10-character Apple Developer Team ID.
- `APPLE_BUNDLE_ID`: `com.antigravity.antigravityPlatformer`.
- `APPLE_CERTIFICATE_BASE64`: Base64-encoded Apple Distribution certificate in `.p12` format.
- `APPLE_CERTIFICATE_PASSWORD`: the certificate password.
- `APPLE_PROVISIONING_PROFILE_BASE64`: Base64-encoded provisioning profile for the Ad Hoc distribution.
- `KEYCHAIN_PASSWORD`: optional; defaults to `flutter-ci-keychain` when omitted.

The certificate and profile must be generated from the same Apple Developer account and the profile must contain the above bundle ID.

### Build and artifact

Run the workflow manually from the GitHub Actions tab or push to `main`. The resulting IPA is uploaded as a workflow artifact named `antigravity-platformer-ipa`.

> An IPA built with an Ad Hoc profile is not automatically submitted to App Store Connect. A production App Store build requires an App Store Distribution certificate, provisioning profile, and an upload step.
