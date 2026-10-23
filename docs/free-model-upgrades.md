# Free model upgrades and research — 2026-10-23

## Integrated and credited

| Asset | Creator / licence | Where used |
| --- | --- | --- |
| [Fishing Rod, Rigged and Animated](https://sketchfab.com/3d-models/fishing-rod-rigged-and-animated-78991bf44cf54acb8660bef317d72c7a) | Ergin ERYILDIR, CC BY 4.0 | Imported starter spinning reel in live fishing and shop; full imported starter rod in the showroom. |
| [Boat Motor](https://sketchfab.com/3d-models/boat-motor-a496b95b40074b91aeeb1e9a2aae913b) | Bora Özakaltun, CC BY 4.0 (source metadata uses older alias paraverun) | Replaces primitive outboards on every boat and the engine shop preview. Propeller is split from existing mesh and rotates separately; motor pivots with steering. |

The source downloads supplied 1k textures. Rod/reel source is approximately
3.6 MiB, with about 23k triangles for the entire assembly; the live reel uses
only its four rigid mesh parts. The outboard has 4,522 triangles (3,850 body,
672 propeller). Source files, licence records and modifications are under
`assets/models/tackle` and `assets/models/boats`. Credits are also in the pause
menu and exported builds. No purchases, subscriptions or new accounts were used.

The live rod blank still uses the game's bending geometry so it can react to
fish direction and line tension. This pass does not replace the branded upgrade
reels with one generic model; those retain their distinct original geometry.
The downloaded generic reel is not presented as an official Shimano or PENN model.

## POV control correction

The throttle touch target previously followed `camera.unproject_position()` of
the 3D lever. Projection could put the rail and reverse end below the screen.
The POV throttle now uses a fixed right-side glass panel, with the entire drag
range, handle and F/N/R markings inside the control rectangle. Drawing and input
use the same centre. Unique boat colours and twin-drive marks remain. The
physical lever and steering wheel still move with the controls. Engine cutoff
remains above the throttle; speed information is beside the panel.

## Boats / sports fishing candidates

- [Speedboat, ПГГПУ](https://sketchfab.com/3d-models/speedboat-9916bd4433024202ab84e43426fc2139):
  CC BY 4.0, about 86.6k triangles; official 1k GLB download listed as 20 MB.
  Download attempt timed out. Not imported or substituted into gameplay.
- [Dinghy, Vlad model's](https://sketchfab.com/3d-models/dinghy-92b24c2f8b874360ab84bf0e881883fe):
  CC BY listing, about 7.8k triangles and 2k PBR textures. Has a separate NoAI
  restriction. Not downloaded or used in this pass.
- [Fishing Reel, jo.bergg](https://sketchfab.com/3d-models/fishing-reel-734ab88a7a6e442dbf168c27ac92bdf3):
  CC BY, approximately 475k triangles. Too heavy to use unchanged on mobile;
  the lower-cost reel from the rigged rod was selected instead.
- [Boat Animated, Leo-Angotialuk](https://sketchfab.com/3d-models/boat-animated-6a292f09d259471aab3655bbd9dcd6ef):
  CC BY, about 756k triangles; includes the Bora motor. Not selected as a
  mobile hull replacement at that density.

No new hull has been integrated yet. Existing hull silhouettes, unique helms,
boat unlocks, storage and handling remain. A hull replacement must be checked
for cockpit room, helm alignment, motor mount position, waterline and mobile
cost, not just whether the preview looks attractive.

## More fish searched

The two existing imported fish remain the active catch catalogue. Additional
scans found during this search include Japanese snapper (Paracaesio caerulea),
Neptune grouper (Cephalopholis igarashiensis) and red barracuda (Sphyraena pinguis).
They are CC0 listings, but they are not interchangeable with the game's earlier
humpback snapper, marble grouper or great barracuda. Maldives occurrence and
regional appearance still need verification before adding any as local species.
See [the fish shortlist](fish-asset-shortlist.md) for direct sources and the
painted sweetlips regional-taxonomy issue. No new fish species was added in this
pass, and retired placeholder fish were not re-enabled.

## Fish follow-up, 2026-10-23

Skipjack, sailfish and Randibu’s Coryphaena hippurus are now integrated. See fish-asset-shortlist.md and the per-asset source/licence records. The earlier Ryba mahi mahi ornament was visually rejected and is not included.
