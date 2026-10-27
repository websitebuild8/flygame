# Ishaq's Fishing Trip — promotional video

`brag.mp4` is the 20-second 1080p/30 fps trailer. `brag.jpg` is its selected
poster, also baked into frame zero. `share-copy.txt` is the ready-to-post caption.
`credits.txt` records music and visible game-asset credits.

`brag-plan.md` and `composition-brief.md` describe the edit. `composition/`
contains the editable local Hyperframes project, footage, music and SFX.
With Node 22+, FFmpeg and FFprobe installed, run `npm run dev`, `npm run check`
and `npm run render` inside that directory. The CLI is pinned in package.json.

The game captures use isolated temporary saves and staged progression. The
video is labelled in development. The entire output directory has `.gdignore`
so promotional assets do not inflate the game build.
