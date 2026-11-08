#!/bin/sh
# Sillok NA16, v1.0.0. Canonical source: aipm/scripts/native_artifact_guard.sh.
# Vendored byte-for-byte into app repositories; no sibling repo/runtime dependency.
# A hidden .noindex physical directory protects both ordinary LS discovery and
# Spotlight. The original path remains a relative symlink for build/restore tools.
# Explicit launch or lsregister -R can still register a bundle; audit separately.
set -eu
command=${1:?usage: native_artifact_guard.sh prepare|check|protect-temp DIRECTORY}
input=${2:?missing artifact directory}
if [ "$command" = check-install ]; then
    [ "$input" = "${3:?missing canonical install path}" ] && [ ! -L "$input" ] && [ ! -L "${input%/*}" ] || {
        echo 'Refusing a noncanonical or symlink install destination' >&2; exit 2;
    }
    exit 0
fi
case "$command" in prepare|check|protect-temp) ;; *) echo 'Unknown artifact guard command' >&2; exit 2 ;; esac
case "$input" in /*) ;; *) echo 'Artifact directory must be absolute' >&2; exit 2 ;; esac
input=${input%/}
name=${input##*/}
parent=${input%/*}
case "$name" in ''|.|..|Applications|'Input Methods'|Sources|Contents|Library|GitHub|*.app|*.app.*)
    echo 'Refusing source, install, or application bundle directory' >&2; exit 2 ;;
esac
case "$input/" in *.app/*) echo 'Refusing a path inside an app bundle' >&2; exit 2 ;; esac
[ "$input" != "${HOME:-/}" ] || { echo 'Refusing home directory' >&2; exit 2; }
[ ! -e "$input/.git" ] || { echo 'Refusing repository root' >&2; exit 2; }
if [ "$command" = prepare ]; then mkdir -p "$parent"; fi
[ -d "$parent" ] || exit 1
parent=$(CDPATH= cd -P -- "$parent" && pwd)
tree="$parent/$name"
if [ "$command" = protect-temp ]; then
    case "$name" in .*.noindex) ;; *) echo 'Temporary stage must be a dot-prefixed .noindex directory' >&2; exit 2 ;; esac
    [ -d "$tree" ] && [ ! -L "$tree" ] || { echo 'Temporary stage must be a real directory' >&2; exit 2; }
    [ "$(uname -s)" != Darwin ] || chflags hidden "$tree"
    exit 0
fi
physical="$parent/.$name.noindex"
expected=".$name.noindex"

valid_link() {
    [ -L "$tree" ] && [ "$(readlink "$tree")" = "$expected" ] &&
        [ -d "$physical" ] && [ ! -L "$physical" ]
}
check_hidden() {
    [ "$(uname -s)" != Darwin ] || [ $(( $(stat -f %f "$physical") & 32768 )) -ne 0 ]
}
if [ "$command" = check ]; then
    valid_link && check_hidden || { echo "Unprotected artifact directory: $tree" >&2; exit 1; }
    exit 0
fi
lock="$parent/.$name.artifact-guard.lock"
mkdir "$lock" 2>/dev/null || { echo "Artifact directory is busy: $tree" >&2; exit 1; }
trap 'rmdir "$lock"' EXIT
trap 'exit 130' HUP INT TERM
if [ -L "$tree" ]; then
    valid_link || { echo 'Refusing unexpected artifact symlink' >&2; exit 1; }
elif [ -e "$physical" ] || [ -L "$physical" ]; then
    echo 'Refusing to merge colliding artifact directories' >&2; exit 1
else
    [ ! -e "$tree" ] || [ -d "$tree" ] || { echo 'Artifact path is not a directory' >&2; exit 1; }
    [ ! -e "$tree/.build.lock" ] || { echo 'An app build holds this directory' >&2; exit 1; }
    # A running development app must not be relocated. No process is stopped.
    if [ -d "$tree" ] && ps -axww -o comm= | (
        while IFS= read -r executable; do
            case "$executable" in "$tree"/*) exit 0 ;; esac
        done
        exit 1
    ); then
        echo 'Refusing to move artifacts containing a running executable' >&2; exit 1
    fi
    if [ -d "$tree" ]; then mv -- "$tree" "$physical"; else mkdir "$physical"; fi
    # On any setup failure restore the original location. Rename preserves all
    # bundle bytes, signatures, timestamps, xattrs and inode identities.
    if [ "$(uname -s)" = Darwin ] && ! chflags hidden "$physical"; then
        mv -- "$physical" "$tree"; exit 1
    fi
    if ! ln -s "$expected" "$tree"; then
        [ "$(uname -s)" != Darwin ] || chflags nohidden "$physical"
        mv -- "$physical" "$tree"; exit 1
    fi
fi
[ "$(uname -s)" != Darwin ] || chflags hidden "$physical"
valid_link && check_hidden || exit 1
printf '%s\n' "$physical"
