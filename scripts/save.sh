#!/usr/bin/env bash
# Commit the work in vlc/ and regenerate patches/ from it, so the patches
# always match the vlc/ commits. Committing this repo is left to you; the
# patches are not staged, so VS Code commits them together with everything else.
#   scripts/save.sh "qt: message"   commit vlc/ changes as a new commit
#   scripts/save.sh --amend         fold vlc/ changes into its last commit
#   scripts/save.sh                 only regenerate patches/ (vlc/ must be clean)
set -euo pipefail
source "$(dirname "$0")/env.sh"

AMEND=0
MESSAGE=""
for arg in "$@"; do
  case "$arg" in
    -a|--amend) AMEND=1 ;;
    -h|--help) sed -n '2,7p' "$0"; exit 0 ;;
    *) MESSAGE="$arg" ;;
  esac
done

VLC="$(to_native "$ROOT/vlc")"
git -C "$VLC" merge-base --is-ancestor "$VLC_BASE" HEAD ||
  { echo "vlc/ HEAD is not based on VLC_BASE ($VLC_BASE)" >&2; exit 1; }

if [ -n "$(git -C "$VLC" status --porcelain)" ]; then
  git -C "$VLC" add -A
  if [ "$AMEND" = 1 ]; then
    git -C "$VLC" commit -q --amend --no-edit
  elif [ -n "$MESSAGE" ]; then
    git -C "$VLC" commit -q -m "$MESSAGE"
  else
    git -C "$VLC" reset -q
    echo "vlc/ has uncommitted changes: pass a commit message or --amend" >&2
    exit 1
  fi
elif [ -n "$MESSAGE" ] || [ "$AMEND" = 1 ]; then
  echo "vlc/ has no changes to commit; regenerating patches only"
fi

# One patch per vlc/ commit since VLC_BASE, replacing what was there.
rm -f "$ROOT"/patches/*.patch
git -C "$VLC" format-patch -q --no-numbered "$VLC_BASE..HEAD" -o "$(to_native "$ROOT/patches")"
echo "patches/ regenerated from $(git -C "$VLC" rev-list --count "$VLC_BASE..HEAD") vlc/ commits:"
git -C "$(to_native "$ROOT")" status --short patches
