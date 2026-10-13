#!/usr/bin/env bash
# Regenerate VLC's icon font (VLCIcons.ttf) from the Figma icons mapped in
# scripts/icons/mapping.json.
set -euo pipefail
source "$(dirname "$0")/env.sh"

docker build -q -t juxt-vlc-icons "$(to_native "$ROOT/scripts/icons")" >/dev/null
docker run --rm \
  -v "$(to_native "$ROOT/vlc")":/vlc \
  -v "$(to_native "$ROOT/design")":/design:ro \
  -v "$(to_native "$ROOT/scripts")":/scripts:ro \
  juxt-vlc-icons python3 /scripts/icons/make_icons.py
