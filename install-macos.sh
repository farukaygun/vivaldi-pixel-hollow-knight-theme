#!/bin/bash
# Pixel Hollow Knight [Animated] - Vivaldi installer (macOS)
# Enables CSS mods in vivaldi://experiments, installs the CSS mod and points
# every Vivaldi profile at it. The theme itself is imported from Settings → Themes.
#
#   ./install-macos.sh              CSS mod
#   ./install-macos.sh --with-js    CSS mod + tab open/close animation
#   ./install-macos.sh --uninstall  remove both

set -euo pipefail

with_js=0
uninstall=0
for arg in "$@"; do
  case "$arg" in
    --with-js) with_js=1 ;;
    --uninstall) uninstall=1 ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

repo="$(cd "$(dirname "$0")" && pwd)"
data_dir="$HOME/Library/Application Support/Vivaldi"
# Outside ~/Desktop and ~/Documents so Vivaldi needs no folder access permission
mod_dir="$data_dir/CustomUIModifications/PixelHollowKnight"

if [[ ! -f "$data_dir/Local State" ]]; then
  echo 'No Vivaldi profile found. Start Vivaldi once, quit it and run this again.' >&2
  exit 1
fi

# Vivaldi rewrites its settings on quit, so it must be closed while we edit them
if pgrep -xq Vivaldi; then
  read -r -p 'Vivaldi is running. Quit it now? Open tabs are restored on the next start. [y/N] ' answer
  [[ "$answer" =~ ^[Yy]$ ]] || { echo 'Aborted.'; exit 1; }
  osascript -e 'quit app "Vivaldi"'
  for _ in {1..30}; do pgrep -xq Vivaldi || break; sleep 1; done
  if pgrep -xq Vivaldi; then
    echo 'Vivaldi did not quit. Close it manually and run this again.' >&2
    exit 1
  fi
fi

if [[ $uninstall -eq 0 ]]; then
  mkdir -p "$mod_dir"
  cp -f "$repo/2-css-mod/hollow-knight.css" "$mod_dir/"
fi

# Local State: experiment flag. Preferences (every profile): CSS mods folder.
/usr/bin/python3 -I - "$data_dir" "$mod_dir" "$uninstall" <<'EOF'
import json, os, sys

data_dir, mod_dir, uninstall = sys.argv[1], sys.argv[2], sys.argv[3] == '1'
FLAG = 'vivaldi-css-mods'

def edit(path, change):
    with open(path, encoding='utf-8') as f:
        data = json.load(f)
    change(data)
    tmp = path + '.hk-tmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))
    os.replace(tmp, path)

def set_flag(data):
    flags = data.setdefault('browser', {}).setdefault('enabled_labs_experiments', [])
    if FLAG not in flags:
        flags.append(FLAG)

def set_mod_dir(data):
    appearance = data.setdefault('vivaldi', {}).setdefault('appearance', {})
    if uninstall:
        if appearance.get('css_ui_mods_directory') == mod_dir:
            appearance['css_ui_mods_directory'] = ''
    else:
        appearance['css_ui_mods_directory'] = mod_dir

if not uninstall:
    edit(os.path.join(data_dir, 'Local State'), set_flag)
    print('Enabled vivaldi://experiments → Allow CSS modifications')

for name in sorted(os.listdir(data_dir)):
    prefs = os.path.join(data_dir, name, 'Preferences')
    if (name == 'Default' or name.startswith('Profile ')) and os.path.isfile(prefs):
        edit(prefs, set_mod_dir)
        print(('Cleared' if uninstall else 'Set') + f' Custom UI Modifications folder: {name}')
EOF

if [[ $uninstall -eq 1 ]]; then
  rm -rf "$mod_dir"
  "$repo/3-js-mod/install-js-mod.sh" --uninstall
elif [[ $with_js -eq 1 ]]; then
  "$repo/3-js-mod/install-js-mod.sh"
fi

echo 'Done. Start Vivaldi to see the changes.'
