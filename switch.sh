#!/usr/bin/env bash
# Auto-detect system and switch Home Manager configuration
# Works on both Mac and Linux

# Detect system using uname (more reliable than nix eval)
ARCH=$(uname -m)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

if [ "$OS" = "darwin" ]; then
  if [ "$ARCH" = "arm64" ]; then
    SYSTEM="aarch64-darwin"
  else
    SYSTEM="x86_64-darwin"
  fi
else
  SYSTEM="x86_64-linux"
fi

# Use system-specific configuration
home-manager switch --flake ".#${SYSTEM}"
