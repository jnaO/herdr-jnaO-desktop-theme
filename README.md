# herdr-jnaO-desktop-theme

A desktop theme for the [Herdr](https://herdr.dev) app: the `jnaO` layout, its `jnao-*` mods, the `ghostty` and `tokyo-night` colour themes and a reference `keys.json`, plus tooling that re-applies the theme on top of every Herdr update.

The repo is laid out like the Herdr home folder, so `layouts/`, `mods/` and `themes/` can be copied straight into it. Tooling lives in `tools/` and the Herdr sources the mods were built from live in `upstream/`; neither is part of the theme itself.

## Install

```sh
git clone https://github.com/jnaO/herdr-jnaO-desktop-theme.git
cd herdr-jnaO-desktop-theme
tools/install
```

`tools/install` copies the layout, mods, themes and `keys.json` into the Herdr home: `$HERDR_APP_HOME` if set, otherwise `~/.config/herdr-app`. It replaces the layout and the `jnao-*` mods, but never overwrites an existing `keys.json` or a colour theme of the same name; it prints what it skipped. Then pick the layout in Herdr under Settings → Look → jnaO, or run `herdr-app do layout.switch --name jnaO`.

To uninstall, delete `layouts/jnaO.json` and the `mods/jnao-*` folders from the Herdr home.

The tools need bash, git, rsync and jq, which current macOS ships with.

## Working on the theme

Edit the mods in the Herdr home, where Herdr reloads them as you save, then copy them into the repo:

```sh
tools/export
```

`tools/export` mirrors the theme from the Herdr home into the repo: the `jnaO` layout, every cloned mod it uses (directly, or opened by another theme mod), the colour themes and `keys.json`. It leaves out files Herdr generates (`*.d.ts`, `jsconfig.json`), and a file deleted in the Herdr home is deleted in the repo. It refuses to run when a mod was cloned from a different Herdr version than the one in `upstream/manifest.json`.

`tools/snapshot-upstream` copies the shipped Herdr sources the theme was cloned from into `upstream/`, and records the Herdr version and their file hashes in `upstream/manifest.json`. Those sources are the base the update sync merges against.

`tools/radius <mod dir>...` sets every corner the mods draw to 2px: it rewrites `.rounded(N)` with N of 3 or more to `.rounded(2)`, leaving status dots, rings and the Herdr logo round. Running it again changes nothing.

Each modified Herdr file starts with a line naming the Herdr mod it came from, as the Apache licence asks.

## Privacy gate

The repo is public, so every commit passes `tools/privacy-check`. It fails when a file contains a home-folder path (macOS, Linux or Windows form), the value of `$HOME`, this machine's local hostname or the git user email. It does not look for the login name, because the theme's own `jnao-*` names would match it. The check runs:

- as a pre-commit hook: run `git config core.hooksPath tools/hooks` once after cloning;
- in GitHub Actions on every push and pull request, where only the path forms apply;
- by hand: `tools/privacy-check`.

## Licence

Apache-2.0. The mods and layout are modified from Herdr's own, which is Apache-2.0; see `NOTICE`.
