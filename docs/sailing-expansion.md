# Sailing, traffic and island markets

## POV and cameras

Throttle movement now uses the boat's lateral hinge axis consistently: forward command rotates the existing handle toward the bow and upward on screen; reverse pulls it back. The hand contact is measured from the authored knob in lever-local coordinates. The old grip correction incorrectly divided by the resized boat's world scale and could move the hand below the knob, particularly on the Grady-White and Whaler. That correction is removed. The wrist follows the actual moving knob, with restrained rotation and the same imported glove/arm model.

The camera button cycles External → POV → Bird’s-eye → Close external. Hands and physical cockpit controls are used in POV; all three external modes retain the common touch steering/throttle controls. Existing `first_person_driving` compatibility is retained for current gameplay checks.

## Harbours and markets

`island_harbours.gd` is shared by terrain, boat collision, route planning, charts, traffic and berth access. Kelaa retains its widened game harbour. Filladhoo and Vashafaru use mapped harbour footprints; Dhidhdhoo uses the mapped marina/pier reference, and Baarah uses mapped pier locations. Entrances and basins are widened for the small mobile game world. These are convincing adaptations of available locations/orientations, not exact harbour surveys. Real map source metadata remains in `assets/maps/neighbours/islands.json` and the original OSM extracts. `tools/prepare_neighbours.py` now includes pier and marina references as well as harbour outlines/walls.

Every island has an inner berth, entrance markers, quays, pontoons, moored skiffs, an exterior market and equipment shop. Berth actions work only inside the harbour and at low speed with neutral or the engine off. The market reuses one interior scene to avoid retaining five customer rigs/interiors in memory, but switches architecture, decoration, colours and customer clothes per island:

- Kelaa: teal painted market and timber counters.
- Filladhoo: woven shade and net backdrop.
- Vashafaru: white/blue framing and sea-coloured window panels.
- Dhidhdhoo: auction boards, columns and industrial fittings.
- Baarah: green timber slats and braced roof details.

Fish values, inventory, exact-denomination MVR payments, pending payment recovery and save identifiers are shared and preserved.

## Sparse traffic and collisions

Six traffic boats include the imported Scout and Glacier Bay plus four original low-detail boats with colour variations, different cruise speeds, berth waits and random destination selection. One shared navigation grid supplies their routes; no grid is allocated per boat. Boats reserve harbour mouths, use offset travel lanes, slow to two game units per second inside ports and yield near the player. They continue visiting harbours after completing a trip. Their mesh/wake visibility is limited by distance; there are no extra AI rigid bodies or per-boat particle systems.

Player movement samples the complete travelled segment against the same coastlines and quay/breakwater collision data, preventing a fast frame from jumping through a wall. Swept circle tests stop the player before passing through a traffic boat. AI boats also check the player, other traffic and water geometry before advancing. A collision stops movement and gives a short message/haptic cue; no damage or monetary penalty is added. Physics pauses with the existing menus, map and inactive-app handling.

`tests/sailing_expansion_checks.gd` checks forward/neutral/reverse projection and real wrist contact on all four boats, all harbour routes and walls, four camera modes, sustained incoming/outgoing traffic, fast-motion collision and exact MVR sales in all five market themes. Device FPS and touch feel still require an Android/iPhone build.
