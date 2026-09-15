param([string]$GodotPath = $env:GODOT_PATH)
$ErrorActionPreference = 'Stop'
if (-not $GodotPath) {
    $found = Get-Command godot, godot4 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $GodotPath = $found.Source }
}
if (-not $GodotPath -or -not (Test-Path -LiteralPath $GodotPath)) {
    throw 'Supply -GodotPath with your Godot console executable, or set GODOT_PATH.'
}
& $GodotPath --path $PSScriptRoot
exit $LASTEXITCODE
