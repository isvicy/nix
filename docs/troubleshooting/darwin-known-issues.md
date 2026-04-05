# Darwin Known Issues

## Tap-to-click requires reboot

nix-darwin sets `system.defaults.trackpad.Clicking = true` and writes to both
`com.apple.AppleMultitouchTrackpad` and `com.apple.driver.AppleBluetoothMultitouch.trackpad`.
The `activateSettings -u` activation script runs on rebuild, but the trackpad setting does not
take effect until a full reboot.

Related: https://github.com/nix-darwin/nix-darwin/issues/1207

## Setapp installed via Homebrew cannot log in

Setapp installed through `brew install --cask setapp` fails to authenticate.
Download and install from the official site (https://setapp.com) instead.
