# USB Setup Guide — Hiren's Boot CD Excelsior

Step-by-step guide for creating your rescue USB drive on Windows, Linux, or macOS.

---

## What You Need

- **USB drive** — 8 GB minimum; 32 GB+ recommended for standard/full profiles
- **Internet connection** — for downloading ISOs
- **Python 3.8+** — for running `setup.py` (auto-detected or auto-installed by `setup.ps1` on Windows)
- **Admin/root access** — required for installing Ventoy to the USB drive

---

## Step 1: Clone the Repository

```bash
git clone --depth=1 https://github.com/HBCD/Hiren-s-Boot-CD-reborn.git
cd Hiren-s-Boot-CD-reborn
```

Or download the ZIP from GitHub → **Code → Download ZIP** and extract it.

---

## Step 2: Run the Setup Script

### Windows

1. **Right-click** `setup.ps1` → **Run with PowerShell**
   - If blocked by execution policy, open PowerShell as Administrator:
     ```powershell
     Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass
     .\setup.ps1
     ```
2. Follow the interactive wizard. It will:
   - Check for Python (installs via `winget` if missing)
   - Let you choose a profile
   - Detect connected USB drives
   - Download Ventoy and install it
   - Download the selected ISOs

**Common Windows commands:**
```powershell
.\setup.ps1                           # Interactive wizard (recommended)
.\setup.ps1 -Profile core            # Core profile (~4 GB)
.\setup.ps1 -Profile standard        # Standard profile (~10 GB)
.\setup.ps1 -Profile full            # Everything (~35 GB)
.\setup.ps1 -ListIsos                # Show all available ISOs
.\setup.ps1 -DryRun                  # Validate URLs without downloading
.\setup.ps1 -IsosOnly -Dest "E:\ISOs" -Profile standard  # ISOs only, no Ventoy
```

### Linux

```bash
chmod +x setup.sh
./setup.sh                           # Interactive wizard

# Non-interactive examples:
./setup.sh --profile standard
./setup.sh --isos-only --profile standard --dest /media/$USER/VENTOY/ISOs
./setup.sh --list-isos
./setup.sh --dry-run
```

### macOS

```bash
chmod +x setup.sh
./setup.sh --profile core
```

> **Note**: macOS does not support automatic Ventoy installation from the script (Ventoy has no native macOS installer).
> The script will download ISOs to a local folder. You can then install Ventoy via a Linux VM and copy the ISOs manually.

### Direct Python (any OS)

```bash
python setup.py                          # Interactive wizard
python setup.py --list-profiles          # See all profiles and sizes
python setup.py --list-isos              # See all available ISOs
python setup.py --profile full           # Download everything
python setup.py --dry-run                # Validate URLs without downloading
python setup.py --isos-only --dest /path/to/usb/ISOs --profile standard
python setup.py --no-skip-existing --profile core  # Force re-download
```

---

## Step 3: Install Ventoy Manually (Alternative)

If you prefer to install Ventoy yourself rather than using the script:

### Windows (GUI)
1. Download Ventoy from https://www.ventoy.net/en/download.html
2. Extract the ZIP
3. Run **`Ventoy2Disk.exe`**
4. Select your USB drive from the dropdown
5. Click **Install** *(this will erase all data on the USB drive!)*

### Linux (Command Line)
```bash
# Find your USB drive first
lsblk

# Download latest Ventoy
wget $(curl -s https://api.github.com/repos/ventoy/Ventoy/releases/latest \
  | grep browser_download_url | grep linux | cut -d'"' -f4) -O ventoy.tar.gz

# Extract and install (replace /dev/sdb with YOUR drive)
tar -xzf ventoy.tar.gz
cd ventoy-*/
sudo ./Ventoy2Disk.sh -I /dev/sdb
```

> ⚠️ **WARNING**: Double-check the device name with `lsblk` before running. Ventoy will **erase** the selected drive.

---

## Step 4: Organize ISOs on the USB Drive

After Ventoy installs, your USB appears as a normal storage device. Copy ISO files into the `ISOs/` folder organized by category:

```
VENTOY (USB Drive)/
├── ISOs/
│   ├── Windows/
│   │   ├── HBCD_PE_x64.iso
│   │   └── sergei_strelec.iso
│   ├── Linux/
│   │   ├── systemrescue-latest.iso
│   │   ├── rescuezilla-latest-amd64.iso
│   │   └── gparted-live-latest-amd64.iso
│   ├── Diagnostics/
│   │   └── memtest86plus.iso
│   ├── Security/
│   │   ├── tails-amd64-latest.iso
│   │   └── kali-linux-latest-live-amd64.iso
│   ├── Network/
│   │   └── netboot.xyz.iso
│   └── Legacy/
│       └── hbcd-15.2.iso
└── ventoy/
    ├── ventoy.json          ← copy from this repo
    └── themes/
        └── hbcd-excelsior/  ← copy from this repo
```

The `setup.py` script handles all of this automatically.

---

## Step 5: Apply the Custom Theme & Menu Config

Copy the `ventoy/` folder from this repository to the root of your USB drive:

```bash
# Linux / macOS
cp -r ventoy/ /media/$USER/VENTOY/

# Windows (PowerShell)
Copy-Item -Recurse .\ventoy\ "E:\"
```

This applies:
- **Custom boot theme** — dark UI with HBCD Excelsior branding
- **Menu aliases** — friendly names for each ISO with emoji icons
- **Category organization** — ISOs grouped by type in the boot menu

---

## Step 6: Boot from USB

1. **Insert** the USB drive into the target computer
2. **Restart** the computer
3. **Enter the boot menu** by pressing one of these keys right after the manufacturer logo:

| Manufacturer | Key(s) |
|---|---|
| Dell | `F12` |
| HP | `F9`, `F10`, `Esc` |
| Lenovo | `F12`, `F11` |
| ASUS | `F8`, `Esc` |
| MSI | `F11` |
| Gigabyte | `F12` |
| ASRock | `F11` |
| Surface | Hold **Volume Down** + Power |

4. **Select your USB drive** from the boot menu
5. **Choose a rescue environment** from the Excelsior menu

> **Tip**: If the computer boots straight to Windows without showing a boot menu, disable **Fast Startup** in Windows (Power Options → Turn on fast startup → uncheck) and/or disable **Fast Boot** in your UEFI/BIOS settings.

---

## Troubleshooting

### USB not showing up in boot menu
- Try a different USB port (USB 2.0 ports are more universally compatible for booting)
- Disable **Secure Boot** temporarily in UEFI settings, boot the USB, then re-enable
- Try toggling **CSM (Compatibility Support Module)** in UEFI settings

### "Ventoy not found" or garbled boot menu
- Re-install Ventoy to the USB using `Ventoy2Disk.exe -I` (force install)
- Make sure the USB is formatted as a single partition by Ventoy, not manually

### An ISO boots to a black screen or kernel panic
- Try pressing `e` in GRUB to edit boot parameters and add `nomodeset` or `noapic`
- Some ISOs need to be booted in **Legacy BIOS mode** — in Ventoy, press **F6** on the ISO entry to switch mode
- Verify the ISO file size matches the expected size (re-download if corrupt)

### Download was interrupted / file is incomplete
```bash
python setup.py --no-skip-existing --profile <name>
```

### Python not found (Linux/macOS)
```bash
# Ubuntu/Debian
sudo apt install python3

# Fedora
sudo dnf install python3

# Arch
sudo pacman -S python

# macOS (Homebrew)
brew install python3
```

---

## Updating ISOs

Check for and download newer versions:

```bash
# Re-download all ISOs in a profile (overwrites existing)
python setup.py --no-skip-existing --profile standard

# Validate that all current download URLs still work
python setup.py --dry-run
```

To add ISOs not in the catalog, see [ADDING_CUSTOM_TOOLS.md](ADDING_CUSTOM_TOOLS.md).
