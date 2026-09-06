#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$BuildDirectory = (Join-Path $PSScriptRoot 'build'),
    [string]$StageDirectory = (Join-Path $PSScriptRoot 'stage')
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    throw 'cmake was not found. Run this script from the KDE Craft terminal.'
}

$configureArguments = @(
    '-S', $PSScriptRoot,
    '-B', $BuildDirectory,
    '-DCMAKE_BUILD_TYPE=Release',
    "-DCMAKE_INSTALL_PREFIX=$StageDirectory"
)

& cmake @configureArguments
if ($LASTEXITCODE -ne 0) {
    throw "CMake configuration failed with exit code $LASTEXITCODE."
}

& cmake --build $BuildDirectory --config Release --parallel
if ($LASTEXITCODE -ne 0) {
    throw "Build failed with exit code $LASTEXITCODE."
}

& cmake --install $BuildDirectory --config Release
if ($LASTEXITCODE -ne 0) {
    throw "Install-to-stage failed with exit code $LASTEXITCODE."
}

$plugin = Get-ChildItem -LiteralPath $StageDirectory -Recurse -Filter 'katefontrouting.dll' |
    Select-Object -First 1

if (-not $plugin) {
    throw "Build succeeded, but katefontrouting.dll was not found under $StageDirectory."
}

Write-Host "Plugin built successfully: $($plugin.FullName)"
Write-Host 'Next: close Kate, then run .\install.ps1 from an elevated PowerShell window.'
