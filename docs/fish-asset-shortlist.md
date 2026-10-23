# Textured fish asset research

Updated 2026-10-23. Listing availability is not proof that a model has been
downloaded, imported, animated or tested in this game.

## Giant trevally — integrated

- Species: Caranx ignobilis (existing game catalogue entry).
- Creator: ffish.asia / floraZia.com.
- Source: https://sketchfab.com/3d-models/cc0-giant-trevally-caranx-ignobilis-e6446df50ba746ed8ce8a3dd66b3b8e8
- Listing licence: CC0, https://creativecommons.org/publicdomain/zero/1.0/
- Listing geometry: approximately 483,200 triangles / 297,400 vertices.
- Status: downloaded through the official signed-in GLB download. Optimised
  asset: `assets/models/fish/trevally.glb`, 51,903 triangles, approximately 4.5 MiB.
  Source textures are 1k; body/tail motion is added by the game shader.
- Preparation checklist: inspect texture coverage and scan defects, simplify with
  UV preservation, reduce textures, align to game -Z forward / +Y up, add tail
  movement, then inspect hooked, landed, showcase and market views. The 10k-triangle trial damaged texture seams; the retained 51,903-triangle
  version preserves them. Actual mobile-device performance remains to be checked.
- The procedural fish are retired from active gameplay. Five imported species are now catchable: yellowfin, giant trevally, skipjack, sailfish and mahi-mahi.

## Painted sweetlips — candidate for an additional species

- Model label: Diagramma pictum pictum; creator ffish.asia / floraZia.com.
- Source: https://sketchfab.com/3d-models/cc0-painted-sweetlips-d-pictum-pictum-98f93c21cd194234bf95c82974f6dd77
- Listing licence: CC0. Approximately 1.3 million triangles / 650,200 vertices.
- Status: listing verified in browser; not downloaded or added to the catalogue.
- Maldives reference: the Maldives Reef Fishery Management Plan lists
  Diagramma pictum, painted sweetlips, Kilan'bu guruva:
  https://fisheries.gov.mv/images/MRFMP2020-1728980959365.pdf
- Regional appearance/taxonomy needs checking before integration. The scan is
  explicitly labelled a subspecies; do not assume its markings represent the
  Maldives population. A newer regional taxonomic reference distinguishes
  Diagramma cinerascens from some historical Diagramma pictum records:
  https://saiab.ac.za/wp-content/uploads/2022/11/1._wiof_volume_3_text.pdf

## Other scanned models found, not approved as Maldives replacements

These are useful leads, not substitutes for similarly named game fish.

| Listing | Licence shown | Reason to hold |
| --- | --- | --- |
| [Neptune grouper, Cephalopholis igarashiensis](https://sketchfab.com/3d-models/cc0-neptune-grouper-c-igarashiensis-777d773273f343c6b11e647474fb1c0e) | CC0 | Maldives occurrence not verified; not peacock hind or marble grouper; about 1.5M triangles. |
| [Japanese snapper, Paracaesio caerulea](https://sketchfab.com/3d-models/cc0-japanese-snapper-p-caerulea-b762ecdee0e7448983c3e5165d750913) | CC0 | Maldives occurrence not verified; not red bass or humpback snapper; about 796k triangles. |
| [Red barracuda, Sphyraena pinguis](https://sketchfab.com/3d-models/cc0-red-barracuda-sphyraena-pinguis-8771a3aa9d1a40a19e31a45da2b4e2ef) | CC0 | Different species from the game's great barracuda. |

## Excluded downloads

- MEA AQUA bigeye trevally sample: evaluation sample; do not treat as a free
  production replacement.
- Ryba mahi mahi: downloaded and visually rejected as a decorative ornament rather than a realistic mahi-mahi. The owner confirmed additional modification permission, but this candidate is not shipped. Randibu’s properly shaped Coryphaena hippurus replaces it.
- Paid fish packs, unknown-licence copies and models without official download
  access have not been used. No suitable free textured wahoo has been verified.

## Additional species — integrated 2026-10-23

| Species | Source | Licence | Prepared geometry |
| --- | --- | --- | --- |
| Skipjack tuna | [ffish.asia scan](https://sketchfab.com/3d-models/cc0-skipjack-tuna-katsuwonus-pelamis-9431157b2fce4ea9a72d9cfe3ce37a6d) | CC0 | 74,045 triangles, 3 texture regions, 1k textures |
| Sailfish | [RED SIDE](https://sketchfab.com/3d-models/sailfish-78249838285d4f67a24c3832464c37ae) | CC BY 4.0 | 23,994 triangles; unpainted source receives blue/silver body and patterned sail shader |
| Mahi-mahi, Coryphaena hippurus | [Randibu fish pack](https://randibu.itch.io/3dfish) | CC BY 4.0 | 1,306 triangles, original painted colour map reduced to 1k |

Official downloads only; no payment. These are distinct meshes, not recolours of the tuna. The source GLBs and Randibu archive remain in Downloads. The prepared models are included in the repository; builds do not fetch or convert them. Each has its own credits/source record. All use independent shader swimming and the existing hooked, landing, catch and market flows.

Preparation: use Godot `tools/convert_mahi.gd -- SOURCE_FOLDER OUTPUT.glb` to convert Randibu’s FBX, then `tools/prepare_species.py SPECIES SOURCE.glb NODE MESHOPTIMIZER/index.js` for each model. Requires numpy and meshoptimizer 1.3.0 only during preparation. Originals are left unchanged. Confirm head is -Z and dorsal fin is +Y in previews after any asset replacement.
