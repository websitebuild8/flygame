# Trip polish: catches, choices and ownership

This release expands the existing Angler’s Club rather than adding a new world or
new heavy model packs. Everything here is free gameplay progression. The paid
Finish Collection remains a preview; no billing has been enabled.

## Player flow

- **Book → Collection:** fish portraits, undiscovered silhouettes, mastery medals,
  personal records, known fishing spots, lure/depth/time/weather hints.
- **Start fishing → Setup:** choose one of three free lure finishes and three
  feeding layers. The paused setup screen previews relative chances for the
  current point, time and weather. Done returns to the rod.
- **Trophy → Daily:** three optional requests (three fish, two of a rotating
  starting-water species, one specimen of at least 6 kg). Each pays earned MVR
  and XP once. No entry costs, streaks or inventory consumption. Claims work
  anywhere. Resets at midnight UTC (05:00 Maldives time).
- **Trophy → My boat:** name each owned vessel, select an earned medal and view
  fleet ownership and livery milestones. Names and medals appear in the driving
  HUD. Naming is local/offline, at most 22 characters, and can be cleared.
- **Showroom → Boats → Customise:** Captain’s teal unlocks after 10 lifetime fish,
  Ocean racer after 30; these are boat-only finishes. Existing level 5/10/15
  finish gifts remain available.
- Captain badges unlock at 1, 15 and 50 landed fish. Badges and liveries are
  cosmetic and never change fishing success or speed.

## Fishing and catch presentation

`fishing_conditions.gd` uses authored **game balance**, not measured Maldivian
fish ecology or live weather data. Matching lure and depth increases a species’
relative weight; time, weather and overhead jigging provide smaller modifiers.
Every fish in a point’s original pool retains a positive chance, and choices
never introduce a species outside that pool. The depth selection represents a
feeding layer, not a new physical underwater simulation. Lure choices are
finishes of the existing licensed hard-bait model, not additional lure meshes.

The catch’s rolled weight, offer and strength remain immutable from cast to sale.
A short reveal counts weight/value up to those exact figures. Fresh, large and
trophy specimens receive 1/2/3 specimen stars (separate from challenge stars).
Discovery and personal-best banners, medals and a short pooled 2D sparkle effect
provide extra celebration. No display leader line is added. The hooked model is
reparented into the showcase rather than instantiated again on landing.

## Guidance and comfort

Contextual first-trip cards cover steering/throttle, stopping at a buoy, choosing
setup/casting, hooking/reeling, bringing a fish aboard and market payment. Got it
dismisses a card; performing its action also marks the relevant lesson learned.
Settings can disable or replay tips. Sound, vibration, reduced camera/reveal
motion and tutorial preferences persist. Menus and app focus loss retain the
existing pause/haptic cancellation behavior.

## Atmosphere and performance

`ocean_activity.gd` pools six tiny opaque unshadowed bird meshes, one small jumping
fish silhouette and two expanding surface rings. Birds gather near fishing
points in daylight; jumps occur occasionally away from the boat. Storms, night,
shops, markets and catch reveals hide this activity. Low/Medium/High displays
2/4/6 birds. Existing sea traffic and harbour activity remain intact; no land
exploration is reintroduced.

- Text-heavy HUD refreshes run at 10 Hz. Fight gauge/reel drawings, boat motion,
  steering input, line physics and hands continue at their existing update rate.
- Automatic 3D resolution samples rendered frames (not physics ticks), ignores
  menus/background/catch screens and includes a warmup. Two slow 3-second windows
  lower scale by .05; four healthy windows recover .025. Bounds are .45 up to the
  selected preset’s .60/.80/1.0 ceiling. UI resolution stays unchanged. The option
  can be disabled for manual settings. Preset frame targets remain 30/60/60 FPS.
- Settings can show FPS and actual 3D render scale for phone testing.
- Reusing the landed fish avoids a second model/material construction at reveal.
- No existing assets or fish have been removed and no new texture pack is added.

These changes reduce some CPU/UI work and GPU fill cost; they **do not establish
an actual FPS improvement on the OnePlus Nord N20 SE**. Resolution reduction helps
GPU bottlenecks but cannot solve every CPU or memory bottleneck. Test a release
APK on that phone, particularly at harbours, in rain, during fights and after
repeated shop visits. Capture FPS/scale and perceived touch responsiveness before
adjusting the defaults further.

Implementation references:
[Godot 4.5 resolution scaling](https://docs.godotengine.org/en/4.5/tutorials/3d/resolution_scaling.html)
and [3D performance](https://docs.godotengine.org/en/4.5/tutorials/performance/optimizing_3d_performance.html).

## Validation

`tests/trip_polish_checks.gd` checks relative fishing preferences and original spot
pools, daily rollover/clock rewind/one-time payout, save persistence, boat badges
and boat-only finishes, adaptive-resolution bounds and pause/manual behavior,
setup pausing, tutorial availability, real landing integration, showcase model
reuse, exact final catch figures, and 1280×720 / 960×540 menu fit. Existing fishing,
water landing, harbour access, haptic, cosmetic, UI and progression suites remain
part of the regression run. Real device vibration/thermal behavior and gameplay
balance still require phone playtesting.

## Angler’s Club scrolling

The Club uses a dedicated vertical scroller. Swipes work across cards and buttons,
with a 9-pixel intent threshold, capped release speed and exponential deceleration.
Mouse dragging, smooth wheel targets and trackpad pan gestures are supported.
A tap during a fling stops the list; a swipe cancels the underlying button press.
Fish portraits open on release rather than on initial contact. Direct scrollbar
use and boat-name editing retain their native controls. The scrollbar has a wider
touch area, each tab remembers its position, detail pages open at the top and Back
returns to the prior list position. Hiding/closing the Club or losing app focus
cancels the gesture and momentum.

`tests/club_scroll_checks.gd` dispatches real viewport mouse events over buttons
and checks drag cancellation, deliberate taps, touch movement, release inertia,
wheel interpolation, bounds, hide cancellation and tab/detail position restore.
Reference: [Godot ScrollContainer](https://docs.godotengine.org/en/4.5/classes/class_scrollcontainer.html).
