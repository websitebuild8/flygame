# Reference fishing game: local artifact inspection

This records the initial inspection before any migration. See
[conversion notes](reference-asset-conversion.md) for subsequent gameplay changes.

User-selected source: `/home/ahusan/ft/`. The user states the app owner has
approved reuse. Source files were inspected in place and not modified.

## Identity and original files

The binary Android manifest of `base.apk` declares package `com.arkgame.ft`,
version `0.59.1`, version code `591`. SHA-256:
`c1b47a238501e3168ada67d0404a8cfc1c6a324dac9861068328985e47e8ff9b`.

Original packages remain:
- `base.apk`: 123,691,771 bytes.
- `split_UnityDataAssetPack.apk`: 366,820,251 bytes.
- `split_config.arm64_v8a.apk`: 49,158,283 bytes.

The directory also contains extracted `base`, `split_UnityDataAssetPack` and
`split_config.arm64_v8a` trees, `gamedata`, and earlier `out/tex` and `out/audio`
exports. Unity serialization, `libunity.so`, `libil2cpp.so` and global metadata
establish a Unity/IL2CPP build. This is distinct from the previously supplied
Uptodown application APK.

## Confirmed packaged resources

Using the existing UnityPy installation read-only, 15 selected bundles were
parsed from the extracted asset pack. Across those bundles, the inventory found
66 Mesh objects, 154 Texture2D objects, 388 AnimationClip objects and 48
SkinnedMeshRenderer objects. These are object counts, not unique species or
unique animations, and do not describe every bundle in the game.

Mesh names include yellowfin tuna, rock cod, red snapper, lionfish, rabbitfish,
leatherjacket, parrotfish, giant grouper, rusty jobfish and other fish. Some named
species are outside our Maldivian theme and should not be imported indiscriminately.

The rod bundle includes `Rod_deepblue`, `Reel_deepblue`, `Rod_abyss`, `Reel_abyss`,
`Rod_elemental`, `Reel_elemental` and line meshes. Repeated names can identify
different objects; full material/rig associations still require inspection.

Fish animation names include Swim, Idle, Struggle, Pulling, Jump, Dash, Hurt,
Click and Show variants. Environment bundles include camera-related objects,
lighting, water-related effects and animated seagulls. Names and serialized
object types establish resource presence, not runtime behavior.

Exact bundle paths, per-type counts and sampled names are retained in
`reference-game-asset-inventory.json`.

## REA evidence and limits

REA opened the actual base APK and inventoried its archive entries.
Summary evidence: `ev_9f9b3e0ba6cde5f2293297a5f526ac81e1f7a852f4bc16ef360c31665e0793b0`.
Inventory evidence: `ev_e83b481609074e6d2bb8545237c7b40d1ac2de60ff63d1e64daeaf5fd961251e`.
The manifest identity was independently decoded from the packaged binary XML.

The APK was not launched. No gameplay timing, camera behavior, underwater
experience or fish AI has yet been verified at runtime. REA Android Java code
inspection requires a currently unconfigured JADX provider; Java inspection
alone would not recover the Unity IL2CPP game logic. Unity shaders, skeletons,
material links and animation conversion to Godot remain untested. No source
assets were copied into gameplay, and no boats, islands or mechanics were changed.

## Suggested next implementation pass

Convert one suitable fish with textures, skeleton and swim/struggle animations
into a separate Godot preview first. Compare its size and runtime cost with the
existing fish. Then validate one rod/reel assembly and animation mapping before
replacing working gameplay assets. Keep source packages outside mobile exports;
convert only selected assets. Rebuild water effects in Godot after inspecting
actual resource data and reference footage, rather than assuming Unity shaders
can be used directly.
