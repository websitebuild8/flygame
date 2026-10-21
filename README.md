# Ishaq's Fishing Trip

An offline landscape Godot 4.5.1 / GDScript fishing prototype. Geometry, shaders,
cloud textures are original procedural work. Audio combines original synthesized
engines with free CC0 reel, splash and wave recordings (see docs/audio-credits.md). No Blender or purchased
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

Store the catch in the icebox. Fish pools differ by spot. Nine varieties are
included: skipjack tuna, yellowfin tuna, giant trevally, dogtooth tuna, wahoo,
mahi-mahi, bluefin trevally, red bass and rainbow runner. Fish profiles, colours,
fins and markings differ. Catch values and fight tuning are fictional game data.

## Market, equipment and boats

Dock at home in neutral. Market, Tackle and Workshop appear on the controls.

- Market: first-person counter and customer queue. Hand over one fish, then
  collect payment. The customer advances and another buyer approaches. Unpaid
  sales persist. The customer panel shows the fish, weight and coins due.
- Tackle: spinning and overhead reels, compatible rods and braid. Manufacturer
  names identify Shimano/PENN/PowerPro references, with original approximate
  models. Performance multipliers and coin prices are fictional game balance.
- Preview: a lit 3D turntable, drag rotation and +/− zoom. Tap item names to select.
- Workshop: engine stages, performance propeller and icebox upgrade (+14 fish).
- Boats tab: buy and switch boats. Each changes model, storage, handling, speed,
  physical helm and touch wheel/throttle design. Ownership/loadouts save locally.

| Boat | Catch milestone | Game coins | Base speed | Storage | Helm |
| --- | ---: | ---: | ---: | ---: | --- |
| Island Dinghy | 0 | Free starter | 12.5 m/s | 10 | Classic mint, 3 spokes |
| Reef Skiff | 3 | 600 | 18 m/s | 14 | White/blue sport, 5 spokes |
| Atoll Runner | 8 | 1,400 | 24 m/s | 18 | Carbon/amber D-wheel, T-top |
| Ocean Launch | 15 | 2,800 | 30 m/s | 24 | Wood/brass 6-spoke, twin controls |

There are no real-money purchases. Owned equipment can be equipped without
paying twice. Pairing rules automatically select an owned compatible rod/reel.
Old saves retain catches and coins and receive the starter boat by default.

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

Codemagic runs validation. Signed Android/iOS packages still need export/signing
setup: see `docs/mobile-builds.md`. Research references are in
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

The final retrieve raises the rod while its tip stays bent, lifts the fish beside
the bow and pauses before the catch result. Large catches currently share this
simplified landing animation; landing nets and gaff handling are not simulated.

Sunny, cloudy, rainy and rough weather transition every 150 seconds, independently
of the 20-minute day/night cycle. Pause → Change weather cycles conditions for
preview (allow several seconds for the blend). Clouds, rain, fog, sea ripples,
whitecaps and boat bob respond to weather. Rain is hidden indoors. Weather is
simulated rather than downloaded live.
