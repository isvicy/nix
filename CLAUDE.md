# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal NixOS configuration using Nix Flakes and Home Manager. Manages system configs for multiple hosts (primarily `rog` — ASUS ROG laptop with NVIDIA GPU, Niri Wayland compositor).

## Commands

```bash
# Apply full system configuration (NixOS + Home Manager)
sudo nixos-rebuild switch --flake .#rog

# Apply home-manager only (faster, no sudo)
home-manager switch --flake .#isvicy

# Test config without persisting (safe for experiments)
sudo nixos-rebuild test --flake .#rog

# Format all Nix files (uses alejandra)
nix fmt

# Lint
statix check

# Build without switching (check for eval errors)
nixos-rebuild build --flake .#rog

# Update all flake inputs
nix flake update

# Update single input
nix flake update nixpkgs
```

## Architecture

### Entry Point: `flake.nix`

Two helper functions create configurations:
- `mkNixosConfiguration` — full NixOS system config (includes Home Manager as a NixOS module)
- `mkHomeConfiguration` — standalone Home Manager config (for non-NixOS hosts like WSL)

Both automatically import `users/${username}/home.nix` and apply overlays from `nixpkgsWithOverlays`.

### Overlays

All overlays live in `flake.nix` under `nixpkgsWithOverlays`. This is where packages are customized:
- `pkgs.unstable` namespace for nixos-unstable packages
- Custom packages from `pkgs/` (e.g., confirmo)
- App wrapping for Wayland compatibility (e.g., Feishu with `--ozone-platform=wayland`)
- Third-party flake overlays (niri unstable)

### Module Layers

**System level (`modules/`)** — NixOS modules imported by host configs:
- `options.nix` defines custom toggles under `custom.*` namespace (e.g., `custom.nvidia.enable`)
- `system.nix` is the core config (user, locale, fonts, nix settings, nix-ld)
- Feature modules use `lib.mkIf` with custom options for conditional enabling
- Subdirectories: `desktop/`, `im/`, `nvidia/`, `virtualization/`

**User level (`home/`)** — Home Manager modules:
- `core.nix` — base home-manager settings
- `programs/common.nix` — the main user package list (LSPs, dev tools, apps)
- `programs/browser.nix`, `programs/terminal.nix` — specialized program configs
- `desktop/niri.nix` — Niri compositor user config (keybindings, window rules)

**Hosts (`hosts/`)** — machine-specific configs that import system modules:
- `rog/` — primary host, imports most modules
- `nixos-wsl/` — minimal WSL config

**Users (`users/`)** — per-user Home Manager entry points:
- `users/isvicy/home.nix` imports from `home/` modules

### Custom Packages (`pkgs/`)

Custom derivations called via overlays in `flake.nix`. Typically packages from `.deb` files using `autoPatchelfHook`. Update script: `scripts/update-pkg.sh`.

### Where to Make Common Changes

| Task | File |
|------|------|
| Add a user package | `home/programs/common.nix` |
| Add/wrap a package via overlay | `flake.nix` (`nixpkgsWithOverlays`) |
| Add a host-specific service | `hosts/<host>/default.nix` |
| Add a system-level module | `modules/` then import in host config |
| Add a new custom option | `modules/options.nix` |
| Configure Niri keybindings/rules | `home/desktop/niri.nix` |

### Notable Patterns

- Electron apps that need Wayland support on Niri require explicit `--ozone-platform=wayland` wrapping via overlay (the `NIXOS_OZONE_WL=1` env var only works with NixOS's standard Electron wrapper)
- Input method (fcitx5/Rime) needs `--enable-wayland-ime --wayland-text-input-version=3` flags on Electron apps
- `docs/troubleshooting/` contains dated investigation logs for resolved issues
