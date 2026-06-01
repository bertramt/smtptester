# Build distribution zip: smtptester-<VERSION>.zip
$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$versionFile = Join-Path $root 'VERSION'
if (-not (Test-Path -LiteralPath $versionFile)) {
    throw "VERSION file not found: $versionFile"
}

$version = (Get-Content -LiteralPath $versionFile -Raw).Trim()
if ([string]::IsNullOrWhiteSpace($version)) {
    throw 'VERSION file is empty.'
}

$zipName = "smtptester-$version.zip"
$zipPath = Join-Path $root $zipName

$files = @(
    'smtptest.ps1',
    'smtptest.cmd',
    'smtptest.config.json.example',
    'LICENSE',
    'VERSION',
    'README.md'
) | ForEach-Object { Join-Path $root $_ }

foreach ($file in $files) {
    if (-not (Test-Path -LiteralPath $file)) {
        throw "Missing file: $file"
    }
}

if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}

Compress-Archive -Path $files -DestinationPath $zipPath -Force
Write-Host "Created $zipPath"
