# Machine setup inventory

`packages/pacman-explicit.txt` is the explicit official-package list. Install it on a fresh Arch system with:

```bash
sudo pacman -S --needed - < packages/pacman-explicit.txt
```

`packages/aur-explicit.txt` lists explicit AUR packages; install them with `yay -S --needed - < packages/aur-explicit.txt` after installing `yay`.

This repository intentionally excludes credentials, browser/editor profiles, caches, package caches, game data, and application databases.
