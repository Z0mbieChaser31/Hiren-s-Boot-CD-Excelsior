# Changelog

All notable changes to **Hiren's Boot CD Excelsior** are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versions follow [Semantic Versioning](https://semver.org/).

---

## [Unreleased] — Excelsior 1.0.0

### 🏗 Architecture Changes (Breaking)

- **REPLACED** Grub4dos bootloader with **GRUB2** — adds full UEFI (x64) support
- **REPLACED** legacy ISOLINUX-only boot with **hybrid ISO** (UEFI + BIOS in one file)
- **REPLACED** Windows XP Mini PE with **SystemRescue** Linux live environment
- **REPLACED** DOS-era tools with native Linux open-source equivalents
- **REPLACED** mkisofs.exe (Windows-only) with **xorriso** (cross-platform)
- **ADDED** GitHub Actions CI/CD pipeline — auto-builds ISO on every push
- **ADDED** JSON-based tool manifest (`MANIFEST.json`) for structured tool tracking
- **ADDED** USB flash helper script (`create-usb.sh`)
- **ADDED** ISO verification script with QEMU test boot (`verify-iso.sh`)
- **ADDED** Tool management script (`add-tool.sh`)

### 🛠 Boot Environment

- **ADDED** GRUB2 graphical boot menu with custom Excelsior theme
- **ADDED** UEFI boot via `EFI/BOOT/BOOTX64.EFI`
- **ADDED** Legacy BIOS boot via ISOLINUX fallback
- **ADDED** Boot options: SystemRescue (console, graphical, network, RAM-copy modes)
- **ADDED** GParted Live entry in boot menu
- **ADDED** Memtest86+ 7.x (UEFI-native + BIOS) entry
- **ADDED** Hardware Detection Tool (HDT) entry for Legacy BIOS
- **ADDED** "Boot from local disk" chainloader entry (UEFI + BIOS)
- **ADDED** Advanced submenu (safe mode, serial console, RAM copy)

### 🔧 Tools Added

**Disk Tools**: gparted, parted, gdisk, ntfs-3g, e2fsprogs, dosfstools, smartmontools, hdparm, badblocks

**Recovery Tools**: testdisk, photorec, ddrescue, extundelete

**Security Tools**: chntpw, ophcrack, clamav, chkrootkit, rkhunter

**System Tools**: grub-install, efibootmgr, os-prober, hwinfo, inxi, dmidecode, stress-ng, memtester, htop, btop, memtest86+

**Network Tools**: nmap, wireshark/tshark, openssh, rsync, curl, wget

**Utility Tools**: midnight commander (mc), hexedit, nano, vim, p7zip

### 📖 Documentation

- **ADDED** Complete `README.md` rewrite with quickstart, tool table, and architecture comparison
- **ADDED** `excelsior/docs/TOOLS.md` — full tool catalog with replacement mapping
- **ADDED** `excelsior/docs/HOW-TO-BUILD.md` — build guide (Linux, WSL, CI, manual)
- **ADDED** `excelsior/docs/HOW-TO-CONTRIBUTE.md` — contribution guide and PR checklist

### 🗑 Removed

- Windows XP Mini PE environment
- DOS tools directory
- Grub4dos (`grldr`) bootloader
- `mkisofs.exe` (Windows-only ISO builder)
- `cygwin1.dll` (Cygwin dependency for mkisofs)
- Old `.bat` build scripts (`Make ISO -boot grub4dos.bat`, `Make ISO -boot isolinux.bat`)

---

## Historical Reference

### Hiren's Boot CD 15.2 (Original — circa 2012)

The last official release of the original Hiren's Boot CD:
- Based on Windows XP Mini PE
- Grub4dos bootloader (BIOS only)
- Over 200 freeware and shareware tools
- No UEFI support
- No USB hybrid boot

### Hiren's Boot CD Reborn (Community — 2016-2019)

HBCD community attempt to update the original:
- Still based on Windows XP PE + DOS tools
- Updated some tool versions
- Added ISOLINUX alongside Grub4dos
- No UEFI support
- Eventually abandoned

### Hiren's Boot CD PE (Official Team — 2017-present)

Official modern successor at hirensbootcd.org:
- Windows 11 PE environment
- UEFI support
- Actively maintained

### Hiren's Boot CD Excelsior (This Project — 2026-present)

Community-driven, fully open-source modernization:
- Linux-based (no Windows license required)
- Full UEFI + Legacy BIOS support
- Open-source tools only
- GitHub Actions CI/CD
- USB hybrid ISO
