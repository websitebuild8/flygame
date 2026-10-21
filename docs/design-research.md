# Design and equipment references

Research checked October 22, 2026. These references informed the implementation;
they are not licences for copying product artwork or 3D assets. All current game
models, shaders and audio were built for this project. Product names identify
real equipment references; models are approximations without copied logos.
Game coin prices and performance multipliers are fictional, not manufacturer
prices, mechanical specifications or product performance claims.

## Mobile interaction

- Apple game controls: https://developer.apple.com/design/human-interface-guidelines/game-controls
- Apple designing for games: https://developer.apple.com/design/human-interface-guidelines/designing-for-games/
- Android touch target guidance: https://support.google.com/accessibility/android/answer/7101858

Applied: stable left/right thumb zones; separate touch ownership for wheel and
throttle; large primary controls; contextual harbour actions; a pause/settings
sheet; visible keyboard focus; colour plus F/N/R text labels; and safe-area
insets on mobile. Most action buttons use 54 logical game units or more. These
canvas units are not automatically Android dp/iOS points; physical target size
and safe-area behavior still need checking on actual devices.

## Boat controls

- Yamaha controls: https://yamahaoutboards.com/rigging/controls
- Yamaha outboard operation manual: https://www.yamaha-parts.ca/thumbs/y/pdf/u63v7ae0.pdf
- Yanmar control/shift delay discussion: https://www.yanmar.com/marine/wp-content/uploads/2021/01/0A6LF-EN0010_2020.09-6LF-operation-manual.pdf

Applied as a game approximation: an F/N/R lever, neutral detent, idle thrust in
gear, continuous throttle beyond engagement, coast-down without thrust, slower
reverse, steering that reverses when backing, and a low-speed direction-change
interlock. The physics deliberately simplifies hydrodynamics. Engine audio is original synthesized material with idle/cruise/full
layers and RPM-dependent pitch, not a recorded Yamaha/PENN/Shimano product.

## Fish anatomy

- Yellowfin: https://www.fisheries.noaa.gov/species/pacific-yellowfin-tuna
- Tuna identification: https://www.fisheries.noaa.gov/s3/2026-02/HMS-Recreational-Compliance-Guide-2026-020325-Final.pdf
- Giant trevally: https://australian.museum/learn/animals/fishes/giant-trevally-caranx-ignobilis-forsskal-1775/

Applied: tapered bodies, metallic dark backs/silver bellies, swept fins, forked
tails, small inset eyes, gill and mouth details, yellowfin finlets, skipjack belly
stripes and a deeper trevally body. Meshes are species-inspired rather than
anatomical scans. No reference illustrations or photographs were copied.

## Fishing equipment

- Shimano Saragosa SW A: https://fish.shimano.com/en-US/product/reels/spinning/swspinning/a075f00002k2gakqam.html
- Shimano Ocea Jigger star drag: https://fish.shimano.com/en-US/product/reels/conventional/stardrag/a075f00002wgo0gqaa.html
- Shimano Grappler Type J casting: https://fish.shimano.com/en-US/product/rods/jigging/a075f00003cuiqqqa1.html
- PENN Fathom II Lever Drag: https://pennfishing.co.nz/product/penn-fathom-ii-lever-drag/
- PowerPro line guide: https://www.powerpro.com/content/dam/shimanosnaffish/PowerPro/newpp/Pick-Your-PowerPro.pdf

Applied: distinct spinning and overhead equipment; spinning bail/rotor, reel foot,
spool lips and crank; conventional side plates, transverse spool and cage;
star drag for the Ocea reference and lever drag for the Fathom reference; tapered
rod blanks with line guides; and braid colour. The reel/rod compatibility rule
and bonus values serve game balance. The overhead mode currently drops the rig
and uses a short jigging motion during retrieval; full depth-based vertical
jigging and adjustable drag systems remain future work.

## Landscape expansion

- AStarGrid2D: https://docs.godotengine.org/en/stable/classes/class_astargrid2d.html
- Dogtooth tuna: https://australian.museum/learn/animals/fishes/dogtooth-tuna-gymnosarda-unicolor-ruppell-1838/
- Bluefin trevally: https://lifg.australian.museum/Group.html?groupId=6X1DgQ9w&hierarchyId=qBHH2Q3E

The expanded chart and seven fishing sites are fictional. No real fishing-site
coordinates or navigable depth claims are made. Routes avoid the same island
exclusion zones used by boat movement, with extra clearance. Boat speed/storage
and unlock goals are fictional. Four boat visuals/helm skins are original.

Hooked-fish movement uses an animated swim/run/jump state and a kinematic line
endpoint; rod spring response is a visual gameplay approximation. The 20-minute
day/night cycle is explicitly game time, with a saved floating-point hour and
lighting interpolation. It does not use system time or location services.
