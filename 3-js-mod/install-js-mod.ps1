# Pixel Hollow Knight [Animated] - Vivaldi JS mod installer
# Adds hk-tab-animations.js to Vivaldi. Run it again after every Vivaldi update.
# To remove it: .\install-js-mod.ps1 -Uninstall

param([switch]$Uninstall)

$ErrorActionPreference = 'Stop'
$modName = 'hk-tab-animations.js'
$modSource = Join-Path $PSScriptRoot $modName
$scriptTag = "<script src=`"$modName`"></script>"
# File name used by the previous version
$legacyName = 'hk-tab-close.js'
$legacyTag = "<script src=`"$legacyName`"></script>"

function Remove-Tag([string]$content, [string]$tag) {
  $content.Replace("  $tag`r`n", '').Replace("  $tag`n", '').Replace($tag, '')
}

$roots = @(
  "$env:LOCALAPPDATA\Vivaldi\Application",
  "$env:ProgramFiles\Vivaldi\Application",
  "${env:ProgramFiles(x86)}\Vivaldi\Application"
) | Where-Object { Test-Path $_ }

$targets = foreach ($root in $roots) {
  Get-ChildItem $root -Directory |
    ForEach-Object { Join-Path $_.FullName 'resources\vivaldi' } |
    Where-Object { Test-Path (Join-Path $_ 'window.html') }
}

if (-not $targets) {
  Write-Error 'No Vivaldi installation found.'
}

if (Get-Process vivaldi -ErrorAction SilentlyContinue) {
  Write-Warning 'Vivaldi is running. Close and reopen Vivaldi for the changes to take effect.'
}

foreach ($dir in $targets) {
  $html = Join-Path $dir 'window.html'
  $content = Remove-Tag (Get-Content $html -Raw) $legacyTag
  Remove-Item (Join-Path $dir $legacyName) -ErrorAction SilentlyContinue

  if ($Uninstall) {
    $content = Remove-Tag $content $scriptTag
    Set-Content $html $content -NoNewline
    Remove-Item (Join-Path $dir $modName) -ErrorAction SilentlyContinue
    Write-Host "Removed: $dir"
    continue
  }

  $backup = "$html.bak"
  if (-not (Test-Path $backup)) {
    Copy-Item $html $backup
  }

  Copy-Item $modSource (Join-Path $dir $modName) -Force

  if (-not $content.Contains($scriptTag)) {
    $content = $content -replace '</body>', "  $scriptTag`n</body>"
  }
  Set-Content $html $content -NoNewline
  Write-Host "Installed: $dir"
}
