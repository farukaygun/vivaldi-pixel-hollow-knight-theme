# Pixel Hollow Knight [Animated] — Vivaldi

![Preview](preview.png)

A Vivaldi port of the Firefox theme **Pixel Hollow Knight [Animated] v7.0**.
The animated pixel art sits in the top-right corner at its original size, just like in Firefox,
behind transparent tab, address and bookmark bars. Start Page dashboard widgets sit at the bottom of the screen.

Works on **Windows** and **macOS**.

## Contents

| File | Purpose |
| --- | --- |
| `1-theme/pixel-hollow-knight-vivaldi.zip` | Vivaldi theme (colours + background image) |
| `2-css-mod/hollow-knight.css` | Animated artwork, transparent bars and bottom-aligned dashboard widgets |
| `3-js-mod/` | Optional: Chrome/Edge-style tab open and close animation (`.ps1` for Windows, `.sh` for macOS) |
| `install-macos.sh` | macOS: sets up steps 2–4 below in one go |
| `install-windows.ps1` | Windows: the same, in PowerShell |

Use the theme and the CSS mod together. The theme alone only applies the colours and the background image.

## Installation

### macOS (quick)

1. **Install the theme:** Settings (`⌘,`) → Themes → **Import** → `1-theme/pixel-hollow-knight-vivaldi.zip`
2. In Terminal, from the repository folder:

   ```sh
   ./install-macos.sh --with-js     # leave out --with-js to skip the tab animation
   ```

   The script quits Vivaldi if it is running (after asking; open tabs come back on the next start), then:
   - enables **Allow CSS modifications** in `vivaldi://experiments`,
   - copies the CSS mod to `~/Library/Application Support/Vivaldi/CustomUIModifications/PixelHollowKnight`
     and sets it as the **Custom UI Modifications** folder for every Vivaldi profile,
   - with `--with-js`, installs the tab animation into `Vivaldi.app`.

3. Start Vivaldi.

Re-run `./install-macos.sh --with-js` after every Vivaldi update — an update replaces `Vivaldi.app`
and removes the tab animation. Re-run it as well after editing `2-css-mod/hollow-knight.css`,
because Vivaldi reads the copy in Application Support.

### Windows (quick)

1. **Install the theme:** Settings (`Alt+P`) → Themes → **Import** → `1-theme/pixel-hollow-knight-vivaldi.zip`
2. In PowerShell, from the repository folder:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\install-windows.ps1 -WithJs   # leave out -WithJs to skip the tab animation
   ```

   It does the same as the macOS script, using `%LOCALAPPDATA%\Vivaldi\User Data\CustomUIModifications\PixelHollowKnight`.
   If Vivaldi is installed system-wide (`C:\Program Files`), run PowerShell as administrator for `-WithJs`.

3. Start Vivaldi.

Re-run it after every Vivaldi update (for `-WithJs`) and after editing `2-css-mod/hollow-knight.css`.
Remove everything with `-Uninstall`.

### Manual (Windows and macOS)

1. **Install the theme:** Settings → Themes → **Import** → `1-theme/pixel-hollow-knight-vivaldi.zip`
2. **Enable CSS mods:** open `vivaldi://experiments`, tick
   **Allow CSS modifications** and restart Vivaldi.
3. **Add the mod:** Settings → Appearance → **Custom UI Modifications** → choose the `2-css-mod` folder.
   Restart Vivaldi again.

   > Vivaldi loads every `.css` file in the chosen folder, so keep only this mod in `2-css-mod`.
   >
   > On macOS, if the repository is in `~/Desktop`, `~/Documents` or `~/Downloads`, macOS asks for
   > permission before Vivaldi may read that folder — allow it, or use `install-macos.sh`,
   > which copies the mod to a folder that needs no permission.

4. **(Optional) Tab open/close animation** — repeat this after every Vivaldi update:
   - **Windows:** close Vivaldi, open PowerShell in the `3-js-mod` folder and run
     `powershell -ExecutionPolicy Bypass -File .\install-js-mod.ps1`.
     To remove it: `powershell -ExecutionPolicy Bypass -File .\install-js-mod.ps1 -Uninstall`
   - **macOS:** quit Vivaldi (`⌘Q`) and run `./3-js-mod/install-js-mod.sh`.
     To remove it: `./3-js-mod/install-js-mod.sh --uninstall`.

   > **macOS "No write access":** macOS protects app bundles from being changed by other apps.
   > Allow your terminal app (Terminal, iTerm…) under System Settings → Privacy & Security →
   > **App Management**, restart the terminal and run the script again. If the script asks for it
   > instead, prefix the command with `sudo`.

## Uninstall

1. Delete the theme from the Themes page.
2. Remove the mods:
   - **macOS:** `./install-macos.sh --uninstall` (clears the Custom UI Modifications folder and removes the tab animation).
   - **Windows:** clear Settings → Appearance → Custom UI Modifications.
     If you installed the JS mod, run `install-js-mod.ps1 -Uninstall` as well.

## Credits

- Original Firefox theme: *Pixel Hollow Knight [Animated]* (Firefox Add-ons)
- Hollow Knight © Team Cherry. This is an unofficial fan work.
