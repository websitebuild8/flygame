# Real boat models

Integrated 2026-10-24. Scout and Boston Whaler retain their existing save IDs and progression. Glacier Bay and Grady-White are additional purchasable upgrades with new save IDs.

| Game ID | Model | Source | Prepared geometry |
| --- | --- | --- | --- |
| skiff | 2004 17-foot Scout Centre Console | [BoatUS Foundation](https://sketchfab.com/3d-models/2004-17-scout-center-console-185e7c1dbf254b57b42b1979c45e4117) | 83,580 triangles, about 7 MiB GLB |
| launch | Boston Whaler 285 Conquest | [BoatUS Foundation](https://sketchfab.com/3d-models/285-conquest-boston-whaler-61e2b2fae81b4e858b401ce7ccc8d8d2) | 88,609 triangles, about 4.7 MiB GLB |
| glacier | Glacier Bay | [BoatUS Foundation](https://sketchfab.com/3d-models/glacier-bay-6c4e6c341c09466fa6d6aafb8d7312b0) | 85,427 triangles, about 6.4 MiB GLB |
| grady | Grady-White Freedom 325 | [BoatUS Foundation](https://sketchfab.com/3d-models/freedom-325-grady-white-71ca8a73f97d44a98f92dd785e151b93) | 112,753 triangles, about 7.2 MiB GLB |

All four official listings offer CC BY 4.0 downloads. Creator credit, licence link, original hashes and modifications are retained beside the assets and in the pause-menu credits. The project owner also confirmed permission on 2026-10-24. No manufacturer endorsement is claimed.

Original GLBs remain untouched in Downloads. Runtime GLBs retain source 1k maps, detailed cabins/consoles, rails, seating and original outboards. The Scout road trailer and its unused textures were removed. Original wheel, lever, motor and propeller meshes were separated into independently animated parts. Wheel bearing frames and propeller axes were calibrated to the hardware, rather than using the hull's origin. The console/instruments stay fixed. Individual POV and bow-fishing camera mounts are provided; touch throttles stay docked on screen.

The Scout uses the blue skiff control skin and single engine; the Boston Whaler retains the gold launch skin, twin levers and twin steering outboards. Engine cutoff, neutral, speed/inertia, sound blending, map, fishing and market access continue to use existing gameplay. A small functional icebox remains on each deck. The default mooring sits beside the jetty rather than intersecting its posts.

Build-time preparation uses `tools/prepare_boats.py` and `tools/simplify_boat.mjs` with numpy and meshoptimizer 1.3.0. Godot/Codemagic consumes the prepared assets directly, without downloading models or installing these preparation dependencies.

The separate `boat_model_checks.gd` suite checks hull selection, trailer removal, texture/mesh budgets, independent wheel movement, POV camera reach, motor steering, twin propellers, cutoff and old save IDs. Other existing gameplay suites cover purchases, compatibility, persistence and fishing. Actual Android/iPhone performance still requires a device build.


Glacier Bay costs MVR 4,200 after 22 catches and holds 30 fish. Grady-White costs MVR 6,000 after 30 catches and holds 36 fish. These are fictional gameplay prices and specifications. Both retain original twin outboards/propellers, steering wheel and throttle controls. Glacier Bay has violet/navy controls with four spokes; Grady-White uses cyan/silver with three spokes. The fixed POV throttle remains accessible on the right. Both support the existing engine, propeller and icebox upgrades. Save validation uses the boat catalogue, preserving new hull ownership when loading.

Grady's source is a skinned FBX conversion: wheel and propeller groups are identified using the original dominant joint weights, then prepared as independent rigid parts in their authored mesh pose. Its static hull is preserved; no source autopilot animation plays in the game. Glacier's material-merged mesh is separated by connected hardware components. Original 1k maps are retained for both models. Prepared geometry stays below 120k triangles per boat. Device performance has not been measured.
