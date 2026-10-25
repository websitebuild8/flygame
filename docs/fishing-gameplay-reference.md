# Fishing gameplay reference and adaptation

Reference: user-provided `example.mp4`, inspected locally on 2026-10-26. Duration 27.09 seconds, portrait 212×480, approximately 18 fps. Frames sampled every 0.25 seconds across the complete clip, with closer inspection of the hook, fight and result stages. The recording is used as a motion/control reference; original project art, fish, sounds and interface are retained.

## Observed sequence

- 0–3 seconds: bite marker and vertical coloured timing gauge, HOOK action.
- 3–4 seconds: upward rod strike, camera response and timing-quality feedback.
- 4–14 seconds: hold/release reel, circular reel feedback, curved gauge, running fish and changing line distance; hands wind the crank and lift the entire rod.
- 14–16 seconds: upward-swipe prompt and power-reel burst.
- 16–20 seconds: bent rod recovery and fish lifting clear of water.
- 20–27 seconds: hanging fish showcase, species, weight and reward; the result counters animate up to the final catch weight and reward.

## Implemented landscape adaptation

Timed hook gauge with strike quality, spring rod load and strike kick, authored textured gloved hands and sleeves by JUST, grip anchored on the rod and winding hand following the authored crank bearing, eased reel animation and spool travel, slack/taut segmented line, hooked fish lateral runs/jumps/splashes, gentle camera tracking/bob and power FOV, floating shallow metal-framed tension gauge, fish stamina, charge ring, swipe-up power reel and keyboard R alternative. Excessive slack lets a fish escape; high tension snaps line. Existing manual Put fish on boat remains available when the fish is lifted before the progress bar fills. Pause/menu/map suspend fight simulation.

An individual is rolled once per cast with weight, price, size, fight strength and a catch grade. Prices are fictional MVR game balance calculated from species base value, weight and a modest individual price factor. Landing preserves this same weight/value rather than rerolling. Inventory and market payment continue using the stored offer, including across save reloads. Existing saves remain compatible. No extra fish species were introduced.

`tests/fishing_gameplay_checks.gd` checks repeated-species variation, weight bounds, stronger/larger/heavier individuals, single hook bonus, power charge/consumption/retrieve speed, slack escape, touch pointer ownership, crank hand anchoring and save persistence. It runs alongside the seven prior suites in Codemagic.

The initial procedural hand shapes have been replaced by JUST’s “Hand With Gloves” (CC BY 4.0), including its finger skeleton and textured sleeves. Two IK chains keep the left hand on the rod and the right hand winding. The starter spinning reel is mirrored across its lateral axis for right-hand retrieval, preserving its authored spool and bearing axes. Other spinning reels also use right-side cranks. The complete Ergin ERYILDIR rod mesh now appears in gameplay with its UV maps and shader bending, replacing cylinder blanks. Both authors are credited in-game and beside the assets. These are licensed models animated for this project, not assets extracted from the reference game. Android/iPhone touch feel and performance require a new device build.


2026-10-26 refinement: orange bevelled circular reel control with rotating external metal handle, hook timing gauge with red/yellow/green segments, outlined floating fight callouts and retrieval strength, stronger spring hook-set camera pitch, horizontal fish tracking, restrained fight roll and a power-reel FOV kick. No opaque rectangle behind the fight gauge. Motion preview includes waiting/hook, reeling, run, burst and manual landing.

Real-hand refinement uses Daiwa pro angler Justin Duggan’s photographed [spinning-rod grip guide](https://daiwa.us/blogs/news/how-to-cast-a-spin-rod-correctly) and the [Texas Parks and Wildlife casting guide](https://tpwd.texas.gov/publications/pwdpubs/media/pwd_bk_k0700_0639_casting.pdf). These demonstrate a thumb above the grip, fingers below, and the reel stem balanced among the fingers. The model now has individually staggered finger curls, a thumb opposing the grip, a relaxed retrieval-hand pinch, and a hold closer to the reel seat. Camera/body-relative shoulders stay stable as the rod moves; two-bone arms bend outward, with forearm rotation distributed along the authored twist bones. The tackle is closer to the player to reduce exaggerated reach. These references inform the new pose; their photographs are not redistributed as game assets.

The continuous line now runs from the spool lip through the spinning reel’s rotating pickup, the four measured ceramic-ring hole centres, the final tip ring and the lure/fish. Guide positions use the same length-preserving deformation as the authored rod shader. Spool oscillation follows its actual spindle axis with millimetre-scale travel; overhead reels feed directly and use upper-side guides. Reference: [Shimano threading and reel guidance](https://fishshop.shimano.com/pages/shimano-faq).

POV driving reuses the authored glove/arm model: one hand winds the physical wheel rim, the other grips and follows the actual throttle knob. Each boat’s wheel size, rim centre and lever grip are measured independently from its geometry. A comfortable grip arc/regrip avoids rotating the wrist through the wheel’s full travel. Controls remain hidden outside POV. The POV wheel retains its angle after touch release, while the external-camera arcade control still recentres. Existing thrust-dependent turning, reverse steering, throttle detent, shift interlock, engine cutoff and momentum remain in force. References: [NMMA single-lever controls](https://www.discoverboating.com/resources/control-units), [Dometic SeaStar no-feedback helm](https://www.dometic.com/en-gb/product/dometic-seastar-front-mount-helm-78). Travel/ratios are game-scale approximations. `tests/line_helm_checks.gd` adds all-six-boat grip, visibility, lever travel, guide routing, endpoint and pickup movement checks to Codemagic.
