# Android and iPhone through Codemagic

Godot exports Android and iOS. Use a custom YAML workflow on Codemagic; the
project is not a Flutter project. Pin the editor and export templates to the
same version (currently 4.5.1).

## First connection

1. Put this folder into your own Git repository and connect it to Codemagic.
2. Select the `godot-validate` YAML workflow. This is validation only.
3. Confirm the project's final unique application ID before creating store
   records or signing profiles. No final identifier has been assigned yet.

## Android test APK

The `android-test` workflow now builds an ARM64 debug APK using Godot 4.5.1,
Java 17 and Android SDK 35. It imports the project, runs four check suites,
then collects `build/android/ishaqs-fishing-trip.apk` as a downloadable artifact.

1. Commit and push the current project, including `codemagic.yaml`,
   `export_presets.cfg`, `tools/ci-android.sh`, assets and scripts to your GitHub
   repository (`websitebuild8/flygame`). Do not include `.godot/` or signing keys.
2. In Codemagic choose **Add application**, connect GitHub and select this repo.
   Choose the **Other** project type if asked; use YAML configuration.
3. Select the branch containing these files. Check for `codemagic.yaml`.
4. Start a new build with workflow **android-test** (Android test APK).
5. After success, download the APK from the build's **Artifacts** section.
6. Open it on an ARM64 Android phone and allow installation from that download
   source when Android asks. This does not require a Google Play account.

This configuration has been checked locally, but its first Codemagic run is still
required to verify the hosted runner and generated APK. It uses the development
package ID `com.ishaq.fishingtrip.dev`; it does not publish to any store.
The runner uses a debug key. If later builds use a different debug key, Android
may require uninstalling the old app first (which removes its local saved game).
Keep a stable private signing key when moving to regular distribution.

Release APK/AAB builds need a private Android keystore kept in Codemagic secrets.
Google Play publishing requires a developer account and a final application ID.

## iPhone device build (next stage)

Use a macOS runner with Xcode. Install matching Godot export templates and add
an iOS export preset. Supply the Apple Team ID and final bundle identifier.
Export the Godot project to an Xcode project, then archive/sign it and export
an IPA using Codemagic's signing tools. Device distribution needs a matching
certificate and provisioning profile. TestFlight/App Store distribution needs
Apple Developer Program membership. Store credentials in Codemagic, never in Git.

The Android test workflow does not upload to stores. iOS still needs export
configuration and signing credentials. An actual successful cloud build and
phone test are required before calling either mobile build verified.

## Costs

The engine is free. Codemagic usage is subject to its plan and build-minute
allowances; cloud builds are not guaranteed to remain free. Store account fees
are separate. Check the account's current allowance before enabling automatic
build triggers. The workflow has no automatic triggers or publishing steps.

References:
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html
- https://docs.codemagic.io/yaml-basic-configuration/yaml-getting-started/

## Fishing feedback

Enable `permissions/vibrate` in the Android export preset before device builds.
Godot's `Input.vibrate_handheld` supports Android/iOS; actual feedback depends on
hardware and device settings. Desktop testing does not validate phone haptics.
