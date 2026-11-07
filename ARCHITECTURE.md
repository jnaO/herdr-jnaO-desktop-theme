# Architecture

A Herdr desktop theme (layout, mods, colour theme) laid out like the Herdr home, plus bash tooling that copies it in and out of the home and re-merges it onto new Herdr releases.

**Where planning lives:** GitHub issues on this repo — a Story per piece of work, its steps as Task sub-issues.

**Drill-downs live in the wiki**, under the sidebar's **agent-docs** section, not in a local `.agent-docs/` folder:

| Page | Read it before touching |
|---|---|
| [Theme composition](https://github.com/jnaO/herdr-jnaO-desktop-theme/wiki/Theme-composition) | what counts as the theme, export/install/snapshot rules, Herdr constraints (no overrides, flat mods, clone renames) |
| [Sync engine](https://github.com/jnaO/herdr-jnaO-desktop-theme/wiki/Sync-engine) | `tools/sync`: trigger, 3-way merge rules, apply/rollback, state folder, rehearsals |
| [Privacy gate](https://github.com/jnaO/herdr-jnaO-desktop-theme/wiki/Privacy-gate) | `tools/privacy-check`, the hook and CI; anything that could publish a path |

The wiki is its own git repo (`herdr-jnaO-desktop-theme.wiki.git`); edit pages there and keep this map's links in step.

## Tree

```
layouts/jnaO.json          THE theme root; every mod and colour theme is found from it
mods/jnao-*/               cloned Herdr mods (flat: folder name = mod name)
  jnao-spaces/machine.js   machine glyph/tint/header helper; identical copy in jnao-agents/
themes/jnaO.json           the layout's own colour theme (named like the layout)
keys.json                  reference key bindings; install never overwrites the user's
upstream/                  unmodified Herdr sources the clones were built from = merge base
  manifest.json            Herdr version + installed.json hashes of those sources
assets/banner.svg          README / wiki banner
tools/lib.sh               shared paths and theme discovery; sourced by every tool
tools/export               Herdr home → repo (mirror; version-guarded)
tools/install              repo → Herdr home (keeps keys.json and foreign same-named themes)
tools/snapshot-upstream    shipped sources → upstream/ (--from <home> for rehearsals)
tools/radius               2px corner rule over mod .js files; idempotent
tools/sync                 re-merge onto a new Herdr release; --dry-run stages only
tools/privacy-check        public-repo gate: path forms, $HOME, hostname, git email
tools/hooks/pre-commit     runs privacy-check --staged (core.hooksPath tools/hooks)
.github/workflows/privacy.yml  privacy-check on push and PR
LICENSE, NOTICE            Apache-2.0; NOTICE credits Herdr for mods/, layouts/, upstream/
```

## Shared helpers (`tools/lib.sh`)

| Symbol | Gives |
|---|---|
| `HERDR_HOME` | `$HERDR_APP_HOME`, else `~/.config/herdr-app` |
| `REPO_ROOT` | the repo, from the script's own location |
| `THEME_LAYOUT` | the one place the theme name lives |
| `theme_mods <home>` | every cloned mod reachable from the layout (layout refs, then `mod: "…"` refs inside mods) |
| `theme_colors <home>` | colour themes the layout's `theme` names, minus Herdr presets |
| `cloned_from <json> <field>` | `name` / `version` of a clone, empty when not a clone |
| `RSYNC_EXCLUDES` | Herdr-generated files never copied (`*.d.ts`, `jsconfig.json`) |

## Patterns

- **Live home is the editing surface, the repo is the published copy.** Change mods in the Herdr home (hot reload), then `tools/export`. Never edit `mods/` in the repo and expect Herdr to see it without `tools/install`.
- **Discover, don't list.** Mods and colour themes come from the layout; adding a mod means referencing it from the layout or a theme mod, never adding it to a list.
- **No absolute paths in anything committed.** Paths resolve at run time; `tools/privacy-check` enforces it.
- **Every modified Herdr `.js` file carries the `// Modified from Herdr's "<src>" mod` header**, in the live home too.
