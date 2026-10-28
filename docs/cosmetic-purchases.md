# Equipment finishes and premium collection

## Implemented

At an inner harbour, open Tackle or Workshop and tap **Customise**. Select an
owned rod, reel or boat, choose a finish and tap **Use free colour**. Finishes are
saved per item and appear in shop previews and on equipped equipment. Original
restores authored materials. Pinch and drag continue to operate the 3D preview.

Free starter finishes: Original, Lagoon blue and Seafoam.
Additional earned finishes unlock through XP levels: Reef bronze (5), Atoll silver
(10) and Ocean gold (15). They are separate from the paid collection.
Premium previews: Sunset coral, Pearl edition and Midnight gold.
These premium looks are intended for **one permanent Premium Finish Collection**
covering rods, reels and boats. The user selected a **150 MVR target price**.
No stat boost, MVR charge or gameplay unlock is attached to a cosmetic selection.

Materials are overridden per instance, not edited on shared meshes. Boat paint is
restricted to a lower side band and leaves imported glass/registration/fire-safety
materials alone; normal maps and alpha cutouts are retained. Rod cosmetics use the
existing bending shader, with the grip region protected. No mesh, rig, reel pivot,
line routing or physics parameter is changed. The feature adds scripts and shaders,
not new downloaded 3D assets or textures.

## Real-money status: NOT IMPLEMENTED OR ENABLED

The current build provides free colours and clearly labelled premium previews.
It does not contain a native billing SDK, product lookup, checkout, verification,
restore flow, purchase acknowledgement or refund handling. There is no simulated
purchase and no paid entitlement that can be granted through the ordinary trip
save. A premium finish cannot be equipped in this build. Changing the example
configuration's enabled flag does not create working payments.

`config/cosmetic-store.example.json` records the agreed pack/target price and blank
store product identifiers. It is a planning file, not a live billing configuration.
It contains no credentials. The normal trip file saves only usable free choices.

## Remaining work for paid launch

1. In App Store Connect, configure the paid agreement, tax/banking, and create a
   non-consumable Premium Finish Collection for com.ishaqfishingtrip.appname.
   In Play Console, configure the payments profile and matching non-consumable
   one-time product. Store product IDs and country availability must be confirmed.
2. Choose supported storefront price points approximating the target value.
   Use native store-returned localized prices/currencies in the UI. Never label an
   actual USD store charge as MVR. Apple lists Maldives in USD; the requested MVR
   amount is a business target, not a forced checkout currency. Confirm Google
   country/currency and merchant eligibility in the actual account.
3. Select compatible Godot 4.5.1 native iOS/Android billing plugins; integrate and
   pin their versions in the Codemagic export workflow. No billing library has
   been added to the current build.
4. Implement product lookup, explicit purchase confirmation, pending/cancelled/
   failed states, authenticated entitlement verification and Google acknowledgement.
   Grant the permanent pack only on a verified, completed transaction. Keep store
   signing keys/service account credentials server-side.
5. Add Restore Purchases, verified offline entitlement caching and refund/revocation
   handling. Reinstall/device restoration must use store ownership rather than
   ordinary trip-save flags. Do not promise cross-store ownership without accounts.
6. Test Apple sandbox/TestFlight and Play internal testing, including interrupted
   purchases, repeated callbacks, reinstall, restore, refunds and offline use.
   Only then replace Coming soon with the localized store checkout action.

References checked during implementation:
- Godot iOS plugins: https://docs.godotengine.org/en/stable/tutorials/platform/ios/ios_plugin.html
- Godot Android purchases: https://docs.godotengine.org/en/latest/tutorials/platform/android/android_in_app_purchases.html
- Apple purchases/restoration: https://developer.apple.com/documentation/storekit/offering-completing-and-restoring-in-app-purchases/
- Google verification: https://developer.android.com/google/play/billing/security
- Apple country/currency listing: https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/auto-renewable-subscription-price-increase-thresholds
- Google distribution/currencies: https://support.google.com/googleplay/android-developer/answer/10532353

## Verification

Cosmetic checks cover all four boat hulls, free per-item selections, save/reload,
original-material restoration, paid-preview blocking, ordinary-save tamper rejection,
transparent glass and unchanged game balance. Existing gear, tackle, line/helm,
boat, menu, gesture/haptic and trip checks exercise integration. Rendering previews
checks the UI and materials. Store billing and real-device frame rate are not tested
because checkout has not been integrated and the phone is not connected here.

### Boat ownership milestones

Captain’s teal (10 lifetime catches) and Ocean racer (30) are free, boat-only
liveries in Customise. They require no purchase and provide no gameplay boost.
They accompany the named-vessel and captain-badge screen in Goals → My boat.
