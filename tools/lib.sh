# Shared helpers for the scripts in tools/. Source it; don't run it.
# Requires bash 3.2+, git, rsync and jq (all shipped with current macOS).

HERDR_HOME="${HERDR_APP_HOME:-$HOME/.config/herdr-app}"
REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

# The theme: one layout, the colour themes it ships, and everything else it
# needs is found by following mod references from the layout.
THEME_LAYOUT=jnaO
THEME_COLORS="ghostty tokyo-night"

# Herdr-generated files inside a mod folder; never copied.
RSYNC_EXCLUDES=(--exclude '*.d.ts' --exclude 'jsconfig.json' --exclude '.DS_Store')

die() { echo "$(basename "$0"): $*" >&2; exit 1; }

need() { command -v "$1" >/dev/null 2>&1 || die "needs '$1' on PATH"; }

# cloned_from.<field> of a mod.json or layout file ("" when not a clone).
cloned_from() { jq -r --arg f "$2" '.cloned_from[$f] // empty' "$1" 2>/dev/null; }

# Mod names referenced from stdin: "mod": "x", mod: "x", "terminal_menu": "x".
mod_refs() { grep -oE '("mod"|mod|"terminal_menu") *: *"[^"]+"' | sed -E 's/.*"([^"]+)"$/\1/'; }

# Every cloned mod the theme layout uses, directly or through another such mod.
theme_mods() {
  local home=$1 queue found=" " n
  queue=$(mod_refs < "$home/layouts/$THEME_LAYOUT.json" | tr '\n' ' ')
  while [ -n "${queue// /}" ]; do
    set -- $queue; n=$1; shift; queue="$*"
    case "$found" in *" $n "*) continue ;; esac
    [ -n "$(cloned_from "$home/mods/$n/mod.json" name)" ] || continue
    found="$found$n "
    queue="$queue $(cat "$home/mods/$n"/*.js | mod_refs | tr '\n' ' ')"
  done
  echo $found
}
