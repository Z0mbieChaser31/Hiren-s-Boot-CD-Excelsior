#!/usr/bin/env python3
"""
Hiren's Boot CD Excelsior — Setup Script
=========================================
Cross-platform setup tool for creating a modern, multi-OS bootable USB drive
using Ventoy as the bootloader and a curated collection of rescue/repair ISOs.

Supports: Windows, Linux, macOS
Requires: Python 3.8+, internet connection (for downloads)

Usage:
    python setup.py               # Interactive mode
    python setup.py --profile core     # Non-interactive, download 'core' profile
    python setup.py --profile full     # Non-interactive, download everything
    python setup.py --list-isos        # List all available ISOs
    python setup.py --ventoy-only      # Install Ventoy to USB, skip ISO download
    python setup.py --isos-only        # Download ISOs only, skip Ventoy install
    python setup.py --dry-run          # Validate catalog URLs without downloading
"""

import argparse
import hashlib
import io
import json
import os
import platform
import re
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.request
import urllib.error
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# ─── UTF-8 console fix (Windows cp1252 → UTF-8) ──────────────────────────────
if hasattr(sys, 'stdout') and hasattr(sys.stdout, 'reconfigure'):
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
        sys.stderr.reconfigure(encoding='utf-8', errors='replace')
    except Exception:
        pass

# ─── Constants ────────────────────────────────────────────────────────────────

SCRIPT_DIR = Path(__file__).parent.resolve()
CATALOG_FILE = SCRIPT_DIR / "iso_catalog.json"
VENTOY_CONFIG_SRC = SCRIPT_DIR / "ventoy" / "ventoy.json"
THEME_SRC = SCRIPT_DIR / "ventoy" / "themes" / "hbcd-excelsior"

VENTOY_RELEASES_API = "https://api.github.com/repos/ventoy/Ventoy/releases/latest"
VENTOY_DOWNLOAD_BASE = "https://github.com/ventoy/Ventoy/releases/download"

PROJECT_NAME = "Hiren's Boot CD Excelsior"
PROJECT_VERSION = "2.0.0"

ANSI = {
    "reset":  "\033[0m",
    "bold":   "\033[1m",
    "red":    "\033[91m",
    "green":  "\033[92m",
    "yellow": "\033[93m",
    "blue":   "\033[94m",
    "cyan":   "\033[96m",
    "white":  "\033[97m",
    "dim":    "\033[2m",
}

# Disable ANSI on Windows if not supported
if platform.system() == "Windows":
    try:
        import ctypes
        kernel32 = ctypes.windll.kernel32
        kernel32.SetConsoleMode(kernel32.GetStdHandle(-11), 7)
    except Exception:
        ANSI = {k: "" for k in ANSI}


# ─── Helpers ──────────────────────────────────────────────────────────────────

def c(color: str, text: str) -> str:
    """Wrap text in an ANSI color code."""
    return f"{ANSI.get(color, '')}{text}{ANSI['reset']}"


def _safe(char: str, fallback: str) -> str:
    """Return char if the terminal can encode it, otherwise return fallback."""
    try:
        char.encode(sys.stdout.encoding or 'ascii')
        return char
    except (UnicodeEncodeError, LookupError):
        return fallback


def banner():
    """Print the project banner."""
    box_h = _safe('═', '=')
    box_tl = _safe('╔', '+')
    box_tr = _safe('╗', '+')
    box_bl = _safe('╚', '+')
    box_br = _safe('╝', '+')
    box_v  = _safe('║', '|')
    bolt   = _safe('⚡', '*')
    dash   = _safe('—', '-')
    line   = box_h * 62
    print()
    print(c("cyan", f"{box_tl}{line}{box_tr}"))
    print(c("cyan", box_v) + c("bold", f"   {bolt} {PROJECT_NAME} {dash} Setup v{PROJECT_VERSION}   ") + c("cyan", box_v))
    print(c("cyan", box_v) + c("dim",  "   Modern Multi-OS Bootable USB Toolkit                         ") + c("cyan", box_v))
    print(c("cyan", f"{box_bl}{line}{box_br}"))
    print()


def info(msg: str):
    bullet = _safe('●', '*')
    print(f"  {c('blue', bullet)} {msg}")


def success(msg: str):
    tick = _safe('✓', 'OK')
    print(f"  {c('green', tick)} {msg}")


def warn(msg: str):
    print(f"  {c('yellow', '!')} {msg}")


def error(msg: str):
    cross = _safe('✗', 'ERR')
    print(f"  {c('red', cross)} {msg}", file=sys.stderr)


def header(title: str):
    arrow = _safe('▶', '>')
    dash  = _safe('─', '-')
    print()
    print(c("bold", f"  {arrow} {title}"))
    print(c("dim", "  " + dash * 60))


def prompt(msg: str, default: Optional[str] = None) -> str:
    """Prompt the user for input with an optional default."""
    suffix = f" [{default}]" if default else ""
    raw = input(f"  {c('cyan', '?')} {msg}{suffix}: ").strip()
    return raw if raw else (default or "")


def confirm(msg: str, default: bool = True) -> bool:
    """Ask a yes/no question."""
    suffix = " [Y/n]" if default else " [y/N]"
    raw = input(f"  {c('cyan', '?')} {msg}{suffix}: ").strip().lower()
    if not raw:
        return default
    return raw in ("y", "yes")


def require_python():
    if sys.version_info < (3, 8):
        error("Python 3.8+ required. Please upgrade Python.")
        sys.exit(1)


# ─── Catalog ──────────────────────────────────────────────────────────────────

def load_catalog() -> dict:
    """Load the ISO catalog from iso_catalog.json."""
    if not CATALOG_FILE.exists():
        error(f"Catalog file not found: {CATALOG_FILE}")
        sys.exit(1)
    with open(CATALOG_FILE, "r", encoding="utf-8") as f:
        return json.load(f)


def list_isos(catalog: dict, profile: Optional[str] = None):
    """Print all available ISOs, optionally filtered by profile."""
    profiles = catalog.get("profiles", {})
    isos = catalog.get("isos", {})

    if profile:
        if profile not in profiles:
            error(f"Unknown profile '{profile}'. Available: {', '.join(profiles.keys())}")
            sys.exit(1)
        selected_keys = profiles[profile]["isos"]
        target_isos = {k: isos[k] for k in selected_keys if k in isos}
    else:
        target_isos = isos

    header(f"Available ISOs{f' (profile: {profile})' if profile else ''}")
    categories: Dict[str, List[Tuple[str, dict]]] = {}
    for key, iso in target_isos.items():
        cat = iso.get("category", "Other")
        categories.setdefault(cat, []).append((key, iso))

    for cat, items in sorted(categories.items()):
        print(f"\n  {c('bold', cat)}")
        for key, iso in items:
            size = iso.get("size_mb", "?")
            uefi = c("green", "UEFI") if iso.get("uefi") else c("dim", "    ")
            bios = c("yellow", "BIOS") if iso.get("legacy_bios") else c("dim", "    ")
            paid = c("red", "[PAID]") if iso.get("requires_license") else ""
            print(f"    {c('cyan', key.ljust(22))} {iso['name'].ljust(40)} {size:>5} MB  {uefi} {bios} {paid}")

    print()
    print(c("dim", f"  Total: {len(target_isos)} ISOs"))
    print()


def list_profiles(catalog: dict):
    """Print all available profiles."""
    header("Available Profiles")
    for name, profile in catalog.get("profiles", {}).items():
        isos = profile.get("isos", [])
        total_mb = sum(
            catalog["isos"].get(k, {}).get("size_mb", 0) for k in isos
        )
        print(f"  {c('cyan', name.ljust(15))} ~{total_mb:,} MB   {profile.get('description', '')}")
    print()


def resolve_profile(catalog: dict, profile_name: str) -> List[str]:
    """Resolve a profile name to a list of ISO keys (handles nested profiles)."""
    profiles = catalog.get("profiles", {})
    if profile_name not in profiles:
        error(f"Unknown profile: {profile_name}")
        sys.exit(1)
    raw_keys = profiles[profile_name].get("isos", [])
    resolved = []
    for k in raw_keys:
        if k in profiles:
            resolved.extend(resolve_profile(catalog, k))
        else:
            if k not in resolved:
                resolved.append(k)
    return resolved


# ─── Ventoy ───────────────────────────────────────────────────────────────────

def get_ventoy_latest_version() -> Tuple[str, dict]:
    """Fetch the latest Ventoy version from GitHub API."""
    info("Checking latest Ventoy release...")
    try:
        req = urllib.request.Request(
            VENTOY_RELEASES_API,
            headers={"User-Agent": f"HBCDExcelsior/{PROJECT_VERSION}"}
        )
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read())
        version = data["tag_name"].lstrip("v")
        return version, data
    except Exception as e:
        warn(f"Could not fetch Ventoy version from GitHub: {e}")
        # Fallback to a known-good version
        fallback = "1.0.97"
        warn(f"Using fallback version: {fallback}")
        return fallback, {}


def get_ventoy_download_url(version: str) -> str:
    """Build the Ventoy download URL for the current OS."""
    system = platform.system()
    if system == "Windows":
        filename = f"ventoy-{version}-windows.zip"
    elif system == "Darwin":
        filename = f"ventoy-{version}-livecd.iso"  # macOS uses the livecd
    else:
        filename = f"ventoy-{version}-linux.tar.gz"
    return f"{VENTOY_DOWNLOAD_BASE}/v{version}/{filename}"


def detect_usb_drives() -> List[Dict]:
    """Detect available USB drives on the system."""
    system = platform.system()
    drives = []

    if system == "Windows":
        try:
            output = subprocess.check_output(
                ["wmic", "diskdrive", "where", "MediaType='Removable Media'",
                 "get", "DeviceID,Model,Size", "/format:csv"],
                text=True, stderr=subprocess.DEVNULL
            )
            for line in output.strip().splitlines():
                parts = line.strip().split(",")
                if len(parts) >= 4 and parts[1]:
                    size_bytes = int(parts[3]) if parts[3].isdigit() else 0
                    drives.append({
                        "device": parts[1],
                        "model": parts[2],
                        "size_gb": round(size_bytes / 1e9, 1)
                    })
        except Exception:
            pass
        # Also try PowerShell for better results
        try:
            ps_cmd = (
                'Get-Disk | Where-Object {$_.BusType -eq "USB"} | '
                'Select-Object Number,FriendlyName,Size | '
                'ConvertTo-Json'
            )
            output = subprocess.check_output(
                ["powershell", "-Command", ps_cmd],
                text=True, stderr=subprocess.DEVNULL
            )
            disks = json.loads(output) if output.strip() else []
            if isinstance(disks, dict):
                disks = [disks]
            for d in disks:
                drives.append({
                    "device": f"Disk {d.get('Number', '?')}",
                    "model": d.get("FriendlyName", "Unknown USB"),
                    "size_gb": round(d.get("Size", 0) / 1e9, 1)
                })
        except Exception:
            pass

    elif system in ("Linux", "Darwin"):
        try:
            if system == "Linux":
                output = subprocess.check_output(
                    ["lsblk", "-J", "-o", "NAME,MODEL,SIZE,TRAN,TYPE"],
                    text=True
                )
                data = json.loads(output)
                for dev in data.get("blockdevices", []):
                    if dev.get("tran") == "usb" and dev.get("type") == "disk":
                        drives.append({
                            "device": f"/dev/{dev['name']}",
                            "model": dev.get("model", "Unknown"),
                            "size_gb": dev.get("size", "?")
                        })
            else:  # macOS
                output = subprocess.check_output(
                    ["diskutil", "list", "-plist"],
                    text=True
                )
                # Basic parsing — full plist parsing would require plistlib
                import plistlib
                data = plistlib.loads(output.encode())
                for disk in data.get("AllDisksAndPartitions", []):
                    dev = disk.get("DeviceIdentifier", "")
                    if "disk" in dev and len(dev) <= 6:
                        info_out = subprocess.check_output(
                            ["diskutil", "info", "-plist", dev], text=True
                        )
                        info_data = plistlib.loads(info_out.encode())
                        if info_data.get("RemovableMedia"):
                            drives.append({
                                "device": f"/dev/{dev}",
                                "model": info_data.get("MediaName", "Unknown"),
                                "size_gb": round(
                                    info_data.get("TotalSize", 0) / 1e9, 1
                                )
                            })
        except Exception as e:
            warn(f"Could not auto-detect USB drives: {e}")

    return drives


def download_file(url: str, dest: Path, description: str = "", verify_sha256: Optional[str] = None):
    """Download a file with a progress bar."""
    dest.parent.mkdir(parents=True, exist_ok=True)

    label = description or dest.name
    info(f"Downloading: {c('bold', label)}")
    info(f"  URL: {c('dim', url)}")

    try:
        req = urllib.request.Request(
            url,
            headers={"User-Agent": f"HBCDExcelsior/{PROJECT_VERSION}"}
        )
        with urllib.request.urlopen(req, timeout=30) as resp, open(dest, "wb") as out:
            total = int(resp.headers.get("Content-Length", 0))
            downloaded = 0
            block = 1024 * 256  # 256 KB chunks
            start = time.time()

            while True:
                chunk = resp.read(block)
                if not chunk:
                    break
                out.write(chunk)
                downloaded += len(chunk)

                if total:
                    pct = downloaded / total * 100
                    bar_len = 40
                    filled = int(bar_len * downloaded / total)
                    bar = "█" * filled + "░" * (bar_len - filled)
                    elapsed = time.time() - start
                    speed = downloaded / elapsed / 1024 / 1024 if elapsed > 0 else 0
                    remaining = (total - downloaded) / (downloaded / elapsed) if downloaded > 0 else 0
                    print(
                        f"\r  {c('cyan', bar)} {pct:5.1f}%  "
                        f"{downloaded/1e6:6.1f}/{total/1e6:.1f} MB  "
                        f"{speed:.1f} MB/s  ETA {remaining:.0f}s   ",
                        end="", flush=True
                    )
                else:
                    print(
                        f"\r  Downloaded {downloaded/1e6:.1f} MB...",
                        end="", flush=True
                    )

        print()  # newline after progress bar

        if verify_sha256:
            info("Verifying checksum...")
            sha = hashlib.sha256()
            with open(dest, "rb") as f:
                for chunk in iter(lambda: f.read(1024 * 1024), b""):
                    sha.update(chunk)
            if sha.hexdigest().lower() != verify_sha256.lower():
                error(f"Checksum mismatch! Expected: {verify_sha256}")
                dest.unlink(missing_ok=True)
                return False
            success("Checksum verified ✓")

        success(f"Downloaded: {dest.name}")
        return True

    except urllib.error.HTTPError as e:
        print()
        error(f"HTTP {e.code}: {e.reason} — {url}")
        return False
    except urllib.error.URLError as e:
        print()
        error(f"Network error: {e.reason}")
        return False
    except KeyboardInterrupt:
        print()
        warn("Download cancelled.")
        dest.unlink(missing_ok=True)
        return False


def install_ventoy(usb_path: str, ventoy_installer: Path, dry_run: bool = False):
    """Run the Ventoy installer for the detected OS."""
    system = platform.system()
    header("Installing Ventoy to USB")

    if dry_run:
        info(f"[DRY RUN] Would install Ventoy to: {usb_path}")
        return True

    if system == "Windows":
        # Ventoy on Windows: extract zip, run Ventoy2Disk.exe
        import zipfile
        extract_dir = ventoy_installer.parent / "ventoy_extracted"
        info("Extracting Ventoy installer...")
        with zipfile.ZipFile(ventoy_installer, "r") as z:
            z.extractall(extract_dir)

        ventoy_exe = None
        for f in extract_dir.rglob("Ventoy2Disk.exe"):
            ventoy_exe = f
            break

        if not ventoy_exe:
            error("Ventoy2Disk.exe not found in archive.")
            return False

        # Run in command-line mode
        disk_num = re.search(r"(\d+)$", usb_path)
        if disk_num:
            disk_index = disk_num.group(1)
            result = subprocess.run(
                [str(ventoy_exe), "-I", f"Disk{disk_index}"],
                capture_output=True, text=True
            )
        else:
            warn("Could not determine disk number. Please run Ventoy2Disk.exe manually.")
            subprocess.Popen([str(ventoy_exe)])
            return True

    elif system == "Linux":
        import tarfile
        extract_dir = ventoy_installer.parent / "ventoy_extracted"
        info("Extracting Ventoy installer...")
        with tarfile.open(ventoy_installer) as t:
            t.extractall(extract_dir)

        ventoy_sh = None
        for f in extract_dir.rglob("Ventoy2Disk.sh"):
            ventoy_sh = f
            break

        if not ventoy_sh:
            error("Ventoy2Disk.sh not found in archive.")
            return False

        ventoy_sh.chmod(0o755)
        info(f"Running: sudo {ventoy_sh} -I {usb_path}")
        result = subprocess.run(
            ["sudo", str(ventoy_sh), "-I", usb_path]
        )
        if result.returncode != 0:
            error("Ventoy installation failed.")
            return False

    elif system == "Darwin":
        warn("macOS: Please install Ventoy manually using the LiveCD ISO.")
        warn("  1. Download the LiveCD: " + get_ventoy_download_url("latest"))
        warn("  2. Run it in VirtualBox or VMware and use the GUI.")
        warn("  3. Then copy ISOs to the USB drive manually.")
        return False

    success("Ventoy installed successfully!")
    return True


def copy_ventoy_config(usb_iso_root: Path, dry_run: bool = False):
    """Copy the Ventoy theme and JSON config to the USB drive."""
    header("Applying Hiren's Boot CD Excelsior Theme")
    ventoy_usb_dir = usb_iso_root.parent / "ventoy"
    ventoy_usb_dir.mkdir(parents=True, exist_ok=True)

    # Copy ventoy.json
    if VENTOY_CONFIG_SRC.exists():
        dest = ventoy_usb_dir / "ventoy.json"
        if not dry_run:
            shutil.copy2(VENTOY_CONFIG_SRC, dest)
        success(f"Copied ventoy.json → {dest}")
    else:
        warn("ventoy/ventoy.json not found. Skipping theme config.")

    # Copy theme directory
    themes_dest = ventoy_usb_dir / "themes" / "hbcd-excelsior"
    if THEME_SRC.exists():
        if not dry_run:
            if themes_dest.exists():
                shutil.rmtree(themes_dest)
            shutil.copytree(THEME_SRC, themes_dest)
        success(f"Copied theme → {themes_dest}")
    else:
        warn("Theme directory not found. Skipping custom theme.")


# ─── ISO Download ─────────────────────────────────────────────────────────────

def get_iso_dest(iso_key: str, iso_data: dict, usb_iso_root: Path) -> Path:
    """Get the destination path for an ISO on the USB drive."""
    category = iso_data.get("category", "Other")
    filename = iso_data.get("filename", f"{iso_key}.iso")
    return usb_iso_root / category / filename


def download_isos(
    catalog: dict,
    iso_keys: List[str],
    usb_iso_root: Path,
    dry_run: bool = False,
    skip_existing: bool = True
):
    """Download a list of ISOs to the USB drive."""
    isos = catalog.get("isos", {})
    header(f"Downloading {len(iso_keys)} ISO(s)")

    total_mb = sum(isos.get(k, {}).get("size_mb", 0) for k in iso_keys)
    info(f"Total estimated download: ~{total_mb:,} MB")

    if not dry_run:
        usb_iso_root.mkdir(parents=True, exist_ok=True)

    results = {"success": [], "skipped": [], "failed": [], "paid": []}

    for i, key in enumerate(iso_keys, 1):
        if key not in isos:
            warn(f"[{i}/{len(iso_keys)}] Unknown ISO key: {key} — skipping")
            continue

        iso = isos[key]
        print()
        print(c("bold", f"  [{i}/{len(iso_keys)}] {iso['name']}"))

        # Skip paid ISOs with a note
        if iso.get("requires_license"):
            warn(f"Requires a license/purchase. Skipping automatic download.")
            warn(f"  → Download manually from: {iso.get('download_page', iso.get('homepage', ''))}")
            results["paid"].append(key)
            continue

        dest = get_iso_dest(key, iso, usb_iso_root)

        # Skip if already exists and matches expected size
        if skip_existing and dest.exists():
            actual_mb = dest.stat().st_size / 1e6
            expected_mb = iso.get("size_mb", 0)
            if expected_mb > 0 and actual_mb >= expected_mb * 0.95:
                success(f"Already exists: {dest.name} ({actual_mb:.0f} MB) — skipping")
                results["skipped"].append(key)
                continue
            else:
                warn(f"Existing file appears incomplete ({actual_mb:.0f} MB / ~{expected_mb} MB). Re-downloading.")

        url = iso.get("mirror") or iso.get("url") or iso.get("download_page")
        sha256 = iso.get("sha256")

        if not url:
            warn(f"No direct download URL for {key}. Manual download required.")
            warn(f"  → {iso.get('download_page', iso.get('homepage', 'See documentation'))}")
            results["failed"].append(key)
            continue

        if dry_run:
            info(f"[DRY RUN] Would download: {url}")
            info(f"  → Destination: {dest}")
            results["success"].append(key)
            continue

        ok = download_file(url, dest, description=iso["name"], verify_sha256=sha256)
        if ok:
            results["success"].append(key)
        else:
            results["failed"].append(key)

    return results


# ─── Interactive Flow ──────────────────────────────────────────────────────────

def interactive_setup(catalog: dict, dry_run: bool = False):
    """Run the full interactive setup wizard."""
    banner()
    print(c("dim", "  This wizard will help you create a modern bootable USB rescue drive."))
    print(c("dim", "  You will need: a USB drive (≥8 GB recommended ≥32 GB for full), internet access."))
    print()

    # ── Step 1: Choose profile ────────────────────────────────────────────────
    header("Step 1 — Choose ISO Profile")
    list_profiles(catalog)

    valid_profiles = list(catalog.get("profiles", {}).keys())
    chosen_profile = prompt(
        f"Enter profile name ({'/'.join(valid_profiles)})",
        default="standard"
    )
    if chosen_profile not in valid_profiles:
        error(f"Invalid profile: {chosen_profile}")
        sys.exit(1)

    iso_keys = resolve_profile(catalog, chosen_profile)
    print()
    info(f"Selected profile: {c('bold', chosen_profile)} — {len(iso_keys)} ISOs")

    # Allow customization
    if confirm("Would you like to review and customize the ISO selection?", default=False):
        list_isos(catalog, profile=chosen_profile)
        add_more = prompt("Add additional ISO keys (comma-separated, or leave blank)", default="")
        if add_more.strip():
            extra = [k.strip() for k in add_more.split(",") if k.strip()]
            iso_keys = list(dict.fromkeys(iso_keys + extra))
        remove = prompt("Remove ISO keys (comma-separated, or leave blank)", default="")
        if remove.strip():
            to_remove = {k.strip() for k in remove.split(",")}
            iso_keys = [k for k in iso_keys if k not in to_remove]
        info(f"Final selection: {len(iso_keys)} ISOs")

    # ── Step 2: Ventoy installation ───────────────────────────────────────────
    header("Step 2 — Ventoy Bootloader")
    print(c("dim", "  Ventoy is the modern bootloader that powers this toolkit."))
    print(c("dim", "  It will be installed to your USB drive, which WILL ERASE IT."))
    print()

    install_ventoy_flag = confirm("Install Ventoy to a USB drive?", default=True)

    usb_path = None
    usb_iso_root = None
    ventoy_installer_path = None

    if install_ventoy_flag:
        drives = detect_usb_drives()
        if drives:
            print()
            info("Detected USB drives:")
            for i, d in enumerate(drives, 1):
                print(f"    {i}. {d['device']} — {d['model']} ({d['size_gb']} GB)")
            choice = prompt("Select drive number (or enter path manually)", default="1")
            if choice.isdigit() and 1 <= int(choice) <= len(drives):
                usb_path = drives[int(choice) - 1]["device"]
            else:
                usb_path = choice
        else:
            usb_path = prompt("Enter USB drive path (e.g. /dev/sdb or Disk 1)")

        # ISO destination on USB
        usb_iso_root_str = prompt(
            "Path to ISOs folder on USB (relative to USB root)",
            default="ISOs"
        )

        if not dry_run:
            # Download Ventoy
            version, _ = get_ventoy_latest_version()
            url = get_ventoy_download_url(version)
            with tempfile.TemporaryDirectory() as tmp:
                tmp_path = Path(tmp)
                ventoy_installer_path = tmp_path / url.split("/")[-1]
                ok = download_file(url, ventoy_installer_path, description=f"Ventoy {version}")
                if ok:
                    install_ventoy(usb_path, ventoy_installer_path, dry_run=dry_run)
                    # Determine mount point
                    if platform.system() == "Windows":
                        usb_drive_letter = prompt(
                            "Enter USB drive letter after Ventoy install (e.g. E:)",
                            default="E:"
                        )
                        usb_iso_root = Path(usb_drive_letter) / usb_iso_root_str
                    else:
                        mount_point = prompt(
                            "Enter USB mount point (e.g. /media/usb or /Volumes/VENTOY)",
                            default="/media/usb"
                        )
                        usb_iso_root = Path(mount_point) / usb_iso_root_str
                else:
                    error("Ventoy download failed. Cannot proceed with USB setup.")
                    sys.exit(1)
        else:
            usb_iso_root = Path("/dry-run-usb") / "ISOs"
    else:
        # No Ventoy install — ask where to put ISOs
        iso_dest_str = prompt(
            "Where should ISOs be saved?",
            default=str(Path.home() / "HBCD_Excelsior_ISOs")
        )
        usb_iso_root = Path(iso_dest_str)

    # ── Step 3: Download ISOs ─────────────────────────────────────────────────
    header("Step 3 — Download ISOs")
    skip_existing = confirm("Skip ISOs that are already downloaded?", default=True)
    print()

    if not confirm(
        f"Download {len(iso_keys)} ISOs to '{usb_iso_root}'? This may take a while.",
        default=True
    ):
        warn("Skipping ISO download.")
        return

    results = download_isos(
        catalog, iso_keys, usb_iso_root,
        dry_run=dry_run, skip_existing=skip_existing
    )

    # ── Step 4: Apply theme & config ──────────────────────────────────────────
    if install_ventoy_flag and usb_iso_root:
        copy_ventoy_config(usb_iso_root, dry_run=dry_run)

    # ── Summary ───────────────────────────────────────────────────────────────
    header("Setup Complete")
    success(f"Downloaded:  {len(results['success'])} ISOs")
    if results["skipped"]:
        info(f"Skipped (already exist): {len(results['skipped'])} ISOs")
    if results["paid"]:
        warn(f"Requires manual purchase: {len(results['paid'])} ISOs")
        for k in results["paid"]:
            iso = catalog["isos"].get(k, {})
            warn(f"  • {iso.get('name', k)}: {iso.get('download_page', iso.get('homepage', ''))}")
    if results["failed"]:
        error(f"Failed: {len(results['failed'])} ISOs")
        for k in results["failed"]:
            iso = catalog["isos"].get(k, {})
            error(f"  • {iso.get('name', k)}: {iso.get('download_page', '')}")

    print()
    print(c("bold", c("green", "  ✓ Hiren's Boot CD Excelsior is ready!")))
    if usb_iso_root:
        print(c("dim", f"  ISOs are in: {usb_iso_root}"))
    print(c("dim", "  Boot your computer from the USB drive to launch the rescue menu."))
    print()


def dry_run_mode(catalog: dict, profile: str = "full"):
    """Validate the catalog and check download URLs without downloading anything."""
    header("Dry Run — Validating ISO Catalog")
    iso_keys = resolve_profile(catalog, profile)
    isos = catalog.get("isos", {})

    for key in iso_keys:
        iso = isos.get(key, {})
        url = iso.get("mirror") or iso.get("url")
        if not url:
            warn(f"{key}: No direct URL")
            continue
        try:
            req = urllib.request.Request(url, method="HEAD",
                headers={"User-Agent": f"HBCDExcelsior/{PROJECT_VERSION}"})
            with urllib.request.urlopen(req, timeout=10) as resp:
                code = resp.getcode()
                length = resp.headers.get("Content-Length", "?")
                success(f"{key}: HTTP {code}, {int(length)/1e6:.0f} MB" if length != "?" else f"{key}: HTTP {code}")
        except Exception as e:
            error(f"{key}: {e}")


# ─── CLI Entry Point ───────────────────────────────────────────────────────────

def main():
    require_python()

    parser = argparse.ArgumentParser(
        description=f"{PROJECT_NAME} — Bootable USB Setup Tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python setup.py                     Interactive mode
  python setup.py --profile core      Download core profile non-interactively
  python setup.py --profile full      Download everything
  python setup.py --list-isos         List all available ISOs
  python setup.py --list-profiles     List all profiles and sizes
  python setup.py --dry-run           Validate URLs without downloading
  python setup.py --isos-only --profile standard --dest /media/usb/ISOs
        """
    )
    parser.add_argument("--profile", default=None,
                        help="ISO profile to use (core/standard/full/...)")
    parser.add_argument("--list-isos", action="store_true",
                        help="List all available ISOs and exit")
    parser.add_argument("--list-profiles", action="store_true",
                        help="List all profiles and exit")
    parser.add_argument("--dry-run", action="store_true",
                        help="Validate catalog and URLs without downloading")
    parser.add_argument("--isos-only", action="store_true",
                        help="Only download ISOs, skip Ventoy installation")
    parser.add_argument("--ventoy-only", action="store_true",
                        help="Only install Ventoy, skip ISO download")
    parser.add_argument("--dest", default=None,
                        help="Destination folder for ISOs (overrides interactive prompt)")
    parser.add_argument("--skip-existing", action="store_true", default=True,
                        help="Skip ISOs that are already downloaded (default: true)")
    parser.add_argument("--no-skip-existing", dest="skip_existing", action="store_false",
                        help="Re-download ISOs even if they already exist")

    args = parser.parse_args()
    catalog = load_catalog()

    if args.list_isos:
        list_isos(catalog, args.profile)
        return

    if args.list_profiles:
        list_profiles(catalog)
        return

    if args.dry_run:
        banner()
        dry_run_mode(catalog, args.profile or "full")
        return

    if args.profile and (args.isos_only or args.dest):
        # Non-interactive batch mode
        banner()
        iso_keys = resolve_profile(catalog, args.profile)
        dest = Path(args.dest) if args.dest else Path.cwd() / "ISOs"
        results = download_isos(catalog, iso_keys, dest, skip_existing=args.skip_existing)
        print()
        success(f"Done — {len(results['success'])} downloaded, "
                f"{len(results['skipped'])} skipped, "
                f"{len(results['failed'])} failed")
        return

    # Default: interactive
    interactive_setup(catalog, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
