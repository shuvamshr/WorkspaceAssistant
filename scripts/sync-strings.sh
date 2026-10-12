#!/bin/zsh
# Syncs each String Catalog from the .stringsdata the compiler emits, for command-line builds
# (Xcode does this automatically when building in the IDE).
# Usage: scripts/sync-strings.sh [derived-data-path]   (default: build/DD)
set -euo pipefail
cd "$(dirname "$0")/.."
DD=${1:-build/DD}
INTER="$DD/Build/Intermediates.noindex"

sync() {
  local catalog=$1 dir=$2
  local files=(${(f)"$(find "$dir" -name '*.stringsdata' 2>/dev/null)"})
  if (( ${#files} == 0 )); then echo "skip $catalog (no stringsdata; build first)"; return; fi
  xcrun xcstringstool sync "$catalog" --stringsdata "${files[@]}"
  echo "synced $catalog from ${#files} files"
}

for module in DesignSystem BoardFeature AssistantFeature SettingsFeature; do
  sync "Packages/WorkspaceKit/Sources/$module/Resources/Localizable.xcstrings" \
       "$INTER/WorkspaceKit.build/Debug-iphonesimulator/$module-t.build"
done
sync "WorkspaceAssistant/Localizable.xcstrings" "$INTER/WorkspaceAssistant.build/Debug-iphonesimulator/WorkspaceAssistant.build"
