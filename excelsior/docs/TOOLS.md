# Hiren's Boot CD Excelsior — Complete Tool Catalog

> **Branch**: `Hiren-s-Boot-CD-Excelsior`  
> **Total Tools**: 37  
> **All tools are free and open-source.**

---

## 🔵 Disk Tools

Tools for partitioning, formatting, cloning, and diagnosing drives.

| Tool | Version | Description | Replaces (Old HBCD) |
|---|---|---|---|
| **GParted** | 1.6.0 | Graphical partition editor | Partition Magic, Acronis Disk Director |
| **parted** | 3.6 | GNU Parted CLI (MBR + GPT) | fdisk |
| **gdisk** | 1.0.9 | GPT-specific partition tool | fdisk on UEFI systems |
| **ntfs-3g** | 2022.10.3 | Read/write Windows NTFS volumes | N/A |
| **e2fsprogs** | 1.47 | ext2/3/4 tools (fsck, mkfs, etc.) | N/A |
| **dosfstools** | 4.2 | FAT/FAT32 tools (mkfs.fat, fsck.fat) | N/A |
| **smartmontools** | 7.4 | S.M.A.R.T. drive health monitoring | HDD Scan, CrystalDiskInfo |
| **hdparm** | 9.65 | Drive parameters, ATA secure erase | HDD Scan |
| **badblocks** | 1.47 | Surface scan for bad sectors | HDDaReg, Victoria |

---

## 🟢 Data Recovery Tools

Recover files, partitions, and data from damaged or formatted media.

| Tool | Version | Description | Replaces (Old HBCD) |
|---|---|---|---|
| **TestDisk** | 7.2 | Partition recovery + boot sector repair | GetDataBack, PTDD |
| **PhotoRec** | 7.2 | File carving from damaged/formatted media | Recuva, PC Inspector |
| **ddrescue** | 1.28 | Forensic disk copy — works around bad sectors | HDD Regenerator |
| **extundelete** | 0.2.4 | Undelete files from ext3/ext4 | Recuva (Linux ext variant) |

---

## 🔴 Security Tools

Offline password recovery, antivirus scanning, and rootkit detection.

| Tool | Version | Description | Replaces (Old HBCD) |
|---|---|---|---|
| **chntpw** | 140201 | Offline Windows password reset + registry editor | NT Password Editor |
| **ophcrack** | 3.8.0 | Windows password hash cracker (rainbow tables) | N/A |
| **ClamAV** | 1.3.0 | Offline antivirus scanner | McAfee Stinger, Kaspersky VRT |
| **chkrootkit** | 0.58b | Rootkit detection | N/A |
| **rkhunter** | 1.4.6 | Rootkit and backdoor scanner | N/A |

---

## 🟡 System & Boot Repair

Bootloader repair, hardware detection, system diagnostics.

| Tool | Version | Description | Replaces (Old HBCD) |
|---|---|---|---|
| **GRUB2 (grub-install)** | 2.12 | Reinstall GRUB2 / fix bootloader | BootICE, EasyBCD |
| **efibootmgr** | 18 | Manage UEFI boot entries | BootICE (UEFI) |
| **os-prober** | 1.81 | Detect all installed operating systems | N/A |
| **hwinfo** | 23.2 | Full hardware detection | CPU-Z, GPU-Z, HWiNFO |
| **inxi** | 3.3.31 | System information report | Speccy, SIW |
| **dmidecode** | 3.5 | DMI/SMBIOS dump (BIOS, RAM slots) | CPU-Z (motherboard tab) |
| **stress-ng** | 0.17 | CPU/RAM/I-O stress testing | Prime95, FurMark |
| **memtester** | 4.6.0 | Userspace RAM testing | RAM tests in old HBCD |
| **htop** | 3.3.0 | Interactive process monitor | Task Manager |
| **btop** | 1.3.0 | Rich resource monitor | Task Manager (enhanced) |
| **Memtest86+** | 7.00 | Standalone UEFI/BIOS RAM tester | Old Memtest86 |

---

## 🟣 Network Tools

Scanning, packet capture, remote access, and file transfer.

| Tool | Version | Description | Replaces (Old HBCD) |
|---|---|---|---|
| **nmap** | 7.95 | Network scanner and auditor | Angry IP Scanner |
| **Wireshark / tshark** | 4.2.0 | Packet capture and analysis | N/A |
| **OpenSSH** | 9.7 | SSH client and server | PuTTY (client) |
| **rsync** | 3.3.0 | File sync and backup over network | XCOPY, robocopy |
| **curl / wget** | — | File downloads | N/A |

---

## 🔵 Utility Tools

File management, editors, and general-purpose utilities.

| Tool | Version | Description | Replaces (Old HBCD) |
|---|---|---|---|
| **Midnight Commander (mc)** | 4.8.31 | Dual-pane file manager | Total Commander |
| **hexedit** | 1.6 | Terminal hex editor | HxD, WinHex |
| **nano** | 7.2 | Simple text editor | Notepad |
| **vim** | 9.1 | Advanced text editor | Notepad++ |
| **p7zip** | 17.05 | 7-Zip CLI — ZIP, 7z, RAR, TAR | 7-Zip, WinRAR |

---

## Adding a Tool

```bash
# Interactive mode
bash excelsior/scripts/add-tool.sh --interactive

# One-liner
bash excelsior/scripts/add-tool.sh \
  --name "toolname" \
  --version "1.0" \
  --category "utility" \
  --description "What it does" \
  --url "https://example.com" \
  --license "GPL-2.0" \
  --package "pacman-package-name"
```

This updates `excelsior/tools/MANIFEST.json`. Then open a PR!

---

## Removed from Old HBCD

The following tool categories from the original Hiren's BootCD are **not included** because they were Windows-specific or obsolete:

| Old Category | Reason Removed |
|---|---|
| Windows XP Mini PE | Unsupported, insecure, BIOS-only |
| DOS Tools | Incompatible with modern filesystems |
| HxD, WinHex | Replaced by `hexedit` |
| Partition Magic | Replaced by GParted |
| Acronis Rescue | Replaced by Clonezilla scripts + `ddrescue` |
| Malwarebytes | Replaced by ClamAV |
| CPU-Z / GPU-Z | Replaced by `hwinfo`, `inxi` |
| CrystalDiskInfo | Replaced by `smartmontools` |
| mkisofs.exe | Replaced by `xorriso` (cross-platform) |
