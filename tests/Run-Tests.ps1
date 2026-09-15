param([string]$GodotPath = $env:GODOT_PATH, [switch]$Visual)
$ErrorActionPreference = 'Stop'
if (-not $GodotPath) {
    $found = Get-Command godot, godot4 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $GodotPath = $found.Source }
}
if (-not $GodotPath -or -not (Test-Path -LiteralPath $GodotPath)) {
    throw 'Supply -GodotPath with your Godot console executable, or set GODOT_PATH.'
}
$projectPath = Split-Path $PSScriptRoot -Parent
$outputPath = Join-Path $PSScriptRoot 'output'
New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
function Invoke-GodotCheck([string]$Name, [string[]]$Arguments) {
    $log = & $GodotPath @Arguments 2>&1
    $result = $LASTEXITCODE
    $log | Set-Content -LiteralPath (Join-Path $outputPath ($Name + '.log'))
    $log | Write-Output
    if ($result -ne 0 -or ($log -match 'SCRIPT ERROR:|^ERROR:|FAIL  ')) {
        throw "Godot check failed: $Name"
    }
}
Invoke-GodotCheck 'import' @('--headless', '--path', $projectPath, '--editor', '--import', '--quit')
$testArgs = @('--path', $projectPath, 'res://tests/regression.tscn')
if ($Visual) { $testArgs += @('--', '--visual') } else { $testArgs = @('--headless') + $testArgs }
Invoke-GodotCheck 'regression' $testArgs
$progressionArgs = @('--path', $projectPath, 'res://tests/progression_regression.tscn')
if ($Visual) { $progressionArgs += @('--', '--visual') } else { $progressionArgs = @('--headless') + $progressionArgs }
Invoke-GodotCheck 'progression' $progressionArgs
$artArgs = @('--path', $projectPath, 'res://tests/art_review.tscn')
if (-not $Visual) { $artArgs = @('--headless') + $artArgs }
Invoke-GodotCheck 'art' $artArgs
$assetArgs = @('--path', $projectPath, 'res://tests/asset_review.tscn')
if (-not $Visual) { $assetArgs = @('--headless') + $assetArgs }
Invoke-GodotCheck 'assets' $assetArgs
$displayArgs = @('--path', $projectPath, 'res://tests/fullscreen.tscn')
if (-not $Visual) { $displayArgs = @('--headless') + $displayArgs }
Invoke-GodotCheck 'fullscreen' $displayArgs
Invoke-GodotCheck 'restart-seed' @('--headless', '--path', $projectPath, 'res://tests/regression.tscn', '--', '--restart-seed')
Invoke-GodotCheck 'restart-load' @('--headless', '--path', $projectPath, 'res://tests/regression.tscn', '--', '--restart-load')
Write-Output 'All regression checks passed.'
