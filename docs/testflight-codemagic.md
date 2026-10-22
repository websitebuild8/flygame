# iPhone TestFlight build with Codemagic

The `ios-testflight` workflow exports this Godot project, runs the five gameplay
checks, signs a Release IPA and uploads it to App Store Connect. It does not
submit a public App Store release or automatically invite testers. First cloud
build/signing/upload is still to be verified on your Apple account.

## One-time Apple setup

1. Use an active Apple Developer Program membership. A free Apple account is
   insufficient for TestFlight. Standard membership is US$99/year, with regional
   prices and eligible organisation waivers.
2. In Apple Developer → Certificates, Identifiers & Profiles, register an explicit
   App ID for `com.ishaqfishingtrip.appname`. If you already registered another ID for
   this game, use that ID consistently in both Codemagic bundle fields below.
3. In App Store Connect → Apps → New App, create an iOS app named
   **Ishaq's Fishing Trip**, choose that Bundle ID, and use a unique SKU such as
   `ishaq-fishing-trip-ios`. The SKU is your internal label.
4. Find the **Team ID** in Apple Developer membership details. This is the
   10-character ID, not your App Store Connect Issuer ID.
5. In App Store Connect → Users and Access → Integrations → App Store Connect
   API, create a team API key with suitable access (Codemagic recommends App
   Manager). Download its `.p8` file and record the Key ID and Issuer ID.
   Keep the private file in Codemagic, outside this repository and chat.

## One-time Codemagic setup

1. Open Team settings → Team integrations → Developer Portal / Manage keys.
   Add the API key, naming the integration **`codemagic`**. Enter its Issuer ID,
   Key ID and upload its `.p8` file. An existing integration can be reused by
   changing `integrations.app_store_connect` in `codemagic.yaml` to its name.
2. In Team settings → codemagic.yaml settings → Code signing identities, add
   an **Apple Distribution certificate with its private key** (`.p12` and its
   password) and an **App Store provisioning profile** for
   `com.ishaqfishingtrip.appname`. You can fetch the profile through the connected Apple
   integration. The profile must include the same certificate and Team ID.
   Development and Ad Hoc profiles are not the TestFlight profile type.
3. In this Codemagic app's Environment variables, create the group
   **`ios_testflight`**. Add **`APPLE_TEAM_ID`** with your 10-character Team ID.
   The API key stays in the integration; do not paste it into a source file.
4. The workflow uses `com.ishaqfishingtrip.appname` in **two** places:
   `environment.ios_signing.bundle_identifier` and `environment.vars.BUNDLE_ID`.
   If using another registered ID, change both to match Apple.

## Start the test build

1. Commit and push these changes to the repository connected to Codemagic.
2. In Codemagic, select that branch and **Start new build**.
3. Choose **Ishaq's Fishing Trip - iOS TestFlight** (`ios-testflight`).
4. Download the IPA from build artifacts if needed. Successful publishing uploads
   it to the existing app record in App Store Connect.
5. In App Store Connect → your app → TestFlight, wait for Apple processing.
   Complete any export-compliance questions, create/select an internal testing
   group, add your eligible App Store Connect user, and select the build.
6. Install Apple's TestFlight app on the iPhone, accept the testing invitation,
   and install the game from it.

Internal testing is the simplest first test. External testers can be added later;
external distribution may require Apple's beta review and beta contact details.
The workflow deliberately leaves `submit_to_testflight: false`: in Codemagic this
flag controls submission to **beta review**, not whether the IPA is uploaded.
App Store review submission is also disabled.

## Versions and device settings

- App version: `0.1.0`, in the iOS export preset.
- Build number: automatically `PROJECT_BUILD_NUMBER + 1` in Codemagic.
- If a higher build already exists on Apple, add `IOS_BUILD_NUMBER` to the
  `ios_testflight` variable group with a higher unused integer for that run.
  Remove the override afterward when the Codemagic counter has caught up, or
  keep increasing it explicitly. Every upload must use a new build number.
- Native arm64 iPhone build, iOS 14+, landscape from the game project settings.
- An original opaque fish icon is generated at 1024px before export. Godot
  generates the required iPhone icon sizes from it.
- Godot only exports the Xcode project; Codemagic applies signing and archives it.
  Godot export alone does not produce the signed IPA in this workflow.
- No extra Blender, mesh optimisation or Python image packages are needed on CI.

## Common failures

- **Integration/group not found:** use the exact `codemagic` and `ios_testflight`
  names above, or update the workflow to your existing names.
- **No matching profiles/certificates:** use `app_store` distribution and ensure
  bundle ID, Team ID and certificate match the provisioning profile. The
  certificate needs its private key, not just an Apple `.cer` download.
- **App record not found:** create the app in App Store Connect first with the
  same Bundle ID used to build it.
- **Build number already used:** choose a higher unused `IOS_BUILD_NUMBER`.
- **Uploaded but unavailable:** inspect Apple's processing messages and complete
  TestFlight/export-compliance setup. A successful Codemagic build alone does
  not guarantee Apple has finished processing or enabled a testing group.

Sources checked 2026-10-23:
- https://docs.codemagic.io/yaml-code-signing/signing-ios/
- https://docs.codemagic.io/yaml-publishing/app-store-connect/
- https://docs.codemagic.io/knowledge-codemagic/build-versioning/
- https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_ios.html
- https://developer.apple.com/get-started/
- https://developer.apple.com/testflight/
