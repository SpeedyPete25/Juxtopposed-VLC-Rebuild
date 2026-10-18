# Juxtopposed VLC Rebuild

[Juxtopposed's open-source VLC redesign]
Video: https://www.youtube.com/watch?v=ERFeOgqk324
Design File: https://www.figma.com/design/5UEUReDQz2dQjwoQDHY5z9/VLC-Redesign--Community-
implemented in VLC 4's real Qt/QML interface, as patches on top of upstream VLC.

## Layout

- `patches/` – the redesign, as `git format-patch` output against `VLC_BASE` (see `scripts/env.sh`)
- `scripts/setup.sh` – clone VLC into `vlc/` and apply the patches
- `scripts/build.sh` – build `dist/vlc/vlc.exe` in VideoLAN's Windows CI Docker image, using their prebuilt contribs
- `scripts/make-icons.sh` – rebuild `VLCIcons.ttf` from the Figma icons (`scripts/icons/mapping.json`)
- `scripts/run.ps1` – run the build in portable mode (never touches an installed VLC's settings) and screenshot it
- `scripts/save.sh` – commit the work in `vlc/` and regenerate `patches/` from it
- `design/figma-assets/` – SVGs exported from the Figma file

## Workflow

```sh
scripts/setup.sh            # once
scripts/build.sh            # incremental after the first (~minutes) build
powershell -File scripts/run.ps1 -Media dist/media/test-clip.mp4 -Shot shot.png
```

Requires Docker (the build runs in VideoLAN's image) and Windows to run the
result. `vlc/` is a local clone of upstream VLC; the redesign is shared only
through `patches/`, so they must stay in sync with the commits in `vlc/`.
After editing files in `vlc/`:

```sh
scripts/save.sh "qt: describe the change"   # or --amend to fold into the last vlc/ commit
```

It commits in `vlc/`, regenerates every file in `patches/` and stages them;
then commit this repo as usual.

## Status

Done: dark theme tokens, Inter font, icon font, player title bar, single-row
control bar (pill play button, inline seek bar, gradient volume), rounded
video stage, library title bar / side bar / inset content panel, fullscreen
window button, audio tracks button, music player view (rounded cover,
"title - artist" caption, skip buttons in the control bar), floating mini
player card in the library (video or cover, seek line, folder and artist),
player side panel (icon rail and play queue on the left of the video).

Not yet: library page headers (breadcrumbs, item count, search field),
library browsing inside the player side panel, settings window, onboarding,
dialogs, context menus, light theme, restyled tracks popup, remaining
icons (stop, repeat, shuffle, …).
