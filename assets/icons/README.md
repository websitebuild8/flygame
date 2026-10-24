# iOS app icon

Original artwork generated with the built-in imagegen tool on 2026-10-24 for Ishaq’s Fishing Trip. Prepared as an opaque RGB 1024×1024 PNG, square with full-bleed edges. Apple applies the corner mask.

Prompt: “A polished realistic 3D game icon showing an anatomically credible yellowfin tuna leaping through turquoise ocean spray, a small Maldivian palm island and golden sunrise behind it; clear silhouette, blue/silver fish with yellow fins; square opaque full-bleed scene, no text, logos, borders or rounded corners.”

`tools/prepare-ios.gd` validates this file and writes `build/ios-icon.png`. Both iOS export icon fields use that build file; Godot creates the smaller icon sizes. Commit this asset and the preparation script before starting Codemagic. The icon is delivered to App Store Connect inside the uploaded build.

Android uses the same 1024px artwork for its launcher and adaptive foreground. The adaptive background is a solid deep teal SVG. Godot generates the Android density variants during export; device launchers apply their own icon shape. Push both assets and export_presets.cfg, then run the Android test APK workflow.
