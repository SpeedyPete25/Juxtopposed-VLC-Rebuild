# Shared settings for the build scripts.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VLC_REPO="https://code.videolan.org/videolan/vlc.git"
# Upstream commit the patches in patches/ apply on top of.
VLC_BASE="1176b56bdef7b96c9d6518b62be37ec8c32d92ed"
IMAGE="registry.videolan.org/vlc-debian-win64-posix:20260611225331"
VOLUME="juxt-vlc-build"
# Docker on Windows wants a native path for bind mounts.
to_native() { if command -v cygpath >/dev/null; then cygpath -m "$1"; else echo "$1"; fi; }
export MSYS_NO_PATHCONV=1
