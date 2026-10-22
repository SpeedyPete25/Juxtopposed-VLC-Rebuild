#!/usr/bin/env bash
# Build VLC for Windows (x86_64) inside VideoLAN's CI image and copy the
# runnable result to dist/vlc/.
#   scripts/build.sh          incremental build (full configure on first run)
#   scripts/build.sh --full   rerun contrib download + bootstrap + configure
set -euo pipefail
source "$(dirname "$0")/env.sh"

FULL=0
[ "${1:-}" = "--full" ] && FULL=1

mkdir -p "$ROOT/dist"

# Start Docker Desktop if its engine is not running yet (Windows).
if ! docker info >/dev/null 2>&1; then
  DOCKER_DESKTOP="/c/Program Files/Docker/Docker/Docker Desktop.exe"
  [ -x "$DOCKER_DESKTOP" ] || { echo "Docker is not running; start it and retry" >&2; exit 1; }
  echo "Starting Docker Desktop..."
  "$DOCKER_DESKTOP" >/dev/null 2>&1 &
  for _ in $(seq 60); do docker info >/dev/null 2>&1 && break; sleep 3; done
  docker info >/dev/null 2>&1 || { echo "Docker did not start in time" >&2; exit 1; }
fi

docker volume create "$VOLUME" >/dev/null

# A running test instance keeps dist/vlc's DLLs locked; stop only that one.
if command -v powershell >/dev/null; then
  powershell -NoProfile -Command "Get-Process vlc -ErrorAction SilentlyContinue |
    Where-Object { \$_.Path -like '$(cygpath -w "$ROOT/dist/vlc")*' } | Stop-Process -Force" || true
fi

# A VLC that hung while exiting can keep its DLLs locked even though it can no
# longer be stopped, which makes the copy below fail. Renaming still works, so
# move the old build aside and drop earlier ones once they are unlocked.
rm -rf "$ROOT"/dist/.vlc-old-* 2>/dev/null || true
[ -d "$ROOT/dist/vlc" ] && mv "$ROOT/dist/vlc" "$ROOT/dist/.vlc-old-$(date +%s)"

# Prebuilt contribs (Qt, ffmpeg, ...) published by VideoLAN's CI, keyed by the
# last commit touching contrib/. The container has no .git, so resolve it here.
CONTRIB_SHA="$(cd "$ROOT/vlc" && extras/ci/get-contrib-sha.sh win64)"
CONTRIBS_URL="https://artifacts.videolan.org/vlc/win64/vlc-contrib-x86_64-w64-mingw32-$CONTRIB_SHA.tar.zst"
# Same reason: VLC stamps its version from git, falling back to src/revision.txt.
VLC_REVISION="$(git -C "$(to_native "$ROOT/vlc")" describe --tags --long --match '?.*.*' --always)-juxt"

docker run --rm -u root \
  -v "$VOLUME":/build \
  -v "$(to_native "$ROOT/vlc")":/src:ro \
  -v "$(to_native "$ROOT/dist")":/dist \
  -e FULL="$FULL" \
  -e VLC_PREBUILT_CONTRIBS_URL="$CONTRIBS_URL" \
  -e VLC_REVISION="$VLC_REVISION" \
  "$IMAGE" bash -euo pipefail -c '
    # Copy sources into the volume, keeping mtimes so make stays incremental
    # (the image has no rsync).
    mkdir -p /build/vlc
    tar -C /src --exclude=./.git --exclude=./win64 --exclude=./contrib/win64 \
        --exclude=./contrib/x86_64-w64-mingw32 -cf - . | tar -C /build/vlc -xf -
    cd /build/vlc
    # Only rewrite on change so it does not trigger a rebuild every time.
    [ "$(cat src/revision.txt 2>/dev/null)" = "$VLC_REVISION" ] || echo "$VLC_REVISION" > src/revision.txt
    if [ "$FULL" = 1 ] || [ ! -f win64/config.status ]; then
      extras/package/win32/build.sh -a x86_64 -p -o /build/install
    else
      make -C win64 -j"$(nproc)"
      make -C win64 package-win-common
    fi
    rm -rf /dist/vlc && mkdir -p /dist/vlc
    cp -a /build/install/. /dist/vlc/
    # Portable mode: VLC keeps config, media library and cache in here instead
    # of %APPDATA%\vlc, so test runs never touch an installed VLC.
    mkdir -p /dist/vlc/portable
    echo "Built: dist/vlc/vlc.exe"
  '
