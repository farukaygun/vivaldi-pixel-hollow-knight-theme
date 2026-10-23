# Pixel Hollow Knight [Animated] — Vivaldi

![Preview](preview.png)

A Vivaldi port of the Firefox theme **Pixel Hollow Knight [Animated] v7.0**.
The animated pixel art sits in the top-right corner at its original size, just like in Firefox,
behind transparent tab, address and bookmark bars. Start Page dashboard widgets sit at the bottom of the screen.

## Contents

| File | Purpose |
| --- | --- |
| `1-theme/pixel-hollow-knight-vivaldi.zip` | Vivaldi theme (colours + background image) |
| `2-css-mod/hollow-knight.css` | Animated artwork, transparent bars and bottom-aligned dashboard widgets |
| `3-js-mod/` | Optional: Chrome/Edge-style tab open and close animation |

Use the theme and the CSS mod together. The theme alone only applies the colours and the background image.

## Installation

1. **Install the theme:** Settings → Themes → **Import** → `1-theme/pixel-hollow-knight-vivaldi.zip`
2. **Enable CSS mods:** open `vivaldi://experiments`, tick
   **Allow for using CSS modifications** and restart Vivaldi.
3. **Add the mod:** Settings → Appearance → **Custom UI Modifications** → choose the `2-css-mod` folder.
   Restart Vivaldi again.

   > Vivaldi loads every `.css` file in the chosen folder, so keep only this mod in `2-css-mod`.

4. **(Optional) Tab open/close animation:** close Vivaldi, open PowerShell in the `3-js-mod` folder and run
   `powershell -ExecutionPolicy Bypass -File .\install-js-mod.ps1`. Repeat this after every Vivaldi update.
   To remove it: `powershell -ExecutionPolicy Bypass -File .\install-js-mod.ps1 -Uninstall`

## Uninstall

Clear Settings → Appearance → Custom UI Modifications, then delete the theme from the Themes page.
If you installed the JS mod, run `install-js-mod.ps1 -Uninstall` as well.

## Credits

- Original Firefox theme: *Pixel Hollow Knight [Animated]* (Firefox Add-ons)
- Hollow Knight © Team Cherry. This is an unofficial fan work.
