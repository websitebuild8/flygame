# Android and iPhone through Codemagic

Godot exports Android and iOS. Use a custom YAML workflow on Codemagic; the
project is not a Flutter project. Pin the editor and export templates to the
same version (currently 4.5.1).

## First connection

1. Put this folder into your own Git repository and connect it to Codemagic.
2. Select the `godot-validate` YAML workflow. This is validation only.
3. Confirm the project's final unique application ID before creating store
   records or signing profiles. No final identifier has been assigned yet.

## Android device build (next stage)

Install matching Godot export templates, a compatible JDK and Android SDK on
the runner, configure Godot's SDK paths, and add an Android export preset.
A debug APK can be used for development. Release APK/AAB builds need a private
Android keystore kept in Codemagic secrets. Store publishing also requires a
Google Play developer account. Add artifact collection only once exports work.

## iPhone device build (next stage)

Use a macOS runner with Xcode. Install matching Godot export templates and add
an iOS export preset. Supply the Apple Team ID and final bundle identifier.
Export the Godot project to an Xcode project, then archive/sign it and export
an IPA using Codemagic's signing tools. Device distribution needs a matching
certificate and provisioning profile. TestFlight/App Store distribution needs
Apple Developer Program membership. Store credentials in Codemagic, never in Git.

The initial validation workflow deliberately does not upload to stores or
pretend to produce a signed device build. We still need export configuration,
credentials and an actual successful CI run before calling mobile builds ready.

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
