param(
  [Parameter(Mandatory = $true)]
  [string]$JsonPath,

  [string]$TargetName = "digital_lifelines_import.json"
)

if (-not (Test-Path $JsonPath)) {
  Write-Error "File not found: $JsonPath"
  exit 1
}

$adb = Get-Command adb -ErrorAction SilentlyContinue
if (-not $adb) {
  Write-Error "adb not found. Install Android platform-tools and ensure adb is in PATH."
  exit 1
}

$target = "/sdcard/Download/$TargetName"

Write-Host "Pushing JSON to phone: $target"
adb push "$JsonPath" "$target"
if ($LASTEXITCODE -ne 0) {
  Write-Error "adb push failed"
  exit 1
}

Write-Host "Done."
Write-Host "Now in the app: About -> Import JSON From File -> choose $TargetName from Downloads."
