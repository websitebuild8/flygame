# Reference-game asset adaptations

The user supplied `/home/ahusan/ft/` and stated that the app owner approved reuse.
This is permission-based material, not an asset pack advertised under an open
license. Keep that distinction in distribution records. Original source APKs,
bundles and cached game data were read in place and were not modified or copied
wholesale into the project.

## Included now

- The original yellowfin tuna mesh, colour/normal/metallic maps, 42 weighted
  joints and five source clips are converted into `yellowfin.glb`.
- The live Yellowfin tuna uses this model. Its fight state switches between
  recovered swimming and pulling clips; the catch display uses the show clip.
  Source jump and hurt clips are accessible in the showcase. The existing fish
  fight calculation, weight/value roll, economy and species pool are unchanged.
- Canonical -Z facing, mouth attachment, physical size and conservative animated
  bounds are adapted for our line routing and above-water landing behavior.
  Camera upward tracking is allowed during a lift; casting camera pitch ends
  once a bite is announced. This avoids losing the lifted fish above the frame.
- The yellowfin's journal portrait is regenerated from the new model.
- The original Deep Blue rod/reel skins and five equipment clips are converted
  into `deep_blue.glb`, available under **Settings → Fishing showcase**. Choose
  casting, waiting, pulling, reeling or display; drag to orbit, wheel to zoom,
  and use Reel close-up to examine the reel. The 3D preview is disabled and
  its model freed when closed. Opening it pauses the fishing game.

The Deep Blue outfit is now **live as the free starter rod and reel**. Saved IDs
`island_rod` and `island_reel`, ownership, stats and prices are preserved; only their
display names and visuals change. The separate showcase retains the original
source animations. Other spinning and overhead outfits remain compatible.
Existing source assets remain present. There are now seven catchable species;
this stage does not add an underwater mode or a new species/lure pack.

## Conversion method

`tools/convert_reference_assets.py` uses the existing UnityPy/Pillow environment:

```
PYTHONDONTWRITEBYTECODE=1 /home/ahusan/ft/venv/bin/python tools/convert_reference_assets.py
```

The exporter is restricted to selected bundles/meshes/clips. It resolves Unity
animation bindings from CRC32 hierarchy paths, decodes streamed polynomial,
dense and constant scalar channels, samples at 30 Hz and converts Unity Euler
ZXY/quaternion rotations to glTF quaternion tracks with sign continuity. It
retains inverse binds and normalized vertex weights, including the reel's
implicit single-joint weights. Irrelevant rig branches are excluded, missing
bindings/weight layouts fail rather than creating silent placeholder motion.

Coordinates are reflected on Z with winding reversal, UV V coordinates are
flipped, texture images are capped at 1024 pixels, and Unity metallic/smoothness
channels are repacked into glTF metallic/roughness. Materials use Godot PBR;
Unity shaders and game executable code were not copied.

Conversion format references:
[Khronos glTF 2.0](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html)
and [AssetStudio's Unity AnimationClip layout](https://github.com/Perfare/AssetStudio/blob/master/AssetStudio/Classes/AnimationClip.cs).

Each GLB has a `.source.json` record with the exact source bundle, SHA-256,
converted output hash, geometry/texture counts and selected animation tracks.
The two GLBs total about 3.3 MiB of source data, rather than copying the roughly
540 MB of original APKs. This is not a measured APK-size delta. The earlier
assets have not been deleted. Godot import/pack compression changes export size.
The tuna is 4,702 triangles; the outfit is 16,198 triangles in two renderers.

## Validation and limits

`tests/reference_asset_checks.gd` validates surviving skins and clips, actual
bone motion, independent playback, finite sampled poses, conservative fish
landing bounds, equipment triangle budget, pause/close behavior and catch
weight/value preservation. Existing fish, fishing gameplay, water landing,
cosmetic, haptic, progression and UI suites cover integration.

Visual previews were rendered in Godot Compatibility on the laptop. The swim,
equipment display, reel retrieval and catch display were inspected. Test cases
cover seven species landing on four boats and full tail clearance. No actual
Nord N20 SE performance measurement or original-game runtime trace was made.
Skeleton and animation costs should be checked on a release mobile build.
CPU skin bounds are used for conversion QA and static preview framing only;
they are not recalculated per gameplay frame. Further species and equipment imports remain separate migration stages.

## Live Deep Blue adaptation

The live version does not play the source whole-outfit animation against our
hand IK. `bake_deep_blue.gd` samples the straight rod and the reel’s waiting pose,
removes source camera/arm transforms and exports geometry in the stationary
housing frame. `prepare_deep_blue_live.py` separates actual connected components
and places them in our canonical rod/reel coordinates; `save_deep_blue_meshes.gd`
creates six compressed ArrayMeshes and `deep_blue_data.gd`.

The meshes total about 320 KiB on disk and reuse the existing converted texture
materials. There are no new texture copies, live equipment skeletons or equipment
AnimationPlayers. Source GLB animation remains available only in the showcase.
The existing rod shader bends the new mesh; its original normal/colour maps and
custom cosmetic finishes are supported. Original metal seat collars replace the
extra primitive collars on this rod.

Eight ceramic-hole centres are measured from the welded guide-ring components,
including the final tip. Their metadata drives the same CPU deformation as the
vertex shader. The route is spool lip → moving bail roller → eight guides →
lure/fish. The spool lip moves with the spool, and landing lift uses the new
actual tip. Cached guide coordinates avoid rebuilding the guide array each tick.

The reversible crank is adapted to right-hand retrieve with its axle cap seated
inside the housing side cover. The housing stays fixed. The bail rotates five
turns per crank revolution; the separated spool oscillates along the shaft and
does not rotate. A separate knob counter-rotates so the gloved hand can keep a
natural wrist orientation while following its orbit. Its grip offset is matched
to the smaller original knob. Spool stroke is in equipment-local units so the
boat/game world scale does not accidentally amplify it.

`tests/deep_blue_live_checks.gd` covers the seated mounting foot, right-side
forward winding, 5:1 bail ratio, stationary housing, nonrotating oscillating
spool, free knob and hand target, eight open guide centres and bending alignment,
existing cosmetic finishes, alternate spinning/overhead compatibility, and the
absence of extra live animation rigs. Gear/line tests now inspect each model’s
actual guide count and physical bail radius rather than assuming one shared
model size.

Live verification captures: `docs/previews/deep-blue-live-ready.png`,
`deep-blue-live-reeling.png` and `deep-blue-live-shop.png`. These documentation
captures are excluded from game exports.

## Rusty jobfish migration

`rusty_jobfish.glb` is now live as the sixth species, appended after the existing
five catalogue entries so saved species/spot indices retain their meanings.
Source mesh `F_rustyjobfish` comes from the selected pack102 bundle. Its source
record contains both SHA-256 hashes and the original/converted texture counts.
The model is 2,378 vertices / 3,758 triangles, with 42 weighted joints, five
recovered clips and 512-pixel colour, normal and metallic maps. The GLB is
1,684,976 bytes; this is a source-file size, not a measured APK delta.

Rebuild only this selection with:

```
PYTHONDONTWRITEBYTECODE=1 /home/ahusan/ft/venv/bin/python tools/convert_reference_assets.py --asset rusty_jobfish
```

`reference_fish.gd` shares animation/visibility behavior without loading a
second species model. The tuna frame remains unchanged; the jobfish is rotated
to canonical -Z and scaled by 2.2. Its conservative envelope includes densely
sampled swim, pulling and show poses, including the larger sideways tail flex.
Only the active actor animates; no frame-by-frame CPU skin-bound measurement is
added to gameplay. The source clips can also be inspected in Fishing showcase.

The species occurs in the Maldives and is listed as **Rankarumas** in the
[Marine Research Centre reef-fishery review](https://mrc.gov.mv/assets/Uploads/May-2008-Review-of-the-Reef-Fishery-of-Maldives.pdf).
The [MRC fish guide](https://www.mrc.gov.mv/assets/Uploads/fishes-of-the-maldives.pdf)
identifies *Aphareus rutilans* as rusty jobfish, with reef/rocky/sandy habitat at
50 m and deeper. The current game's depth choices are simplified fishing
presets. Catch weights (0.8–6 kg), MVR prices, fight profile, lure/weather/time
preferences and compressed-map fishing locations are authored game balance,
not survey data or current market prices.

It is catchable at Kelaa Outer Reef, Filladhoo Dropoff and Dhidhdhoo Reef. It uses
steady deep pulls without billfish-style leaps. Existing variable individual
weights/prices, landing, market inventory, journal records/mastery and weekly
species counting include it. The journal uses a rendered 2D portrait; its
species-discovery denominator now derives from the catalogue instead of a
hardcoded five. Existing rod/reel, boat and island behavior is preserved.

`jobfish_checks.gd` covers animated bounds, independent playback, distribution,
individual weight/value variation, preferred setup, distinct fight and saved
records. Fish, water/landing (all seven species × four boats), UI, progression,
conditions, ocean, reference assets, live Deep Blue, fishing and market smoke
suites also pass. Physical Nord N20 SE performance remains unmeasured.

Visual captures: `docs/previews/jobfish-catch.png` and
`docs/previews/jobfish-journal.png` (excluded from game exports).

## Giant grouper and reef challenge migration

`giant_grouper.glb` is live as the seventh species. It is appended to the catalogue,
retaining all previous species/spot IDs and saves. The selected pack102 source
mesh is `F_giantgrouper`, with 3,414 vertices, 5,582 triangles, 32 weighted joints
and five original clips. The source artist uses materials/textures named
`F_duskygrouper`; this is representative grouper artwork, not a verified species
scan. No second renderer belongs to this actor: the similarly generic
`polySurface35` renderer belongs to a separate `F_rainbowrunner` animator.

The [MRC grouper identification guide](https://mrc.gov.mv/assets/Uploads/Grouper-and-Reef-Fish-Guide-Eng.pdf)
lists *Epinephelus lanceolatus*, giant grouper, as **Mudu faana**. The compressed
map locations, 3–24 kg catch range, fictional MVR values and heavy non-leaping
fight behavior are game balance rather than local population or market data.
It can be caught at Filladhoo Dropoff, Baarah Drift and Dhidhdhoo Reef.

The converter now accepts `--texture-size 256|512|1024`. Grouper defaults to
512 pixels per map, reducing its GLB from 4,234,708 to 1,797,508 bytes (about
58% smaller). Original source files remain untouched. This is a source-model
comparison, not an APK-size or measured mobile-FPS claim. Rebuild with:

```
PYTHONDONTWRITEBYTECODE=1 /home/ahusan/ft/venv/bin/python tools/convert_reference_assets.py --asset giant_grouper
```

Canonical frame scale is 1.65 with offset `(0, .09, -.14)`. A conservative
symmetric envelope is validated against 61 samples of each live swim, pulling
and display clip. This keeps mouth alignment, tail clearance and catch framing
compatible with every existing boat. The portrait is rendered once as a small
2D image; shared playback logic loads only the selected species model.

Two optional permanent bonus challenges appear in **Angler’s Club → Spots**:

- **Rankarumas specialist**: Kelaa Outer Reef, level 2, one rusty jobfish ≥2 kg.
  Silver at 3.5 kg, gold at 5 kg; first-clear 110 base XP and MVR 120.
- **Drop-off heavyweight**: Filladhoo Dropoff, level 4 plus its existing spot
  unlock, one giant grouper ≥8 kg. Silver at 14 kg, gold at 20 kg; first-clear
  140 base XP and MVR 180.

They use existing higher-star XP, saved attempts/medals, single active attempt
and exact-once first-clear rewards. Replay rules and all ten earlier challenges
are retained, giving twelve challenges overall. The bonus buttons open their
own details. Fishing showcase uses a compact model dropdown so more species do
not extend the sidebar beyond small landscape screens.

`grouper_checks.gd` validates animation bounds, independent clips, catch ranges,
distribution, challenge gates/filtering/stars/save/claims and visible button
routing. The market integration test now stages matching species models and
individual data, then checks actual counter previews and exact MVR payments
for skipjack, sailfish, mahi-mahi, jobfish and grouper. Texture tests check the
new 512-pixel cap. Fifteen relevant suites passed, including all seven species
landing on four boats, challenges, scrolling, progression and existing tackle.

The final visual check exposed a clipped head despite the old centre-point
framing assertion passing. Landing now centres the render eye on the hanging
fish, independently of the camera-attached rod, then fits its cached envelope
with a bounded field of view. This avoids an upward camera/rod feedback loop.
It uses eight cached-box corners, not per-frame CPU skinning. The render offset
resets on landing and outside the lift. Water/landing tests now require the
whole envelope, rather than only the actor origin, to fit with screen padding
for all seven species on all four boats.

Final captures: `docs/previews/grouper-hanging.png`, `grouper-catch.png`,
`grouper-journal.png`, `grouper-challenge.png` and `grouper-showcase.png`.
Documentation images are excluded from game exports.

## Camera and desktop clarity correction after player feedback

The render-eye / up-to-105° landing reframing described above was reverted. It
changed perspective too far, hid the hands and weakened the established close
camera feel. Landing again retains a zero render-eye offset and the existing
70° fight lens, strike kick, tension sway, power burst and fish tracking. The
water/landing test now guards that perspective along with mouth attachment,
centre visibility and dry tails; it no longer forces the full conservative
bounding box into view by changing the lens. Full-envelope framing captures
from the earlier stage are historical and do not represent the current camera.

The actual laptop save had High graphics, shadows and full motion enabled.
Auto-resolution was enabled; its runtime scale is not saved, so the actual
scale at the time of the report could not be recovered. The previous governor
could reduce High to 45% resolution. Desktop auto-resolution now respects floors
of 85% on High and 65% on Medium; Low and the existing mobile 45% floor remain
available. No ocean, island lighting, global renderer or fish-fight formula was
changed. `camera_feel_checks.gd` covers clarity floors and the retained tracking,
rod tension, reel rotation, strike kick, power zoom and close landing lens.

Restored close-view verification: `docs/previews/restored-fishing-camera.png`.
