#!/bin/zsh
# Syncs the String Catalog from the .stringsdata the compiler emits, for command-line builds
# (Xcode does this automatically when building in the IDE).
# Usage: scripts/sync-strings.sh [derived-data-path]   (default: build/DD)
set -euo pipefail
cd "$(dirname "$0")/.."
DD=${1:-build/DD}
DIR="$DD/Build/Intermediates.noindex/WorkspaceAssistant.build/Debug-iphonesimulator/WorkspaceAssistant.build"
files=(${(f)"$(find "$DIR" -name '*.stringsdata' 2>/dev/null)"})
if (( ${#files} == 0 )); then echo "No stringsdata found; build first."; exit 1; fi
xcrun xcstringstool sync WorkspaceAssistant/Resources/Localizable.xcstrings --stringsdata "${files[@]}"
echo "Synced WorkspaceAssistant/Resources/Localizable.xcstrings from ${#files} files"
