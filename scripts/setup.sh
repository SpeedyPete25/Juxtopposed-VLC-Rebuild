#!/usr/bin/env bash
# Clone VLC at the pinned commit and apply the redesign patches from patches/.
set -euo pipefail
source "$(dirname "$0")/env.sh"

if [ ! -d "$ROOT/vlc/.git" ]; then
  git clone "$VLC_REPO" "$(to_native "$ROOT/vlc")"
fi
cd "$ROOT/vlc"
# The Docker build needs LF endings even on Windows.
git config core.autocrlf false
git config core.eol lf
git checkout -q -B juxtopposed-redesign "$VLC_BASE"
git am "$(to_native "$ROOT")"/patches/*.patch
echo "vlc/ is on juxtopposed-redesign; run scripts/build.sh"
