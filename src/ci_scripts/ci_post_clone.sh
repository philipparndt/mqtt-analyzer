#!/bin/bash
set -e
cd "$(dirname "$0")/.."

export HOMEBREW_NO_INSTALL_CLEANUP=true

brew install cocoapods
pod install
