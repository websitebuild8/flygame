# Angler's Club and visual HUD

## Player flow

The gameplay HUD has separate **book** (fish collection) and **gold trophy**
(delivery contracts) buttons. Both open Angler's Club directly. Collection,
Contracts and Weekly tabs live there; they are no longer a Settings menu option.
**Back to fishing** resumes gameplay directly. Settings still owns settings only.
The existing pause flag is reused internally so opening the Club also suspends
boat inputs, fight vibration and gameplay updates.

## Visual progression

- Collection cards show 2D portraits rendered from the existing fish models,
  personal-best weight, catch count, a mastery meter and earned medals.
- Bronze/discovery: first catch; silver: five catches; gold: fifteen catches.
  Undiscovered species are dimmed with a lock. Tap a fish or Details for location,
  value and behaviour information, instead of displaying paragraphs on every card.
- Contract cards show the target fish, minimum count/weight icons, reward and an
  Accept action. Active delivery cards show both meters and a claim state. Changing
  an unfinished contract requires a second confirmation tap before progress is lost.
- Catch information also displays a medal for discoveries, records and trophy catches.
  Reward claims show a small earned-MVR celebration banner.
- Weekly goals use fish illustrations, separate catch/variety meters and a medal
  reward card. Normal rewards, one-time claims and the progression save schema are
  retained. A small HUD badge signals claimable rewards.

## Gameplay HUD

The left header shows a location pin/name, Settings gear, MVR wallet and fish count.
The upper-right strip has chart, camera, collection and trophy icons with descriptive
tooltips. Buttons keep 56px logical targets. The clock uses weather/day-night icons.
Empty route instructions and repetitive lower-screen driving hints are hidden.
Routine status messages fade after 4.5 seconds; live fishing feedback still updates.
Steering, throttle, casting, reeling and actual reward logic are unchanged by this UI.

## Free resources and size

Kenney Medals and Game Icons are CC0. Selected images are copied into assets/ui/
with the original licence texts. Extra matching line symbols are original SVGs.
Fish portraits are transparent 384x216 PNG renders of the already licensed game
models, generated once with tools/render_fish_portraits.gd. Existing fish attribution
still applies; these renders are not represented as CC0 fish models. Source details
are in assets/ui/SOURCES.txt and the in-game Credits.

All cards use cached 2D textures. There are no live 3D viewports in the UI and no
new fish models. Text remains for names, amounts, requirements and actions; icons
and progress meters replace decorative/instructional text. The asset source budget
is below 1 MB; APK size and phone frame rate have not been measured for this change.

## Validation

Gamified UI checks exercise independent entry/exit, icon targets, five portraits,
medal/progress display, unbroken weight labels, real contract acceptance, fading
status, fish details and screen containment at two landscape sizes. Progression,
menu, shop, graphics, helm, cockpit, gesture/haptic and trip checks provide regression
coverage. Screens are rendered and inspected to catch layout errors.
