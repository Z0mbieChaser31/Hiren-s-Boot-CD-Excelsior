#Requires -Version 5.1
<#
.SYNOPSIS
    Hiren's Boot CD Excelsior — Windows Setup Wrapper
.DESCRIPTION
    PowerShell wrapper for setup.py that handles Windows-specific requirements:
    elevation, Python detection/installation, and a friendly launch experience.
.EXAMPLE
    .\setup.ps1
    .\setup.ps1 -Profile core
    .\setup.ps1 -Profile full -Dest E:\ISOs
    .\setup.ps1 -ListIsos
    .\setup.ps1 -DryRun
#>
[CmdletBinding()]
param(
    [string]$Profile = "",
    [string]$Dest = "",
    [switch]$ListIsos,
    [switch]$ListProfiles,
    [switch]$VentoyOnly,
    [switch]$IsosOnly,
    [switch]$DryRun,
    [switch]$NoSkipExisting
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# ── ANSI colors (Windows 10+ Terminal) ───────────────────────────────────────
function Write-Color {
    param([string]$Text, [string]$Color = "White")
    $colors = @{
        "Cyan"    = "`e[96m"
        "Green"   = "`e[92m"
        "Yellow"  = "`e[93m"
        "Red"     = "`e[91m"
        "Bold"    = "`e[1m"
        "Dim"     = "`e[2m"
        "White"   = "`e[97m"
        "Reset"   = "`e[0m"
    }
    $code = $colors[$Color]
    if ($code) { Write-Host "$code$Text`e[0m" } else { Write-Host $Text }
}

function Write-Banner {
    Write-Host ""
    Write-Color "╔══════════════════════════════════════════════════════════════╗" "Cyan"
    Write-Color "║   ⚡ Hiren's Boot CD Excelsior — Windows Setup             ║" "Bold"
    Write-Color "║   Modern Multi-OS Bootable USB Toolkit                       ║" "Dim"
    Write-Color "╚══════════════════════════════════════════════════════════════╝" "Cyan"
    Write-Host ""
}

function Write-Step {
    param([string]$Message)
    Write-Color "  ● $Message" "Cyan"
}

function Write-Ok {
    param([string]$Message)
    Write-Color "  ✓ $Message" "Green"
}

function Write-Warn {
    param([string]$Message)
    Write-Color "  ! $Message" "Yellow"
}

function Write-Err {
    param([string]$Message)
    Write-Color "  ✗ $Message" "Red"
}

# ── Elevation check ───────────────────────────────────────────────────────────
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Request-Elevation {
    if (-not (Test-Administrator)) {
        Write-Warn "Administrator privileges recommended for USB disk operations."
        $elevate = Read-Host "  ? Restart as Administrator? [Y/n]"
        if ($elevate -eq "" -or $elevate -match "^[Yy]") {
            $argList = @("-ExecutionPolicy", "Bypass", "-File", $MyInvocation.ScriptName) + $args
            Start-Process powershell -Verb RunAs -ArgumentList $argList
            exit
        }
    }
}

# ── Python detection and installation ─────────────────────────────────────────
function Find-Python {
    # Try common Python locations
    $candidates = @(
        "python",
        "python3",
        "py",
        "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python311\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python310\python.exe",
        "C:\Python312\python.exe",
        "C:\Python311\python.exe"
    )
    foreach ($candidate in $candidates) {
        try {
            $version = & $candidate --version 2>&1
            if ($version -match "Python (\d+)\.(\d+)") {
                $major = [int]$Matches[1]
                $minor = [int]$Matches[2]
                if ($major -ge 3 -and $minor -ge 8) {
                    Write-Ok "Found Python $major.$minor at: $candidate"
                    return $candidate
                }
            }
        } catch {}
    }
    return $null
}

function Install-Python {
    Write-Step "Python 3.8+ not found. Attempting to install via winget..."
    try {
        $winget = Get-Command winget -ErrorAction SilentlyContinue
        if ($winget) {
            winget install --id Python.Python.3.12 --accept-source-agreements --accept-package-agreements
            Write-Ok "Python installed. Please restart this script."
            pause
            exit
        }
    } catch {}
    
    # Fallback: open Python download page
    Write-Warn "Could not auto-install Python."
    Write-Step "Opening Python download page in your browser..."
    Start-Process "https://www.python.org/downloads/"
    Write-Err "Please install Python 3.8+ from python.org, then re-run this script."
    pause
    exit 1
}

# ── Main ──────────────────────────────────────────────────────────────────────
Write-Banner

# Check for Python
Write-Step "Checking for Python 3.8+..."
$python = Find-Python
if (-not $python) {
    Install-Python
    $python = Find-Python
    if (-not $python) {
        Write-Err "Python still not found after installation attempt. Please install manually."
        pause
        exit 1
    }
}

# Build argument list for setup.py
$setupScript = Join-Path $ScriptDir "setup.py"
if (-not (Test-Path $setupScript)) {
    Write-Err "setup.py not found in: $ScriptDir"
    Write-Err "Please run this script from the Hiren's Boot CD Excelsior folder."
    pause
    exit 1
}

$pyArgs = @($setupScript)

if ($Profile)       { $pyArgs += @("--profile", $Profile) }
if ($Dest)          { $pyArgs += @("--dest", $Dest) }
if ($ListIsos)      { $pyArgs += "--list-isos" }
if ($ListProfiles)  { $pyArgs += "--list-profiles" }
if ($VentoyOnly)    { $pyArgs += "--ventoy-only" }
if ($IsosOnly)      { $pyArgs += "--isos-only" }
if ($DryRun)        { $pyArgs += "--dry-run" }
if ($NoSkipExisting){ $pyArgs += "--no-skip-existing" }

# Run the script
try {
    & $python @pyArgs
    $exitCode = $LASTEXITCODE
} catch {
    Write-Err "Failed to run setup.py: $_"
    pause
    exit 1
}

if ($exitCode -ne 0) {
    Write-Err "Setup encountered errors (exit code $exitCode)."
} else {
    Write-Ok "Setup completed successfully."
}

if (-not $ListIsos -and -not $ListProfiles -and -not $DryRun) {
    Write-Host ""
    Read-Host "  Press Enter to exit"
}
