# Kelaa island recreation

The home island now uses OpenStreetMap way 485114123's 114-point coastline and 138 mapped road/path features, downloaded on 2026-10-27. The dataset includes 20 building footprints, the harbour and breakwaters, sports grounds, schools/health facilities, council building and mosques. The long curved island, northern settlement and southern spit retain their mapped north/south orientation.

This is a compressed, stylised recreation: 0.04 game units per geographic metre, anchored so the existing home mooring remains accessible. It is not a full-scale survey or a navigational chart. The other islands retain their existing game positions and artwork. Individual extra houses, facades, walls, roofs, palms and the adapted shop/pier layout are original fictional decoration; they do not represent an exact building inventory. Approximately 160 houses and 250 palms are generated deterministically around the mapped streets. Mapped named landmarks inform placement, with stylised mosque towers and civic buildings. Shop interiors and market transactions remain in their existing scenes.

The terrain, ocean chart, circular minimap, cockpit navigation screens and boat obstacles use the same coastline. Breakwaters also obstruct boats. Baarah Drift has moved a short distance west to keep it outside the longer island; its ID, unlock and fish species remain unchanged. The home dock, save balances, boat ownership and sale flow are preserved.

Static coloured village geometry is combined into 16 m spatial chunks (fewer than 30 draws for buildings/roads). Palms share an instanced mesh and are partitioned by the same grid. No per-house or per-tree update loops run during gameplay. Temporary construction buffers are released after mesh creation. Textures are not needed for the new buildings. Low/Medium/High and shadows settings still apply; direct phone performance must be checked with a rebuilt APK.

## Sources and reproduction

- Data: © OpenStreetMap contributors, https://www.openstreetmap.org/copyright
- Coastline: https://www.openstreetmap.org/way/485114123
- Database licence: ODbL 1.0, https://opendatacommons.org/licenses/odbl/1-0/
- `assets/maps/kelaa/source.osm` is the original extract.
- `assets/maps/kelaa/kelaa.json` is the distributed derived geometry, source metadata and licence links.
- `python3 tools/prepare_kelaa.py assets/maps/kelaa/source.osm` rebuilds the derived data without a network request.
- `tests/kelaa_checks.gd` checks geography, static geometry budgets, collision, fishing spots, safe harbour routes, and market/shop access. Existing ocean checks now exercise the new island location and contour.

## Harbour and island-spacing update

The boats now share a 0.22 world scale, with their waterline, first-person camera anchors, hands and tackle kept in the same scale. Showroom previews retain their previous framing. A widened game-scale basin is cut into the home shoreline: stone breakwaters enclose the north/south/west sides, an inner quay closes the east side, and the only entrance is the marked western gap. The same walls block steering and navigation routes. Inner pontoons, fenders, bollards, entrance markers and small original moored skiffs decorate the basin. Water and boat bob are calmer inside; boat speed is limited to 4 game units per second inside the basin and returns smoothly to the vessel's normal performance outside. Market/workshop actions require the inner berth. The menu's home action now plots a route rather than teleporting past the entrance.

Filladhoo, Vashafaru, Dhidhdhoo and Baarah now use their own OSM coastlines, roads and selected mapped footprints, plus original stylised houses/vegetation. Derived geometry and licence information are in `assets/maps/neighbours/islands.json`; original public extracts remain beside it in the repository. Boat ownership, equipment and sale balances are unchanged. Island positions and fishing markers are spaced farther apart for gameplay, and the ocean, navigation grid and charts cover the larger area. These are compressed, fictional inter-island distances, not real nautical distances. Baarah's eastern fishing marker now shares the three-catch eastern-water unlock.

The source shape is retained in `mapped_coast`; the rendered home `coast` includes the widened harbour cutout. Buildings/palms are spatially rebased and use distance visibility so neighbouring villages do not all render in full detail from the home island. `tests/harbour_world_checks.gd` checks mandatory entrance routing in both directions, walls, all fishing spots, relative boat height, cockpit usability, berth services and the non-teleporting home action.
