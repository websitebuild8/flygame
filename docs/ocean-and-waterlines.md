# Ocean appearance and shared waterlines

## Implemented

The sea now uses a 512×512 map baked from all five **carved island coastlines**.
Offshore water shades toward navy blue; coastal shelves and harbour basins shade
into turquoise/teal. The depth ramp is fictional, not surveyed bathymetry. Its
source polygons and raster are ODbL derivatives beside the existing OSM sources.

A free **Aerial Beach 01** diffuse texture by Rob Tuytel / Poly Haven supplies
seabed variation, resized to 512 pixels and encoded as a 14 KB WebP. An original
256-pixel normal map supplies two crossing, slowly moving ripple layers. These
normal patterns, shore wash and weather-dependent roughness add surface detail.
Close shallows have a sandy-bottom appearance and, on Medium/High, restrained
moving light patterns. There is no runtime download, purchased water plugin or
additional fullscreen reflection/refraction pass.

Eight small moving fish silhouettes are composed into the nearest shallow area
at High, five at Medium, three at Low. They occur around the harbour berths and
selected coastal water points. They fade with depth, viewing angle, darkness and
rough weather. Their rendering stays within the ocean's opaque material, so boats
and quays occlude them normally. This is an inexpensive clear-water illusion,
not transparent water with fully simulated underwater 3D fish. The practical
Nord target is a convincing mobile tropical sea; full refraction and 3D schools
would need a separately profiled higher-quality option.

## Floating and landing fixes

The original wave displacement remained large after the boats were resized;
boats bobbed independently of the shader. `water_surface.gd` now mirrors the
shader's wave phase, scale, harbour shelter and actual PlaneMesh triangle
interpolation at all three mesh qualities. Player boats, all traffic, buoy
waterlines and wakes use that shared surface. The fishing eye is kept above it.
The shader's displacement uses the same 0.22 scale as the vessels.

Two of six NPCs use the already-imported Scout and Glacier Bay assets, sharing
meshes/textures, without cockpit display viewports or extra hand rigs. Shadow
casting is disabled, lower mesh LODs are preferred and visibility ends at 140
world units. The other four traffic boats retain the lightweight hull designs.

The short landing leader now runs vertically from the last guide to each fish's
mouth attachment. Imported model bounds determine the complete tail clearance;
the rod/handle lifts enough to keep the fish above the maximum wave crest.
The landing button checks the full fish bounds. The catch showcase raises its
camera above the water, includes a hanging leader and uses a small shadowless
fill light for night-time readability. Inventory and MVR values are preserved.

`tests/water_landing_checks.gd` checks shader/CPU water agreement at every quality,
maximum-size catches of all five species on all four boats, vertical mouth/line
alignment, complete fish clearance, camera framing, dry catch showcases, imported
NPC count and quality-based shallow fish budgets. Real phone frame times and
appearance still require testing a fresh APK.

## Research and free resources

- [Poly Haven Aerial Beach 01](https://polyhaven.com/a/aerial_beach_01): beach sand by Rob Tuytel.
- [Poly Haven licence](https://polyhaven.com/license): CC0 assets usable in commercial games.
- [Godot GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html): mobile bottlenecks, fill cost and material reuse.
- [Godot screen-reading shaders](https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html): screen copies and rendering order for refraction approaches.
- [Android materials guidance](https://developer.android.com/games/optimize/materials): transparency and lighting cost on mobile GPUs.

The asset licence is saved in `assets/textures/ocean/LICENSE.txt`. Regenerate the
coastal map with Godot's `tools/export_ocean_coasts.gd` followed by
`tools/prepare_ocean.py` using Python with NumPy/Pillow; those tools are build-time
only and add no Python dependency to the game.
