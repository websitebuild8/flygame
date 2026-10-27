# Harbour rock armour and white navigation beacons

The five playable harbours retain their shared navigable layouts and collision
boundaries. Their breakwaters now have submerged structural cores, concrete
inner faces and coping, and irregular sloping piles of textured armour stone
on the seaward faces. The entrance towers sit on concrete end platforms; each
pair has a white body/gallery with red and green lantern variants. The lights
become brighter at night with a simple game flash cycle.

## Reference basis

The user's references show angular grey/brown armour stone, dark wet revetment
rocks, concrete end platforms and short white harbour-light towers. MTCC's
Kelaa Phase 2 project lists breakwater and revetment work, quay wall and paved
areas, plus navigation lights and mooring buoys. Vashafaru's MTCC harbour
project and the existing OSM-derived harbour/pier locations provide additional
context. The game remains a compressed, convincing recreation rather than
an exact as-built survey; 2026 announced upgrades are not assumed complete.

- https://mtcc.mv/project/sh-feevah-harbour-upgrading/ — page title H.A. Kelaa Harbour Project (Phase 2), completed July 2020.
- https://web.mtcc.mv/project/ha-vashafaru-harbour-project/
- https://dev.mtcc.mv/mtcc-has-signed-an-agreement-with-ministry-of-infrastructure-housing-and-urban-development-towards-implementation-of-projects-3/ — Kelaa upgrade agreement, September 2026.
- Original mapped source references remain in `assets/maps/kelaa/` and `assets/maps/neighbours/`.

## Free models and adaptations

- **Boulder 01**, Rico Cilliers / Poly Haven, CC0: https://polyhaven.com/a/boulder_01
  Photogrammetry geometry reduced from 66,122 to 580 triangles, vertex buffers
  compacted and photographic maps resized to 512 pixels. One mesh/material is
  shared across spatial MultiMesh groups. A shader adds a dark wet band and
  restrained grey/brown variation.
- **Lighthouse**, Codels library, CC0: https://codels.download/models/lighthouse
  The free code-made model is adapted into a short white beacon: landscape base
  and steps removed, striped body repainted white, components merged to three
  surfaces, dimensions scaled and widened, coloured lantern materials added.

Licence records and checksums: `assets/models/harbour/LICENSE.txt` and
`harbour-source.json`. Reproduce by running Godot in editor mode with
`tools/prepare_harbour_assets.gd -- <source-directory>`, followed by
`tools/compress_harbour_textures.py`. Embedded source files are preserved under
`assets/models/harbour/source/` with `.gdignore`; they are excluded from the game.

## Mobile budgets and checks

Each harbour has fewer than 300 rock instances. High shows all; Medium shows
80%, Low 55%, distributed along the walls. Groups cull at 180/135/95 world
units respectively, and rock/beacon shadow casting is disabled. The rock mesh
is about 43 KB, compressed texture maps total about 236 KB, and the merged
beacon about 223 KB (source file sizes, not measured APK size changes).
No physics body is allocated to each stone; shared harbour boundaries still
handle collision. Entrance clearances, traffic routes, markets and waypoints
are unchanged. `tests/harbour_world_checks.gd` also verifies all five rock
installations, ten lanterns, texture/mesh budgets and quality scaling.
