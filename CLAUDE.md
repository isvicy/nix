# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal NixOS configuration repository using Nix Flakes and Home Manager. It manages system configurations for multiple hosts and provides a modular approach to system configuration.

## Common Development Commands

### System Management
```bash
# Apply system configuration changes
sudo nixos-rebuild switch --flake .#rog

# Test configuration without switching
sudo nixos-rebuild test --flake .#rog

# Apply home-manager configuration
home-manager switch --flake .#isvicy

# Show available configurations
nix flake show
```

### Development Workflow
```bash
# Format all Nix files
nix fmt

# Lint Nix files
statix check

# Update flake inputs
nix flake update

# Update specific input
nix flake update nixpkgs

# Check flake configuration
nix flake check
```

### Debugging
```bash
# Build configuration without switching
nixos-rebuild build --flake .#rog

# Evaluate specific attribute
nix eval .#nixosConfigurations.rog.config.system.build.toplevel

# Show derivation info
nix show-derivation .#nixosConfigurations.rog.config.system.build.toplevel
```

## Architecture

The repository follows a modular structure:

- **flake.nix**: Entry point defining inputs, outputs, and helper functions (`mkNixOS`, `mkHM`, `mkHost`)
- **hosts/**: Machine-specific configurations
  - Each host has its own directory with hardware-specific settings
  - Currently supports: `rog` (gaming laptop), `nixos-wsl` (WSL environment)
- **modules/**: Reusable system modules
  - Core system settings, hardware support, desktop environments, virtualization
  - Key modules include GPU passthrough setup for Windows VMs
- **home/**: Home Manager modules for user-level configuration
  - Programs, dotfiles, and user environment setup
- **users/**: User-specific configurations (currently only `isvicy`)

### Key Design Patterns

1. **Modular Configuration**: Each feature is in its own module file for easy toggling
2. **Host Abstraction**: The `mkHost` function in flake.nix creates both NixOS and Home Manager configurations for a host
3. **Separation of Concerns**: System-level (NixOS) and user-level (Home Manager) configs are clearly separated
4. **Flake-based**: Uses modern Nix flakes for reproducible builds and better dependency management

### Important Configuration Details

- NixOS version: 25.05
- Default user: isvicy
- Primary host: rog (ASUS ROG laptop with NVIDIA GPU)
- Features GPU passthrough for Windows 11 VMs
- Uses Niri as the primary Wayland compositor
- Extensive development environment setup including multiple compilers and build tools