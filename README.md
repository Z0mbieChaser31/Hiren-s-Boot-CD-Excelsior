# Hiren's Boot CD Excelsior

<div align="center">

```
╔══════════════════════════════════════════════════════════════╗
║   ⚡ Hiren's Boot CD Excelsior — v2.0                        ║
║   The Modern Multi-OS Bootable USB Rescue Toolkit            ║
╚══════════════════════════════════════════════════════════════╝
```

**A complete rebuild of the legendary Hiren's Boot CD for the modern era.**

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
[![Python 3.8+](https://img.shields.io/badge/Python-3.8+-blue.svg)](https://python.org)
[![UEFI Ready](https://img.shields.io/badge/UEFI-Ready-green.svg)](#compatibility)
[![Legacy BIOS](https://img.shields.io/badge/Legacy%20BIOS-Supported-yellow.svg)](#compatibility)

</div>

---

## What Is This?

**Hiren's Boot CD Excelsior** is the modern successor to [Hiren's BootCD 15.2](CD/HBCD.txt) — the beloved rescue toolkit that last shipped in 2012. This project rebuilds it from the ground up for modern hardware, using [**Ventoy**](https://www.ventoy.net/) as the bootloader and a curated collection of current, actively-maintained rescue ISOs.

### Why a new version?
The original HBCD 15.2 no longer works on most modern computers because:
- ❌ **No UEFI support** — grub4dos + isolinux 4.05 are legacy BIOS only
- ❌ **Mini Windows XP** — EOL since 2014, incompatible with modern hardware
- ❌ **Outdated tools** — Avira 2012, ComboFix, etc. are non-functional today
- ❌ **DOS programs** — Cannot address NVMe, modern SATA, or USB 3.0
- ❌ **Windows-only build** — `.bat` + `mkisofs.exe` only runs on Windows

### What's new in Excelsior?
- ✅ **UEFI + Secure Boot + Legacy BIOS** — works on any computer made in the last 20 years
- ✅ **Cross-platform** — set up from Windows, Linux, or macOS
- ✅ **Actively maintained ISOs** — Hiren's PE (Win 11), SystemRescue, Kali, MemTest86+, and more
- ✅ **Maximum coverage** — Windows repair, Linux rescue, diagnostics, security/forensics, network boot
- ✅ **Modular profiles** — core (8 GB), standard (16 GB), full (64 GB), or fully custom
- ✅ **Auto-download manager** — one script sets everything up
- ✅ **Custom boot theme** — clean dark UI with category-organized menus

---

## Quick Start

### Requirements
- A USB drive (8 GB minimum; 32–64 GB recommended for standard/full profiles)
- Internet connection (for downloading ISOs)
- Python 3.8+ (auto-detected or auto-installed by the setup script)

### Windows

```powershell
# 1. Clone the repository
git clone https://github.com/HBCD/Hiren-s-Boot-CD-reborn.git
cd Hiren-s-Boot-CD-reborn

# 2. Run setup (right-click → Run with PowerShell, or in PowerShell terminal):
.\setup.ps1

# Or non-interactively with a specific profile:
.\setup.ps1 -Profile core
.\setup.ps1 -Profile standard
.\setup.ps1 -Profile full
```

### Linux

```bash
# 1. Clone the repository
git clone https://github.com/HBCD/Hiren-s-Boot-CD-reborn.git
cd Hiren-s-Boot-CD-reborn

# 2. Make executable and run
chmod +x setup.sh
./setup.sh

# Or with arguments:
./setup.sh --profile standard --isos-only --dest /media/usb/ISOs
```

### macOS

```bash
# Same as Linux
chmod +x setup.sh
./setup.sh --profile core
```

### Direct Python (any OS)

```bash
python setup.py                          # Interactive wizard
python setup.py --list-profiles          # See all profiles and sizes
python setup.py --list-isos              # See all available ISOs
python setup.py --profile full           # Download everything
python setup.py --dry-run                # Validate URLs without downloading
python setup.py --isos-only --dest /path/to/usb/ISOs --profile standard
```

---

## ISO Profiles

| Profile | Size | Description |
|---------|------|-------------|
| `core` | ~4 GB | Essential toolkit — Hiren's PE, SystemRescue, MemTest86+, GParted |
| `standard` | ~10 GB | Well-rounded — adds Rescuezilla, Clonezilla, HDAT2 |
| `full` | ~35 GB | Maximum coverage — everything including Kali, Tails, CAINE, Ubuntu |
| `windows-only` | ~5 GB | Windows PE environments only |
| `linux-only` | ~8 GB | Linux rescue environments only |
| `diagnostics` | ~1 GB | Hardware testing and diagnostics only |
| `security` | ~10 GB | Security and digital forensics tools |

---

## Included Tools (Full Profile)

### 🪟 Windows Repair & Recovery
| Tool | Description |
|------|-------------|
| **Hiren's BootCD PE** | Windows 11 PE with 100+ repair tools. Password reset, antivirus, disk management, and more |
| **Sergei Strelec WinPE** | Comprehensive Windows toolkit. Drivers, activation, deep system repair |
| **Microsoft DaRT PE** | Official Microsoft diagnostics and recovery toolset |

### 🐧 Linux Rescue Environments
| Tool | Description |
|------|-------------|
| **SystemRescue** | Gold standard Linux rescue system. GParted, TestDisk, PhotoRec, network tools |
| **Rescuezilla** | User-friendly GUI disk imaging and cloning. Compatible with Clonezilla images |
| **Clonezilla** | Professional partition/disk cloning over local drives or network |
| **GParted Live** | The definitive free partition editor. All modern partition types supported |
| **Ubuntu Live** | Best hardware compatibility. Full desktop for general recovery tasks |
| **Fedora Live** | Excellent modern hardware detection |
| **Debian Live** | Stable and lightweight. Great for older hardware |
| **KNOPPIX** | Comprehensive recovery. Legendary hardware auto-detection |
| **Parted Magic** | Professional disk management suite (paid) |

### 🔬 Hardware Diagnostics
| Tool | Description |
|------|-------------|
| **MemTest86+** | Open-source RAM testing. The industry standard |
| **MemTest86 (PassMark)** | UEFI RAM tester with graphical reports |
| **HDAT2** | Hard disk diagnostic and bad sector repair |

### 🔐 Security & Forensics
| Tool | Description |
|------|-------------|
| **Tails OS** | Anonymous OS. All traffic through Tor. Leaves zero traces |
| **Kali Linux** | 600+ penetration testing and security tools |
| **CAINE** | Digital forensics. All drives read-only by default for evidence integrity |
| **DEFT Zero** | Lightweight digital evidence and forensics toolkit |

### 🌐 Network Boot
| Tool | Description |
|------|-------------|
| **netboot.xyz** | Boot any OS over the internet (2 MB ISO!) |
| **iPXE** | Advanced network boot firmware |

### ⏳ Legacy (Preserved)
| Tool | Description |
|------|-------------|
| **HBCD 15.2** | Original Hiren's Boot CD for DOS tools and very old hardware |

---

## Compatibility

| Firmware | Supported |
|----------|-----------|
| UEFI (x64) | ✅ Yes |
| UEFI with Secure Boot | ✅ Yes (Ventoy Secure Boot module) |
| Legacy BIOS | ✅ Yes |
| UEFI (ARM64) | ⚠️ Partial (Ventoy experimental) |

| USB Type | Supported |
|----------|-----------|
| USB 2.0 | ✅ Yes (slower boot) |
| USB 3.0 / 3.1 / 3.2 | ✅ Yes (recommended) |
| USB-C | ✅ Yes (with adapter or native) |
| External SSD (USB) | ✅ Yes (fastest) |

---

## Project Structure

```
Hiren-s-Boot-CD-reborn/
├── setup.py                   # Main cross-platform setup script
├── setup.ps1                  # Windows PowerShell wrapper
├── setup.sh                   # Linux/macOS Bash wrapper
├── iso_catalog.json           # Machine-readable ISO catalog
├── README.md                  # This file
│
├── ventoy/
│   ├── ventoy.json            # Ventoy boot menu configuration
│   └── themes/
│       └── hbcd-excelsior/   # Custom GRUB2 boot theme
│           ├── theme.txt
│           ├── background.png
│           └── icons/
│
├── docs/
│   ├── USB_SETUP_GUIDE.md    # Detailed USB creation guide
│   ├── TOOLS_GUIDE.md        # "Which tool do I use for X?" guide
│   ├── ADDING_CUSTOM_TOOLS.md
│   └── LEGACY.md             # Legacy HBCD 15.2 documentation
│
└── CD/                        # Legacy HBCD 15.2 files (preserved)
    └── HBCD/
        ├── menu.lst           # grub4dos menu (legacy)
        ├── isolinux.cfg       # isolinux config (legacy)
        └── ...
```

---

## Contributing

Contributions are welcome! See [docs/ADDING_CUSTOM_TOOLS.md](docs/ADDING_CUSTOM_TOOLS.md) for how to:
- Add new ISOs to the catalog
- Update existing ISO download URLs and checksums
- Submit a new ISO profile

To report broken download links or outdated checksums, please open an issue.

---

## Legacy HBCD 15.2

The original Hiren's Boot CD 15.2 files are preserved in the `CD/` directory. You can still build the legacy ISO using:

```bash
# Windows only (legacy)
"Make ISO -boot grub4dos.bat"
# or
"Make ISO -boot isolinux.bat"
```

> ⚠️ **Note**: The legacy ISO requires a Legacy BIOS computer and will not boot on UEFI systems. See [docs/LEGACY.md](docs/LEGACY.md) for details.

---

## Credits

- **Original Hiren's BootCD** by Hiren Patel (hiren.info) — the inspiration
- **Ventoy** by longpanda — the modern multiboot bootloader powering this project
- **All ISO authors** — SystemRescue, Rescuezilla, Clonezilla, GParted, MemTest86+, Kali, Tails, CAINE, and all other tools included
- **HBCD Community** — contributors to this reborn project

---

## License

GPL-3.0 — see [LICENSE](LICENSE) for details.

The individual ISOs are subject to their own licenses. See each tool's homepage for details.
