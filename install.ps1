#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$KateExecutable,
    [string]$PluginDll
)

$ErrorActionPreference = 'Stop'

function Resolve-KateExecutable {
    param([string]$RequestedPath)

    if ($RequestedPath) {
        return (Resolve-Path -LiteralPath $RequestedPath).Path
    }

    $command = Get-Command kate.exe -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $candidates = @(
        (Join-Path $env:ProgramFiles 'Kate\bin\kate.exe'),
        (Join-Path $env:ProgramFiles 'Kate\kate.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Kate\bin\kate.exe')
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    throw 'kate.exe was not found. Pass its path with -KateExecutable.'
}

function Resolve-PluginDll {
    param([string]$RequestedPath)

    if ($RequestedPath) {
        return (Resolve-Path -LiteralPath $RequestedPath).Path
    }

    $candidate = Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'stage') -Recurse -Filter 'katefontrouting.dll' -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($candidate) {
        return $candidate.FullName
    }

    throw 'katefontrouting.dll was not found. Build it first or pass its path with -PluginDll.'
}

$katePath = Resolve-KateExecutable -RequestedPath $KateExecutable
$pluginPath = Resolve-PluginDll -RequestedPath $PluginDll

if (Get-Process kate -ErrorAction SilentlyContinue) {
    throw 'Kate is running. Close every Kate window before installing the plugin.'
}

$kateBin = Split-Path -Parent $katePath
$qtCore = Join-Path $kateBin 'Qt6Core.dll'
if (-not (Test-Path -LiteralPath $qtCore -PathType Leaf)) {
    throw "Qt6Core.dll was not found beside Kate: $qtCore"
}

$qtVersionInfo = (Get-Item -LiteralPath $qtCore).VersionInfo
$qtVersion = [version]::new(
    $qtVersionInfo.FileMajorPart,
    $qtVersionInfo.FileMinorPart,
    $qtVersionInfo.FileBuildPart,
    $qtVersionInfo.FilePrivatePart
)
if ($qtVersion -lt [version]'6.9.0.0') {
    throw "This plugin needs Qt 6.9 or newer; this Kate installation uses $qtVersion."
}

$knownPlugin = Get-ChildItem -LiteralPath $kateBin -Recurse -Filter 'katefiletreeplugin.dll' -ErrorAction SilentlyContinue |
    Where-Object { $_.Directory.Name -eq 'ktexteditor' } |
    Select-Object -First 1

if ($knownPlugin) {
    $destinationDirectory = $knownPlugin.Directory.FullName
} else {
    $destinationDirectory = Join-Path $kateBin 'kf6\ktexteditor'
    if (-not (Test-Path -LiteralPath $destinationDirectory -PathType Container)) {
        throw "Kate's KTextEditor plugin directory was not found under: $kateBin"
    }
}

$destination = Join-Path $destinationDirectory 'katefontrouting.dll'
if (Test-Path -LiteralPath $destination -PathType Leaf) {
    $backup = "$destination.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item -LiteralPath $destination -Destination $backup
    Write-Host "Previous plugin backed up to: $backup"
}

Copy-Item -LiteralPath $pluginPath -Destination $destination -Force
Write-Host "Installed: $destination"
Write-Host 'Start Kate, verify Settings > Configure Kate > Plugins > Font Routing, then restart Kate once.'
