#!/bin/bash
# macOS system settings
# Run: ./macos.sh
# Some changes require logout or restart to take effect.

set -e

echo "Applying macOS settings..."

# ====================
# Mission Control
# ====================

# Disable "Switch to Desktop N" shortcuts (ctrl+1/2/3/...)
# These conflict with AeroSpace workspace switching
for key in 118 119 120 121 122 123 124 125 126 127; do
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$key" '{ enabled = 0; value = { parameters = (0, 0, 0); type = standard; }; }'
done

# Disable "Displays have separate Spaces" (recommended for AeroSpace)
defaults write com.apple.spaces spans-displays -bool true

echo "Done. Some changes may require logout or restart."
