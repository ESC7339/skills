
#========================================
# PowerShell Script Boilerplate
#========================================

# Region: Strict Settings
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Region: Root/Admin Check
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "[ERROR] This script must be run as Administrator."
    exit 1
}

# Defaults
$WorkDir = ""
$MountDir = ""
$ChrootDir = ""
$LoopDev = ""
$WorkDirProvided = $false
$Output = ""
$InputISO = ""
$Debug = $false
$DoClean = $false
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Cleanup Handler
$cleanupScript = {
    Write-Host "[CLEANUP] Running cleanup..." -ForegroundColor Cyan

    if ($MountDir -and (Test-Path $MountDir)) {
        try {
            Dismount-DiskImage -ImagePath $InputISO -ErrorAction SilentlyContinue
        } catch {}
    }

    if (-not $WorkDirProvided -and (Test-Path $WorkDir)) {
        Write-Host "[CLEANUP] Removing workdir '$WorkDir'" -ForegroundColor Cyan
        Remove-Item -Recurse -Force $WorkDir -ErrorAction SilentlyContinue
    } else {
        Write-Host "[CLEANUP] Leaving workdir '$WorkDir' intact." -ForegroundColor Yellow
    }

    Write-Host "[CLEANUP] Done." -ForegroundColor Green
}
Register-EngineEvent PowerShell.Exiting -Action $cleanupScript | Out-Null

# Helpers
function Die($msg) {
    Write-Error "[ERROR] $msg"
    exit 1
}
function Log($msg) {
    Write-Host "[INFO] $msg"
}

# Argument Parsing
param(
    [string] $Input,
    [string] $OutputFile,
    [string] $WorkDirArg,
    [switch] $Clean,
    [switch] $DebugFlag
)

if ($Clean) {
    & $cleanupScript.Invoke()
    exit 0
}

if (-not $Input) {
    Die "Usage: script.ps1 -Input <iso> [-OutputFile <out.img>] [-WorkDirArg <dir>] [-DebugFlag] [-Clean]"
}

$InputISO = $Input
if (-not (Test-Path $InputISO)) {
    Die "Input ISO not found: $InputISO"
}

if ($WorkDirArg) {
    $WorkDir = $WorkDirArg
    $WorkDirProvided = $true
} else {
    $WorkDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "sudobuild-$([guid]::NewGuid())") -Force
}
$MountDir = Join-Path $WorkDir "iso-mount"
$ChrootDir = Join-Path $WorkDir "chroot"
New-Item -ItemType Directory -Path $MountDir, $ChrootDir -Force | Out-Null

if ($OutputFile) {
    $Output = $OutputFile
} else {
    $base = [System.IO.Path]::GetFileNameWithoutExtension($InputISO)
    $Output = "$base-custom.img"
}

if (-not $Output.ToLower().EndsWith(".img")) {
    Die "Output must end in .img"
}

Log "Input ISO: $InputISO"
Log "Output: $Output"
Log "Workdir: $WorkDir (provided=$WorkDirProvided)"

# ISO Mount
Log "Mounting ISO..."
Mount-DiskImage -ImagePath $InputISO -StorageType ISO -PassThru | Out-Null
$MountedImage = Get-DiskImage -ImagePath $InputISO | Get-Volume
$MountedPath = ($MountedImage.DriveLetter + ":\")
Log "ISO mounted at $MountedPath"

# ISO Copy
$IsoRoot = Join-Path $WorkDir "iso-root"
New-Item -ItemType Directory -Path $IsoRoot -Force | Out-Null
Log "Copying ISO contents to $IsoRoot"
Copy-Item -Path "$MountedPath*" -Destination $IsoRoot -Recurse -Force


Log "Preparing chroot patching (placeholder)..."
# Place unsquashfs, chroot patch logic


Log "Final output would be written to $Output"


# Region: Manual Cleanup Trigger
Write-Host "[FINISHED] All done. Triggering cleanup." -ForegroundColor Green
& $cleanupScript.Invoke()
exit 0
