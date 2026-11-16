# Shared helpers for the scripts in tools/. Source it; don't run it.
# Requires bash 3.2+, git, rsync and jq (all shipped with current macOS).

HERDR_HOME="${HERDR_APP_HOME:-$HOME/.config/herdr-app}"
REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

# Where the tools keep their logs, staging copy, backups, lock and installed release.
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/herdr-jnaO-desktop-theme"

# The theme is one layout; the mods and colour themes it ships are found by
# following references from it.
THEME_LAYOUT=jnaO

# Herdr's built-in colour themes: never shipped as files.
HERDR_PRESETS="graphite ink moss paper"

# Herdr-generated files inside a mod folder; never copied.
RSYNC_EXCLUDES=(--exclude '*.d.ts' --exclude 'jsconfig.json' --exclude '.DS_Store')

die() { echo "$(basename "$0"): $*" >&2; exit 1; }

need() { command -v "$1" >/dev/null 2>&1 || die "needs '$1' on PATH"; }

# cloned_from.<field> of a mod.json or layout file ("" when not a clone).
cloned_from() { jq -r --arg f "$2" '.cloned_from[$f] // empty' "$1" 2>/dev/null; }

# Mod names referenced from stdin: "mod": "x", mod: "x", "terminal_menu": "x".
mod_refs() { grep -oE '("mod"|mod|"terminal_menu") *: *"[^"]+"' | sed -E 's/.*"([^"]+)"$/\1/'; }

# Colour theme files the layout's root "theme" names (a name or {light, dark}).
theme_colors() {
  local n
  for n in $(jq -r '.theme | if type == "object" then .[] elif type == "string" then . else empty end' \
      "$1/layouts/$THEME_LAYOUT.json" | sort -u); do
    case " $HERDR_PRESETS " in *" $n "*) ;; *) echo "$n" ;; esac
  done
}

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

# --- Applying a theme to the live home (tools/sync, tools/update) -------------

# One run at a time across the tools: a mkdir lock in the state folder, removed
# on exit. Returns 1 when another run holds it.
take_lock() {
  mkdir -p "$STATE_DIR"
  mkdir "$STATE_DIR/lock" 2>/dev/null || return 1
  trap 'rmdir "$STATE_DIR/lock" 2>/dev/null || true' EXIT
}

log_outcome() { echo "$(date '+%Y-%m-%d %H:%M:%S') $2 $3: $4" >> "$1"; } # <log> <outcome> <subject> <message>

# Outcome: a log line and, where possible, a macOS notification titled
# "jnaO theme <tool>: <outcome>".
notify() { # <log> <outcome> <subject> <message>
  log_outcome "$@"
  if command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"$4 Log: ${1/#$HOME/~}\" with title \"jnaO theme $(basename "$0"): $2\"" >/dev/null 2>&1 || true
  fi
}

# Copies the named mods, the layout and its colour theme from the live home into
# a new $STATE_DIR/backups/<timestamp>/ and sets BACKUP to it. mods.txt lists
# every named mod, held or not; release holds $STATE_DIR/release. The newest
# five backups are kept.
backup_theme() { # <mods…>
  local m f
  mkdir -p "$STATE_DIR/backups"
  BACKUP="$STATE_DIR/backups/$(date +%Y%m%d-%H%M%S)"
  f=$BACKUP
  m=1
  while ! mkdir "$BACKUP" 2>/dev/null; do BACKUP="$f-$m"; m=$((m + 1)); done
  mkdir -p "$BACKUP/mods" "$BACKUP/layouts" "$BACKUP/themes"
  : > "$BACKUP/mods.txt"
  for m in "$@"; do
    echo "$m" >> "$BACKUP/mods.txt"
    if [ -d "$HERDR_HOME/mods/$m" ]; then cp -Rp "$HERDR_HOME/mods/$m" "$BACKUP/mods/"; fi
  done
  for f in "layouts/$THEME_LAYOUT.json" "themes/$THEME_LAYOUT.json"; do
    if [ -f "$HERDR_HOME/$f" ]; then cp -p "$HERDR_HOME/$f" "$BACKUP/$f"; fi
  done
  { cat "$STATE_DIR/release" 2>/dev/null || true; } > "$BACKUP/release"
  ls -1d "$STATE_DIR/backups"/*/ | sort -r | tail -n +6 | while read -r f; do rm -rf "$f"; done
}

# Puts a backup_theme folder back: every mod in its mods.txt, the layout and the
# colour theme are removed from the live home, then the ones it holds are copied in.
restore_theme() { # <backup>
  local m f
  while read -r m; do
    [ -n "$m" ] || continue
    rm -rf "$HERDR_HOME/mods/$m"
    if [ -d "$1/mods/$m" ]; then cp -Rp "$1/mods/$m" "$HERDR_HOME/mods/"; fi
  done < "$1/mods.txt"
  for f in "layouts/$THEME_LAYOUT.json" "themes/$THEME_LAYOUT.json"; do
    rm -f "$HERDR_HOME/$f"
    if [ -f "$1/$f" ]; then cp -p "$1/$f" "$HERDR_HOME/$f"; fi
  done
}

# herdr-app check on each named live mod, then herdr-app status .errors after
# the hot reload (skipped when no window answers). Prints one line per failure;
# returns 1 on any.
live_check() { # <mods…>
  local m out status errors ok=0
  for m in "$@"; do
    if ! out=$(herdr-app check "$HERDR_HOME/mods/$m" 2>&1); then
      ok=1; echo "LIVE CHECK FAILED $m: $(echo "$out" | head -3 | tr '\n' ' ')"
    fi
  done
  sleep 2
  if status=$(herdr-app status 2>/dev/null); then
    errors=$(echo "$status" | jq -r '.errors | length' 2>/dev/null || echo 0)
    if [ "${errors:-0}" != 0 ]; then ok=1; echo "herdr-app status reports errors: $(echo "$status" | jq -c .errors)"; fi
  fi
  return $ok
}
