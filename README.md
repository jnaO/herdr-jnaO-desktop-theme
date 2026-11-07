# herdr-jnaO-desktop-theme

A desktop theme for the [Herdr](https://herdr.dev) app: the `jnaO` layout, its `jnao-*` mods, the `ghostty` and `tokyo-night` colour themes and a reference `keys.json`, plus tooling that re-applies the theme on top of every Herdr update.

The repo is laid out like the Herdr home folder, so `layouts/`, `mods/` and `themes/` can be copied straight into it. Tooling lives in `tools/` and the Herdr sources the mods were built from live in `upstream/`; neither is part of the theme itself.

## Privacy gate

The repo is public, so every commit passes `tools/privacy-check`. It fails when a file contains a home-folder path (macOS, Linux or Windows form), the value of `$HOME`, this machine's local hostname or the git user email. It does not look for the login name, because the theme's own `jnao-*` names would match it. The check runs:

- as a pre-commit hook: run `git config core.hooksPath tools/hooks` once after cloning;
- in GitHub Actions on every push and pull request, where only the path forms apply;
- by hand: `tools/privacy-check`.

## Licence

Apache-2.0. The mods and layout are modified from Herdr's own, which is Apache-2.0; see `NOTICE`.
