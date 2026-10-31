# Juxtopposed VLC Rebuild

[Juxtopposed's open-source VLC redesign]
Video: https://www.youtube.com/watch?v=ERFeOgqk324
Design File: https://www.figma.com/design/5UEUReDQz2dQjwoQDHY5z9/VLC-Redesign--Community-
implemented in VLC 4's real Qt/QML interface, as patches on top of upstream VLC.

The redesign itself is QML (Qt Quick) with some C++, in VLC's Qt interface
(`modules/gui/qt`). It lives in `patches/`, which GitHub does not count as code,
so the language bar only shows the helper scripts.

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
scripts/build.sh            # incremental after the first (~minutes) build; starts Docker Desktop if needed
powershell -File scripts/run.ps1 -Media dist/media/test-clip.mp4 -Shot shot.png
# extra VLC arguments: -Extra --no-audio,--start-time=30
```

Requires Docker (the build runs in VideoLAN's image) and Windows to run the
result. `vlc/` is a local clone of upstream VLC; the redesign is shared only
through `patches/`, so they must stay in sync with the commits in `vlc/`.
After editing files in `vlc/`:

```sh
scripts/save.sh "qt: describe the change"   # or --amend to fold into the last vlc/ commit
```

It commits in `vlc/` and regenerates every file in `patches/`; then commit this
repo as usual (the patches are left unstaged so everything goes into one
commit). If you commit `vlc/` from VS Code instead, run `scripts/save.sh` with
no arguments afterwards to export the patches.

## Status

Done: dark theme tokens, Inter font, icon font, player title bar, single-row
control bar (pill play button, inline seek bar, gradient volume), rounded
video stage, library title bar, fullscreen
window button, audio tracks button, music player view (rounded cover,
"title - artist" caption, skip buttons in the control bar), floating mini
player card in the library (video or cover, seek line, folder and artist),
player side panel (icon rail and play queue on the left of the video),
tracks popup as a floating menu card, player icons (stop, skip forward,
repeat, shuffle, mute, record, snapshot, info, chevrons, bookmark), library
page headers (back/forward, breadcrumb, item count, sort, view, inline search),
grid cards (rounder covers, 16px titles; video cards with a dimmed title and an
orange progress line inside the thumbnail once started), library side bar as
an inset rounded card on a single dark background, settings window rebuilt in
QML (13 categories, plain-language rows over VLC's options, info icons, search,
advanced options per category; the classic dialog stays reachable),
in-player quick settings sidebar (Playback, Video, Audio and Subtitles tabs
with live speed, delay, track, zoom, crop and deinterlacing controls),
keyboard shortcuts dialog (grouped hotkeys and global hotkeys, search by
field, press-a-key editing that frees conflicting keys, Save/Cancel; opened
from Settings > Controls or Tools > Keyboard Shortcuts, applies after restart),
menu styling (main, player and library menus as a rounded dark card with 48px
rows, muted text, dim separators and chevrons), player right-click menu laid
out as in the design (playback entries with their current hotkeys, Hide UI,
Playback/Video/Audio/Subtitle, More Settings, Playlist, Open Media, Quit VLC)
with the two-tone orange menu icons, library item menu in the design's order
and wording with its icons (Play, Mark as Watched, Favorites, Stream, Convert,
Add to Queue, Add to Playlist, Show in File Explorer, Properties & Metadata),
library playlist menu (Play, Shuffle, Add to Queue) and orange icons on the
playlist item, Browse and play queue menus.

Not yet: library browsing inside the player side panel, settings extras
(accent color, interface language, equalizer board, extensions list),
subtitle presets and timeline, onboarding, menu entries VLC has no action for
(Favorite and Export Playlist for playlists, Go to Source, Add/Edit Subtitle
and Audio Tracks, Resync), dialogs, light theme, library icons.
