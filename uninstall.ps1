#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$KateExecutable
)

$ErrorActionPreference = 'Stop'

if (Get-Process kate -ErrorAction SilentlyContinue) {
    throw 'Kate is running. Close every Kate window before uninstalling the plugin.'
}

if ($KateExecutable) {
    $katePath = (Resolve-Path -LiteralPath $KateExecutable).Path
} else {
    $command = Get-Command kate.exe -ErrorAction SilentlyContinue
    if ($command) {
        $katePath = $command.Source
    } else {
        $katePath = Join-Path $env:ProgramFiles 'Kate\bin\kate.exe'
    }
}

if (-not (Test-Path -LiteralPath $katePath -PathType Leaf)) {
    throw 'kate.exe was not found. Pass its path with -KateExecutable.'
}

$kateBin = Split-Path -Parent $katePath
$plugin = Get-ChildItem -LiteralPath $kateBin -Recurse -Filter 'katefontrouting.dll' -ErrorAction SilentlyContinue |
    Where-Object { $_.Directory.Name -eq 'ktexteditor' } |
    Select-Object -First 1 -ExpandProperty FullName

if (-not $plugin) {
    $plugin = Join-Path $kateBin 'kf6\ktexteditor\katefontrouting.dll'
}
if (-not (Test-Path -LiteralPath $plugin -PathType Leaf)) {
    Write-Host "Plugin is not installed: $plugin"
    exit 0
}

$disabled = "$plugin.disabled-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Move-Item -LiteralPath $plugin -Destination $disabled
Write-Host "Plugin disabled and kept for recovery: $disabled"
