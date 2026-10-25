#!/bin/bash
# Pixel Hollow Knight [Animated] - Vivaldi JS mod installer (macOS)
# Adds hk-tab-animations.js to Vivaldi. Run it again after every Vivaldi update.
# To remove it: ./install-js-mod.sh --uninstall

set -euo pipefail

uninstall=0
[[ "${1:-}" == "--uninstall" ]] && uninstall=1

mod_name='hk-tab-animations.js'
mod_source="$(cd "$(dirname "$0")" && pwd)/$mod_name"
script_tag="<script src=\"$mod_name\"></script>"
# File name used by the previous version
legacy_name='hk-tab-close.js'
legacy_tag="<script src=\"$legacy_name\"></script>"

# Removes a tag (and its indented line) from window.html
remove_tag() {
  local html="$1" tag="$2"
  TAG="$tag" perl -0pi -e 's/^[ \t]*\Q$ENV{TAG}\E\r?\n//mg; s/\Q$ENV{TAG}\E//g' "$html"
}

targets=()
for app in /Applications/Vivaldi.app "$HOME/Applications/Vivaldi.app" \
           /Applications/Vivaldi\ Snapshot.app "$HOME/Applications/Vivaldi Snapshot.app"; do
  [[ -d "$app" ]] || continue
  for dir in "$app"/Contents/Frameworks/Vivaldi\ Framework.framework/Versions/*/Resources/vivaldi; do
    [[ -f "$dir/window.html" ]] && targets+=("$dir")
  done
done

if [[ ${#targets[@]} -eq 0 ]]; then
  echo 'No Vivaldi installation found.' >&2
  exit 1
fi

if pgrep -xq Vivaldi; then
  echo 'Warning: Vivaldi is running. Quit (Cmd+Q) and reopen Vivaldi for the changes to take effect.' >&2
fi

for dir in "${targets[@]}"; do
  html="$dir/window.html"
  # Plain permissions (sudo helps) or macOS App Management protection (it does not)
  if ! touch "$dir/.hk-write-test" 2>/dev/null; then
    echo "No write access to $dir" >&2
    if [[ -w "$dir" ]]; then
      echo 'macOS blocks changes to other apps. Allow your terminal app under System Settings →' >&2
      echo 'Privacy & Security → App Management, restart the terminal and run this again.' >&2
    else
      echo 'Run this again with sudo.' >&2
    fi
    exit 1
  fi
  rm -f "$dir/.hk-write-test"

  remove_tag "$html" "$legacy_tag"
  rm -f "$dir/$legacy_name"

  if [[ $uninstall -eq 1 ]]; then
    remove_tag "$html" "$script_tag"
    rm -f "$dir/$mod_name"
    echo "Removed: $dir"
    continue
  fi

  [[ -f "$html.bak" ]] || cp "$html" "$html.bak"
  cp -f "$mod_source" "$dir/$mod_name"

  if ! grep -qF "$script_tag" "$html"; then
    TAG="$script_tag" perl -0pi -e 's#</body>#  $ENV{TAG}\n</body>#' "$html"
  fi
  echo "Installed: $dir"
done
