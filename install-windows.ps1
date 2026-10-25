# Pixel Hollow Knight [Animated] - Vivaldi installer (Windows)
# Enables CSS mods in vivaldi://experiments, installs the CSS mod and points
# every Vivaldi profile at it. The theme itself is imported from Settings -> Themes.
#
#   .\install-windows.ps1              CSS mod
#   .\install-windows.ps1 -WithJs      CSS mod + tab open/close animation
#   .\install-windows.ps1 -Uninstall   remove both

param([switch]$WithJs, [switch]$Uninstall)

$ErrorActionPreference = 'Stop'

$repo = $PSScriptRoot
$dataDir = Join-Path $env:LOCALAPPDATA 'Vivaldi\User Data'
# Next to the profiles, so it survives Vivaldi updates and needs no extra permissions
$modDir = Join-Path $dataDir 'CustomUIModifications\PixelHollowKnight'
$flag = 'vivaldi-css-mods'

if (-not (Test-Path (Join-Path $dataDir 'Local State'))) {
  Write-Error 'No Vivaldi profile found. Start Vivaldi once, quit it and run this again.'
}

# Vivaldi rewrites its settings on quit, so it must be closed while we edit them
$running = @(Get-Process vivaldi -ErrorAction SilentlyContinue)
if ($running) {
  $answer = Read-Host 'Vivaldi is running. Quit it now? Open tabs are restored on the next start. [y/N]'
  if ($answer -notmatch '^[Yy]$') { Write-Host 'Aborted.'; exit 1 }
  $running | Where-Object { $_.MainWindowHandle -ne 0 } | ForEach-Object { [void]$_.CloseMainWindow() }
  for ($i = 0; $i -lt 30 -and (Get-Process vivaldi -ErrorAction SilentlyContinue); $i++) {
    Start-Sleep -Seconds 1
  }
  if (Get-Process vivaldi -ErrorAction SilentlyContinue) {
    Write-Error 'Vivaldi did not quit. Close it manually and run this again.'
  }
}

if (-not $Uninstall) {
  New-Item -ItemType Directory -Force $modDir | Out-Null
  Copy-Item (Join-Path $repo '2-css-mod\hollow-knight.css') $modDir -Force
}

# Windows PowerShell 5.1 cannot turn JSON into editable objects without losing
# data (ConvertFrom-Json gives read-only objects), so use the serializer that
# produces plain dictionaries.
if ($PSVersionTable.PSVersion.Major -ge 6) {
  function Read-Json([string]$path) { Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable }
  function Write-Json($data) { ConvertTo-Json $data -Depth 100 -Compress }
} else {
  Add-Type -AssemblyName System.Web.Extensions
  $serializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
  $serializer.MaxJsonLength = [int]::MaxValue
  $serializer.RecursionLimit = 200
  function Read-Json([string]$path) { $serializer.DeserializeObject((Get-Content $path -Raw -Encoding UTF8)) }
  function Write-Json($data) { $serializer.Serialize($data) }
}

function Get-Child($parent, [string]$key) {
  if (-not $parent.ContainsKey($key)) { $parent[$key] = New-Object 'System.Collections.Generic.Dictionary[string,object]' }
  $parent[$key]
}

function Edit-Json([string]$path, [scriptblock]$change) {
  $data = Read-Json $path
  & $change $data
  $tmp = "$path.hk-tmp"
  [IO.File]::WriteAllText($tmp, (Write-Json $data), (New-Object Text.UTF8Encoding($false)))
  Move-Item $tmp $path -Force
}

# Local State: experiment flag. Preferences (every profile): CSS mods folder.
if (-not $Uninstall) {
  Edit-Json (Join-Path $dataDir 'Local State') {
    param($data)
    $browser = Get-Child $data 'browser'
    $flags = @()
    if ($browser.ContainsKey('enabled_labs_experiments')) { $flags = @($browser['enabled_labs_experiments']) }
    if ($flags -notcontains $flag) { $flags += $flag }
    $browser['enabled_labs_experiments'] = [object[]]$flags
  }
  Write-Host 'Enabled vivaldi://experiments -> Allow CSS modifications'
}

Get-ChildItem $dataDir -Directory |
  Where-Object { $_.Name -eq 'Default' -or $_.Name -like 'Profile *' } |
  ForEach-Object {
    $prefs = Join-Path $_.FullName 'Preferences'
    if (-not (Test-Path $prefs)) { return }
    Edit-Json $prefs {
      param($data)
      $appearance = Get-Child (Get-Child $data 'vivaldi') 'appearance'
      if ($Uninstall) {
        if ($appearance['css_ui_mods_directory'] -eq $modDir) { $appearance['css_ui_mods_directory'] = '' }
      } else {
        $appearance['css_ui_mods_directory'] = $modDir
      }
    }
    Write-Host ($(if ($Uninstall) { 'Cleared' } else { 'Set' }) + " Custom UI Modifications folder: $($_.Name)")
  }

$jsInstaller = Join-Path $repo '3-js-mod\install-js-mod.ps1'
if ($Uninstall) {
  Remove-Item $modDir -Recurse -Force -ErrorAction SilentlyContinue
  & $jsInstaller -Uninstall
} elseif ($WithJs) {
  & $jsInstaller
}

Write-Host 'Done. Start Vivaldi to see the changes.'
