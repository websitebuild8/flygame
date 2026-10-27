# Ishaq's Fishing Trip

An offline landscape Godot 4.5.1 / GDScript fishing prototype. Most geometry,
shaders and cloud textures are original procedural work; fish use imported
textured tuna and giant trevally models (see credits below). Audio combines free CC0 real outboard,
reel, splash and wave recordings (see docs/audio-credits.md). No Blender or purchased
assets are required to run this version.

## Launch and controls

Import `project.godot`, press F5 and select Set sail. The game is 1280 × 720
landscape, with a smaller desktop preview window and mobile safe-area margins.

- External camera: drag the left wheel and slide the right F/N/R lever.
- The throttle stays set. Neutral coasts; changing direction waits for the boat
  to slow. Reverse is limited below forward speed.
- POV button: switch to a seated first-person helm. Drag the actual visible wheel
  and the throttle's vertical F/N/R region. External returns to the chase view.
- Wheel, physical helm, throttle and outboard motors animate together. Twin-engine
  launch motors and throttle handles are linked. Hull lean is a separate motion.
- Keyboard: A/D or arrows steer, W/S adjust throttle, N selects neutral, M opens
  the chart, Space casts/reels, Escape opens settings or closes the chart.
- The pause/settings sheet includes sound, vibration, engine upgrades, a prototype
  Return to home dock shortcut, and Next time of day for previewing lighting.

## Chart and navigation

Open Chart or press M. Tap a fishing marker or open water to set a waypoint.
The chart shows your boat and heading, islands, home dock/shops, unlocked and
locked fishing spots, selected waypoint and planned route. Routes use a grid
and clearance around islands, with a line-of-sight smoothing pass. A route card
shows remaining distance and steering guidance. A gold beacon marks the target
in the world. You still drive manually; this is guidance, not autopilot.

The chart is explicitly **fictional prototype geography**, not real Maldives
bathymetry or a real navigation chart. Seven fishing spots surround five islands:
Lagoon Buoy, Western Reef, Palm Channel, Eastern Dropoff, Bluewater Bank, South
Drift and Sunset Shoal. Some spots require catch milestones. Eastern waters
open after three catches.

## Fishing

Approach an unlocked buoy within 14 metres, select neutral and slow down, then
Start fishing. Cast (or Drop jig for overhead equipment), wait for the bite,
and hold Reel In / Space. Release to lower tension.

The hooked fish actually swims, turns, runs and jumps. Its position drives the
line endpoint; water crossings and runs trigger spray and ripple effects. The
rod follows pull direction with a spring-smoothed curve, its segments bend
continuously, and the reel mechanism animates during retrieval. The fishing
view shows rod/reel only: there is no visible hand or arm.

Store the catch in the icebox. Only the imported textured yellowfin tuna and
giant trevally are currently catchable at all seven spots. Other species are
retired from gameplay for now. Catch values and fight tuning are fictional game
data. Currency is displayed as MVR throughout the HUD, shops and market; it is
an earned in-game balance. Existing saved balances keep their numeric value.

## Market, equipment and boats

Dock at home in neutral. Market, Tackle and Workshop appear on the controls.

- Market: first-person counter and customer queue. Hand over one fish, then
  collect payment. The customer advances and another buyer approaches. Unpaid
  sales persist. The customer panel shows the fish, weight and MVR due.
- Tackle: spinning and overhead reels, compatible rods and braid. Manufacturer
  names identify Shimano/PENN/PowerPro references, with original approximate
  models. Performance multipliers and MVR prices are fictional game balance.
- Preview: a lit 3D turntable, drag rotation and +/− zoom. Tap item names to select.
- Workshop: engine stages, performance propeller and icebox upgrade (+14 fish).
- Boats tab: buy and switch boats. Each changes model, storage, handling, speed,
  physical helm and touch wheel/throttle design. Ownership/loadouts save locally.

| Boat | Catch milestone | MVR | Base speed | Storage | Helm |
| --- | ---: | ---: | ---: | ---: | --- |
| Island Dinghy | 0 | Free starter | 12.5 m/s | 10 | Classic mint, 3 spokes |
| Reef Skiff | 3 | 600 | 18 m/s | 14 | White/blue sport, 5 spokes |
| Atoll Runner | 8 | 1,400 | 24 m/s | 18 | Carbon/amber D-wheel, T-top |
| Ocean Launch | 15 | 2,800 | 30 m/s | 24 | Wood/brass 6-spoke, twin controls |

There are no real-money purchases. Owned equipment can be equipped without
paying twice. Pairing rules automatically select an owned compatible rod/reel.
Old saves retain catches and balances and receive the starter boat by default.

## Day and night

A full in-game day takes 20 minutes of active play. The clock starts at 08:00,
rolls through midnight and saves with progress. Sun/sky/water colour, ambient
light, moon/stars, cloud tint, shadows and dock lights change with time. Menus,
the chart and backgrounding pause the active clock. This is game time, not the
phone's system time. Next time of day in settings cycles noon/sunset/night/dawn.

## Limits and validation

This is stylised procedural prototype art, not the photographic realism of the
references. Characters, buildings, water and tackle need further art refinement.
Boat motion, rod/line behaviour and fish runs approximate reality for gameplay;
full hydrodynamics, elastic-line simulation and depth-based jigging are future
work. Real Maldives GIS data has not been imported. Mobile frame rate, physical
touch target sizing, safe areas and vibration still need device testing.

After import, the four headless checks are:

- `godot --headless --path . --script res://tests/trip_smoke.gd`
- `godot --headless --path . --script res://tests/helm_checks.gd`
- `godot --headless --path . --script res://tests/gear_checks.gd`
- `godot --headless --path . --script res://tests/ocean_checks.gd`

They cover fishing/market transactions and save migration; boat throttle,
inertia, steering, touch ownership and audio; purchases/loadouts; map routes,
land avoidance, locks, boats, POV and linked motors; fish movement/jumps/splashes;
rod/line feedback; day/night rollover and persistence. They use separate saves.

Codemagic includes validation and an Android test APK workflow. Store releases
and iOS still need signing setup: see `docs/mobile-builds.md`. Research references are in
`docs/design-research.md`; keep credentials out of Git.


### Kelaa setting, landing and weather

Home harbour is HA. Kelaa; chart islands include Filladhoo, Vashafaru,
Dhidhdhoo and Baarah. Names follow the Maldives Bureau of Statistics Haa Alif
map: https://statisticsmaldives.gov.mv/haa-alif-atoll-map/ . Coastlines, relative
positions, fishing spot labels and distances remain a compact gameplay layout,
not geographic survey data or a navigational chart.

Fifteen species now include green jobfish, humpback snapper, peacock hind,
marble grouper, great barracuda and kawakawa. Species references:
https://www.mrc.gov.mv/assets/Uploads/May-2008-Review-of-the-Reef-Fishery-of-Maldives.pdf .
Sizes, value, distribution and fighting difficulty are game balancing values.

The final retrieve raises the rod while its tip stays bent and lifts the fish
beside the bow. The right-side **Put fish on boat** button becomes available
before the progress bar is full. Tap it to bring the catch aboard; it does not
automatically land. The whole rod and reel also move with retrieval and load. Large catches currently share this
simplified landing animation; landing nets and gaff handling are not simulated.

Sunny, cloudy, rainy and rough weather transition every 150 seconds, independently
of the 20-minute day/night cycle. Pause → Change weather cycles conditions for
preview (allow several seconds for the blend). Clouds, rain, fog, sea ripples,
whitecaps and boat bob respond to weather. Rain is hidden indoors. Weather is
simulated rather than downloaded live.


### Engine power and revised helm

The power button above the throttle cuts the engine while preserving the lever
and gear selection. The boat coasts down. At low speed, either neutral or engine
off allows fishing, market and shop actions. To restart, put the lever in neutral.
POV uses a closer camera and larger physical wheel, with touch targeting scaled
to its visible size. Boat hulls are teal, blue, coral-red and gold; rods and reels
use model-specific finishes, thread wraps and visible spool windings.

The HUD uses translucent buttons, frosted background panels and soft borders.
The glass shader uses a blurred screen sample; phone performance still needs
on-device testing. It is a custom glass-inspired style.


### Fish art and species references

Active fish use the imported models described below. The original procedural
species remain as retired source code for possible future work and are not
spawned by fishing spots or displayed at the market. Legacy catches retain their
sale value, but unsupported species do not show a substitute fish on the counter.

Species references:
- Maldives Marine Research Centre reef fish review (local species context): https://www.mrc.gov.mv/assets/Uploads/May-2008-Review-of-the-Reef-Fishery-of-Maldives.pdf
- Yellowfin tuna: https://fishesofaustralia.net.au/home/species/731
- Giant trevally: https://fishesofaustralia.net.au/home/species/4268
- Bluefin trevally: https://fishesofaustralia.net.au/home/species/1652
- Marble grouper: https://fishesofaustralia.net.au/Home/species/4670
- Mahi-mahi: https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/dolphinfish/
- Great barracuda: https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/great-barracuda/


### Imported textured fish

Yellowfin tuna now uses **Tuna Fish by GoldenZtuff**, downloaded from
https://www.fab.com/listings/6b90bbe2-3031-4b36-93ad-90f1cb2d01f5 under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). The asset is an artistic
tuna model used as a yellowfin representation, not a verified biological scan.
Only this tuna and the imported giant trevally are currently enabled.

The model retains its rigged Swim animation for the fight, catch display and
market. Mesh and material resources are shared; each fish owns its animation
playback. Body textures are reduced from 4096px to 1024px and eyes to 512px,
reducing the GLB from 56.7 MiB to about 5.6 MiB. `tools/prepare_tuna.py` reproduces
that conversion from the original download with Pillow; it is not needed to run
the game or build on Codemagic. The full original stays outside the repository.

Creator/source/license and changes are recorded in
`assets/models/fish/LICENSE.txt` and `tuna-source.json`, and displayed in the
scrollable pause menu. Desktop appearance and regression checks have been run;
Android/iPhone performance still needs actual device testing.

Giant trevally uses the **Caranx ignobilis scan by ffish.asia / floraZia.com**,
released under CC0. See `assets/models/fish/trevally-source.json` for its source
and conversion details. The separate label cube was removed and the fish was
aligned, centred and reduced from about 483k to 51,903 triangles. The smaller
10k trial visibly damaged texture seams, so the 4.5 MiB version retains more
geometry. Source 1k textures are preserved. A per-instance shader adds body and
tail movement, with stronger movement during a fight. It does not use a full
skeletal rig. Device performance still needs checking. Build-time conversion
uses `tools/prepare_trevally.py` and `tools/simplify_fish.mjs`; Codemagic builds
use the prepared GLB directly and need no extra packages.

## iPhone TestFlight builds

Use the `ios-testflight` Codemagic workflow. It exports an iPhone Xcode project,
runs gameplay checks, applies App Store signing and uploads an IPA for internal
TestFlight testing. Apple membership, the app record and Codemagic signing
identities must be configured first. Follow [the setup guide](docs/testflight-codemagic.md).
The first signed cloud build has not yet been run against your Apple account.

## Free tackle and motor upgrades

The starter spinning reel now uses the free textured Ergin ERYILDIR model, and
its full rod appears in the starter rod shop preview. The live blank retains
fish-responsive bending. Boats now use Bora Özakaltun's textured outboard, with
steering pivots and separately animated propellers. Both are CC BY 4.0 assets,
credited in-game and in exported licence files. The POV throttle has a fixed
right-side touch panel so its full F/N/R range stays on-screen. See
[model sources, changes and further candidates](docs/free-model-upgrades.md).

### Additional imported catches

Skipjack tuna (ffish.asia, CC0), sailfish (RED SIDE, CC BY 4.0) and mahi-mahi (Randibu, CC BY 4.0) join yellowfin and giant trevally. All are available through fishing spots, hooked movement, catch display and MVR market sales. Skipjack uses its scan colours; the unpainted sailfish receives a procedural species-coloured skin. Mahi-mahi uses Randibu’s painted Coryphaena hippurus model. Sources and changes are recorded in assets/models/fish/*-source.json and *-LICENSE.txt and the in-game credits.

The earlier Sketchfab “Ryba mahi mahi” scan was rejected after visual inspection: it resembles a decorative ornament rather than the requested fish. It is not shipped or used.

### Real boat upgrades

The existing skiff and launch upgrades now use BoatUS Foundation’s Scout 17 Centre Console and Boston Whaler 285 Conquest models (CC BY 4.0), with detailed consoles/cabin, independent steering wheels, throttles, original outboards/props, and individual driving/fishing cameras. Existing purchases and saves keep their IDs and game stats. See [model sources and preparation](docs/real-boat-models.md).

Glacier Bay and Grady-White Freedom 325 are additional BoatUS Foundation CC BY 4.0 boat upgrades with original 3D cockpit hardware, twin outboards and per-boat helm skins. Unlock at 22/30 catches for MVR 4,200/6,000 respectively; ownership persists in saves. See [real boat models](docs/real-boat-models.md).

Fishing now includes timed hook strikes, crank-linked gloved hands, a curved tension gauge, swipe-up power reeling (R on keyboard), camera response and individually weighted/priced MVR catches. See [fishing reference adaptation](docs/fishing-gameplay-reference.md).

The fishing line runs from the spool/pickup through all four bent rod guides to the fish. POV helm hands grip the physical wheel and throttle on all four boats; POV steering retains its angle when released. `tests/line_helm_checks.gd` verifies the new line and hand-contact paths and runs in all Codemagic workflows.

Kelaa market now uses animated Quaternius customers, a Kenney register showing the sale total, authored gloved seller hands, and a two-sided MVR 100 specimen payment texture extracted from MMA's currency booklet. Asset sources and licences are in `assets/models/market/`; `tests/market_art_checks.gd` checks the updated scene and preserves exact MVR payment amounts.

Graphics settings in the pause menu offer Low/Medium/High (60/80/100% 3D resolution, native-resolution UI), independent shadows, and saved preferences. Phones default to Low with shadows off and a 30 FPS cap; Medium/High cap at 60. Water mesh detail, shadow distance and rain density follow quality. Source assets are preserved; imported boat/fish textures are capped at 768px (63 source textures affected, 43.8% fewer pixels). This reduces texture payload and memory, not a guaranteed APK-size percentage or device FPS. `tests/graphics_checks.gd` verifies presets and persistence.

Supplied outdoor ambience loops during driving/fishing and obeys Sound/muting and pause/background state. Three supplied retrieve loops and four splash impact variants use compressed Ogg assets in `assets/audio/supplied/` (original WAVs untouched; source mapping in `audio-source.json`). Playable boats are now Scout, Boston Whaler, Glacier Bay and Grady-White; Scout is free and removed Dinghy/Runner save selections migrate to it. Third-person controls show a larger unboxed wheel from the equipped boat's original mesh, updated only when steering changes. All boats share a 2D F/N/R throttle with ten power segments and a percentage. The icon-only circular engine button glows green while running and stays muted green when off. POV retains the physical cockpit. The hook cue uses a one-shot supplied reeling clip. Intro/pause panels fit inside screen margins with scrolling for long settings/credits. `tests/audio_helm_menu_checks.gd` covers this update.

Basic procedural upgrade reels were replaced with CC BY 4.0 imported assets: Sobrom's textured spinning reel (the source listing is titled Fishing Rod) and C. Yamahata's overhead level-wind mechanism, assembled with the existing Ergin ERYILDIR crank. The overhead assembly has opaque metal side plates, wound line, moving spool and traversing guide; these are generic adapted reels, not branded replicas. Shop names now describe those variants; saved item IDs and prices remain compatible. The existing authored rod and starter imported reel are retained. New spinning textures use mobile 768px VRAM compression. Attribution and changes are in `assets/models/tackle/free-tackle-source.json`; `tests/free_tackle_checks.gd` covers mounting, animated parts and line routing.

POV cockpit instruments are fitted onto the existing physical screen faces of all four hulls. Speed (knots), gear and engine power update at 10 Hz; neutral is green, rising forward/reverse power shifts through yellow/orange/red. Whaler, Glacier Bay and Grady-White use their second display for a live chart with boat heading, fishing spots and the active waypoint route. Duplicate POV throttle/speed overlays are hidden; drag the actual throttle knob to change power, while external view keeps the shared throttle. Twin-display POV hides its duplicate circular minimap; Chart remains available for waypoint selection. Spinning crank/bail retrieve direction was reversed, with overhead direction retained. `tests/cockpit_display_checks.gd` covers displays, input, colours, overlay switching and retrieve direction.

Market payments now display exact whole-MVR tender using 5/10/20/50/100/500/1000 notes and 1/2 coins with official MMA artwork. For example, 120 is 100+20; 234 is 100+100+20+10+2+2. Cached meshes and batched instances keep cash lightweight. Tender rebuilds only when the amount changes; collection animates the complete bundle and preserves exact game balances and pending-payment saves. Texture imports cap at 512px. `tests/market_cash_checks.gd` covers amount decomposition through MVR 5000, displayed instances, save restoration and collection.

Casting now starts with a ready pose and a visible, licensed 3D saltwater lure hanging from the tip. Tap Cast again for a backswing, forward release, gravity arc and splash on impact. Low graphics also reduces simulation/effect work and avoids glass blur; all assets remain available. See `docs/fishing-gameplay-reference.md` for the reference observations and device-testing limits. The casting regression suite is `tests/casting_checks.gd`.

HA. Kelaa now has its mapped curved coastline, roads, harbour and landmark positions, with a lightweight original village and palm groves. All charts/navigation share the same coastline. The island is compressed for gameplay; extra buildings are stylised rather than exact replicas. Source, licence and implementation notes are in `docs/kelaa-recreation.md`.

The home harbour is now enclosed, with a marked entrance used by both driving and chart routes. Boats have been resized against the island scenery; the home menu action plots a course to the inner berth. The four neighbouring islands also use mapped outlines and have more open sea between them. See `docs/kelaa-recreation.md` for scale, source and gameplay details.

Sailing now includes four camera modes, corrected physical throttle/hand motion, six lightweight traffic boats, swept boat/shore collisions and harbours with distinct markets on all five islands. Harbour locations follow the available OSM harbour, pier and marina references, adapted for gameplay. See `docs/sailing-expansion.md` for behaviour and verification.

The ocean now uses coastline-based shallow/deep colour ramps, free CC0 sand detail and quality-scaled shallow fish silhouettes. Boats share the rendered water height; landing fish hang by the mouth with dry tails. See [ocean and waterlines](docs/ocean-and-waterlines.md) for research, source licences and mobile limits.
