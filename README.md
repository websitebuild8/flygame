# Ishaq's Fishing Trip

A Godot 4.5.1 / GDScript starter for an offline mobile fishing game.

## Play

Import `project.godot` into Godot 4.5.1 and press Play (F6/F5).
Drive with WASD, arrow keys, or the on-screen buttons. Follow the golden buoy,
stop within 14 metres, then cast. After the bite, hold Reel (or Space) to bring
in the fish; release before tension reaches 100%. Return home, sell catches,
and buy engine upgrades. Three catches unlock eastern waters. Progress saves
locally. The Return home button is a prototype convenience.

## Current limits

All geometry is generated in code; no Blender or paid assets are needed.
Islands and distances are fictional placeholders. Species names are provisional;
catch rates, habitats, weights and behaviour are not yet based on verified data.
Fishing, water and boat movement are intentionally simple. This is an early
prototype, not a finished realistic simulator. Landscape UI needs real-device
safe-area, small-screen and performance testing. Boat collision uses broad
island exclusion zones.

## Build direction

The Compatibility renderer is selected for a broad initial device baseline.
`codemagic.yaml` currently installs Godot on a Mac runner and validates the
project. It does NOT yet generate an APK, AAB or signed IPA. See
`docs/mobile-builds.md` for the remaining build setup. No credentials belong
in this repository.
