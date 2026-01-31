#!/usr/bin/env bash
set -euo pipefail

# Usage: ./update-pkg.sh <package-name>
# Updates a package in pkgs/ by fetching the latest GitHub release

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Package configurations: name -> "owner/repo asset_pattern"
declare -A PACKAGES=(
    ["confirmo"]="yetone/confirmo-releases confirmo_VERSION_amd64.deb"
)

update_package() {
    local pkg_name="$1"
    local pkg_file="$REPO_ROOT/pkgs/${pkg_name}.nix"

    if [[ ! -f "$pkg_file" ]]; then
        echo "Error: Package file not found: $pkg_file"
        exit 1
    fi

    if [[ ! -v "PACKAGES[$pkg_name]" ]]; then
        echo "Error: Unknown package: $pkg_name"
        echo "Available packages: ${!PACKAGES[*]}"
        exit 1
    fi

    IFS=' ' read -r github_repo asset_pattern <<< "${PACKAGES[$pkg_name]}"

    echo "Checking latest release for $github_repo..."

    # Get latest release info from GitHub API
    local release_info
    release_info=$(curl -sL "https://api.github.com/repos/${github_repo}/releases/latest")

    local latest_version
    latest_version=$(echo "$release_info" | jq -r '.tag_name' | sed 's/^v//')

    if [[ -z "$latest_version" || "$latest_version" == "null" ]]; then
        echo "Error: Could not fetch latest version"
        exit 1
    fi

    # Get current version from nix file
    local current_version
    current_version=$(grep -oP 'version = "\K[^"]+' "$pkg_file")

    echo "Current version: $current_version"
    echo "Latest version:  $latest_version"

    if [[ "$current_version" == "$latest_version" ]]; then
        echo "Already up to date!"
        exit 0
    fi

    # Construct download URL
    local asset_name="${asset_pattern//VERSION/$latest_version}"
    local download_url="https://github.com/${github_repo}/releases/download/v${latest_version}/${asset_name}"

    echo "Fetching hash for: $download_url"

    # Get the hash using nix-prefetch-url
    local hash_base32
    hash_base32=$(nix-prefetch-url --type sha256 "$download_url" 2>/dev/null)

    if [[ -z "$hash_base32" ]]; then
        echo "Error: Could not fetch package"
        exit 1
    fi

    # Convert to SRI format
    local hash_sri
    hash_sri=$(nix hash convert --to sri --hash-algo sha256 "$hash_base32")

    echo "New hash: $hash_sri"

    # Update the nix file
    sed -i "s/version = \"${current_version}\"/version = \"${latest_version}\"/" "$pkg_file"
    sed -i "s|hash = \"sha256-[^\"]*\"|hash = \"${hash_sri}\"|" "$pkg_file"

    echo ""
    echo "Updated $pkg_name: $current_version -> $latest_version"
    echo ""
    echo "To apply: home-manager switch --flake .#isvicy"
}

# Main
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <package-name>"
    echo ""
    echo "Available packages:"
    for pkg in "${!PACKAGES[@]}"; do
        echo "  - $pkg"
    done
    exit 1
fi

update_package "$1"
