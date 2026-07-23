<p align="center">
  <img src="img/hbcd-logo.png" alt="Hiren's Boot CD Excelsior" width="200"/>
</p>

<h1 align="center">Hiren's Boot CD — Excelsior</h1>
<p align="center">
  <strong>The modern, open-source revival of the legendary rescue toolkit</strong><br/>
  UEFI · Legacy BIOS · USB Bootable · Cross-Platform · Linux-based
</p>

<p align="center">
  <a href="https://github.com/HBCD/Hiren-s-Boot-CD-reborn/tree/Hiren-s-Boot-CD-Excelsior">
    <img src="https://img.shields.io/badge/branch-Excelsior-blueviolet?style=for-the-badge" alt="Branch"/>
  </a>
  <a href="https://github.com/HBCD/Hiren-s-Boot-CD-reborn/actions">
    <img src="https://img.shields.io/github/actions/workflow/status/HBCD/Hiren-s-Boot-CD-reborn/build-iso.yml?style=for-the-badge&label=ISO+Build" alt="Build Status"/>
  </a>
  <img src="https://img.shields.io/badge/boot-UEFI%20%2B%20BIOS-brightgreen?style=for-the-badge" alt="UEFI + BIOS"/>
  <img src="https://img.shields.io/badge/license-GPL--3.0-blue?style=for-the-badge" alt="License"/>
</p>

---

## What is Hiren's Boot CD Excelsior?

**Hiren's Boot CD Excelsior** is a complete modernization of the classic Hiren's BootCD rescue toolkit. The original (and its "Reborn" fork) relied on Windows XP Mini PE, Grub4dos, and DOS-era tools — none of which work on hardware made after 2015.

**Excelsior fixes everything:**

| Feature | Old (Reborn) | New (Excelsior) |
|---|---|---|
| Boot mode | Legacy BIOS only | ✅ UEFI (x64 + ARM64) **and** Legacy BIOS |
| USB bootable | Requires special tool | ✅ `dd`-compatible hybrid ISO |
| Base OS | Windows XP Mini PE | ✅ Modern Linux (SystemRescue-based) |
| Bootloader | Grub4dos (2008) | ✅ GRUB2 with graphical theme |
| Tool format | Windows .exe only | ✅ Native Linux tools (open-source) |
| Build system | mkisofs.exe (Windows) | ✅ xorriso + bash (Linux/WSL/CI) |
| CI/CD | None | ✅ GitHub Actions auto-build |
| Hardware support | Pre-2012 | ✅ All modern hardware |

---

## 🚀 Quickstart

### Flash to USB (Recommended)

```bash
# Download the latest Excelsior ISO from Releases
# Then flash to USB (replace /dev/sdX with your USB drive)
sudo dd if=Excelsior.iso of=/dev/sdX bs=4M status=progress oflag=sync

# Or use the helper script:
sudo bash excelsior/scripts/create-usb.sh Excelsior.iso /dev/sdX
```

> **Windows users**: Use [Rufus](https://rufus.ie/) or [Ventoy](https://www.ventoy.net/) to flash the ISO.

### Boot Menu Options

When you boot from the Excelsior USB/CD, the GRUB2 menu presents:

1. **SystemRescue Live** — Full Linux rescue environment with all tools
2. **Memtest86+** — Modern memory diagnostics (UEFI native)
3. **Hardware Detection Tool (HDT)** — BIOS-level hardware inventory
4. **GParted Live** — Graphical disk partitioning
5. **Boot from local disk** — Pass through to installed OS

---

## 🛠 Included Tools

> Full list: [excelsior/docs/TOOLS.md](excelsior/docs/TOOLS.md)

### Disk Tools
| Tool | Purpose |
|---|---|
| `gparted` | Graphical partition editor |
| `parted` / `fdisk` / `gdisk` | CLI partitioning (MBR + GPT) |
| `testdisk` | Partition recovery & boot sector repair |
| `photorec` | File/photo recovery from damaged media |
| `smartmontools` | Drive health (S.M.A.R.T.) diagnostics |
| `hdparm` | Drive benchmarking and parameters |
| `badblocks` | Surface scan for bad sectors |
| `clonezilla` (scripts) | Disk/partition imaging and cloning |
| `ddrescue` | Forensic disk imaging / rescue copying |

### System & Boot Repair
| Tool | Purpose |
|---|---|
| `boot-repair` | Automated GRUB/Windows bootloader fix |
| `chntpw` | Offline Windows password reset + registry editor |
| `ntfs-3g` | Read/write NTFS volumes from Linux |
| `os-prober` | Detect installed operating systems |
| `efibootmgr` | Manage UEFI boot entries |
| `grub-install` | Reinstall GRUB2 bootloader |

### Security & Recovery
| Tool | Purpose |
|---|---|
| `clamav` | Offline virus scanning |
| `ophcrack` | Windows password hash cracker |
| `chkrootkit` | Rootkit detection |
| `rkhunter` | Rootkit/backdoor scanner |

### Network
| Tool | Purpose |
|---|---|
| `nmap` | Network scanner |
| `wireshark` / `tshark` | Packet capture and analysis |
| `netcat` / `ncat` | Network debugging |
| `wget` / `curl` | File downloads |
| `openssh` | SSH client/server |

### System Diagnostics
| Tool | Purpose |
|---|---|
| `hwinfo` / `lshw` | Full hardware inventory |
| `inxi` | System information report |
| `dmidecode` | DMI/SMBIOS hardware info |
| `stress-ng` | CPU/memory/disk stress testing |
| `memtester` | RAM testing from Linux |
| `htop` / `btop` | System resource monitoring |

### File Management
| Tool | Purpose |
|---|---|
| `mc` | Midnight Commander (Norton Commander-style) |
| `rsync` | File synchronization and backup |
| `7zip` / `tar` | Archive handling |
| `hexedit` | Hex editor |
| `nano` / `vim` | Text editors |

---

## 🔨 Building the ISO

See full instructions: [excelsior/docs/HOW-TO-BUILD.md](excelsior/docs/HOW-TO-BUILD.md)

### Quick Build (Linux / WSL)

```bash
git clone https://github.com/HBCD/Hiren-s-Boot-CD-reborn.git
cd Hiren-s-Boot-CD-reborn
git checkout Hiren-s-Boot-CD-Excelsior
sudo bash excelsior/scripts/build.sh
# Output: Excelsior.iso
```

### GitHub Actions (Automatic)

Every push to this branch triggers the [build-iso.yml](.github/workflows/build-iso.yml) workflow. Download the ISO from the Actions artifacts tab or from [Releases](https://github.com/HBCD/Hiren-s-Boot-CD-reborn/releases).

---

## 📁 Repository Structure

```
Hiren-s-Boot-CD-reborn/
├── excelsior/
│   ├── boot/
│   │   ├── grub/
│   │   │   ├── grub.cfg          # GRUB2 boot menu (UEFI + BIOS)
│   │   │   └── themes/excelsior/ # Custom boot theme
│   │   └── isolinux/
│   │       └── isolinux.cfg      # Legacy BIOS fallback
│   ├── scripts/
│   │   ├── build.sh              # Main ISO build script
│   │   ├── create-usb.sh         # USB flash helper
│   │   ├── add-tool.sh           # Add/update tool in manifest
│   │   └── verify-iso.sh         # ISO integrity verification
│   ├── tools/
│   │   ├── MANIFEST.json         # Master tool catalog
│   │   ├── disk/
│   │   ├── network/
│   │   ├── security/
│   │   ├── recovery/
│   │   └── system/
│   └── docs/
│       ├── TOOLS.md              # Full tool list
│       ├── HOW-TO-BUILD.md       # Build guide
│       ├── HOW-TO-CONTRIBUTE.md  # Contribution guide
│       └── CHANGELOG.md          # Version history
├── .github/
│   └── workflows/
│       └── build-iso.yml         # CI/CD pipeline
└── README.md                     # This file
```

---

## 🤝 Contributing

We welcome contributions! Please read [excelsior/docs/HOW-TO-CONTRIBUTE.md](excelsior/docs/HOW-TO-CONTRIBUTE.md) before submitting a PR.

Ways to contribute:
- 🐛 Report bugs or broken tools in [Issues](https://github.com/HBCD/Hiren-s-Boot-CD-reborn/issues)
- 🔧 Add new tools by running `bash excelsior/scripts/add-tool.sh`
- 📖 Improve documentation
- 🖥 Test on real hardware and report compatibility

---

## 📜 License

This project is licensed under the **GNU General Public License v3.0**.
All included tools are free and open-source with their own respective licenses listed in [excelsior/tools/MANIFEST.json](excelsior/tools/MANIFEST.json).

---

## 🙏 Credits

- **Original Hiren's BootCD** — Hiren Patel (the legend)
- **HBCD/Hiren-s-Boot-CD-reborn** — The HBCD community for keeping it alive
- **SystemRescue** — The base rescue environment
- **GRUB2 Project** — The modern bootloader
- **All open-source tool authors** — Listed in MANIFEST.json
