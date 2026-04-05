hostname := `hostname`

# NixOS: full system rebuild
nixos host=hostname:
  sudo nixos-rebuild switch --flake .#{{host}}

# NixOS: build only (no switch)
nixos-build host=hostname:
  nixos-rebuild build --flake .#{{host}}

# NixOS: test (activates but doesn't persist across reboot)
nixos-test host=hostname:
  sudo nixos-rebuild test --flake .#{{host}}

# Darwin: full system rebuild
darwin host=hostname:
  nix build .#darwinConfigurations.{{host}}.system \
    --extra-experimental-features 'nix-command flakes'
  sudo ./result/sw/bin/darwin-rebuild switch --flake .#{{host}}

# Darwin: build with debug output
darwin-debug host=hostname:
  nix build .#darwinConfigurations.{{host}}.system --show-trace --verbose \
    --extra-experimental-features 'nix-command flakes'
  sudo ./result/sw/bin/darwin-rebuild switch --flake .#{{host}} --show-trace --verbose

# Home Manager: standalone switch (ubuntu hosts)
home:
  home-manager switch --flake .

# Update all flake inputs
update:
  nix flake update

# Format all nix files
fmt:
  nix fmt

# Show profile history
history:
  nix profile history --profile /nix/var/nix/profiles/system

# Garbage collect (NixOS)
gc:
  sudo nix-collect-garbage --delete-older-than 30d

# Garbage collect (Darwin)
gc-darwin:
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 7d
  sudo nix store gc --debug

# Clean build artifacts
clean:
  rm -rf result
