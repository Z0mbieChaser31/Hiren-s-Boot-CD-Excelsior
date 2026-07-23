# Legacy HBCD 15.2 — Documentation & Compatibility

The original Hiren's Boot CD 15.2 files are preserved in this repository for historical reference and use with very old hardware that cannot run modern tools.

---

## What Is HBCD 15.2?

Hiren's BootCD 15.2 was the final release of the original Hiren's BootCD, shipped in **October 2012**. At the time, it was considered the most comprehensive PC rescue toolkit available — an all-in-one bootable CD/USB that included:

- **Mini Windows XP** — a portable Windows XP environment that runs from CD, USB, or RAM, with built-in LAN/WLAN drivers and tools
- **MS-DOS programs** — a floppy image containing 50+ DOS-based diagnostic utilities
- **Parted Magic 2012** — a Linux-based partition and recovery environment
- **250+ Windows utilities** — antivirus, disk diagnostics, password recovery, file recovery, partitioning, registry tools, and more

See [CD/HBCD.txt](../CD/HBCD.txt) for the complete tool list with version numbers.

---

## Why It No Longer Works on Modern Hardware

| Problem | Details |
|---------|---------|
| **No UEFI support** | `grub4dos` and `isolinux 4.05` are Legacy BIOS-only bootloaders. Any computer with UEFI firmware (post-~2012) will not boot this ISO unless CSM is enabled. |
| **Mini Windows XP is EOL** | Windows XP reached End of Life in April 2014. It has no drivers for USB 3.0, NVMe SSDs, modern Intel/AMD chipsets, or GPUs made after ~2012. |
| **32-bit only** | All Windows tools are 32-bit. Modern 64-bit-only systems (rare but growing) cannot run them. |
| **Antivirus definitions from 2012** | Avira, Malwarebytes, ClamWin definitions are 14 years old and will not detect modern malware. |
| **ComboFix discontinued** | BleepingComputer officially discontinued ComboFix in 2021 — it cannot be updated. |
| **DOS tools and old hardware** | DOS programs assume hardware interfaces (IDE, old SCSI) that don't exist on NVMe or modern SATA controllers without drivers. |

---

## When HBCD 15.2 Is Still Useful

✅ **Use HBCD 15.2 if you are working on:**
- A PC manufactured before **2012** with Legacy BIOS (no UEFI)
- Hardware where only MS-DOS tools (MHDD, HDAT2, SeaTools for DOS, etc.) are required
- Very old drives (IDE/PATA) that modern tools may not detect
- Archival / historical research of rescue tools
- Systems with very limited RAM (<256 MB) where modern live environments won't load

❌ **Do NOT rely on HBCD 15.2 if:**
- The computer has UEFI firmware (any PC made after ~2012)
- The primary drive is an NVMe SSD
- You need to repair Windows 8, 10, or 11
- You need current antivirus/malware scanning
- You're working with drives larger than 2 TB (MBR partition limit)

---

## Building the Legacy ISO

The legacy build files are preserved and functional. Run from the project root on Windows:

```batch
:: Build with grub4dos bootloader (recommended for legacy)
"Make ISO -boot grub4dos.bat"

:: Build with isolinux bootloader (alternative)
"Make ISO -boot isolinux.bat"
```

These scripts use `mkisofs.exe` (included in the repo root) to produce `MyHBCD.iso`.

> ⚠️ **Note**: These `.bat` files are deprecated and receive no updates. They are preserved for archival purposes only.

### Requirements for building
- Windows (any version)
- The `CD/` submodule must be checked out: `git submodule update --init --recursive`
- `mkisofs.exe` and `cygwin1.dll` in the project root (already present)

---

## Using the Legacy ISO on a Ventoy USB

You can include HBCD 15.2 alongside modern tools on your Ventoy drive:

1. Build the legacy ISO using the `.bat` files above (produces `MyHBCD.iso`)
2. Copy it to your USB drive at: `ISOs/Legacy/hbcd-15.2.iso`
3. Ventoy will detect it automatically and add it to the boot menu
4. The `ventoy/ventoy.json` in this project already includes a menu alias for it

> **Critical**: When booting HBCD 15.2 from Ventoy, you **must** use **Legacy BIOS mode**.
> In the Ventoy boot menu, highlight the ISO and press **F6** to switch boot mode before launching.
> UEFI mode will fail.

---

## Legacy Bootloader Details

The original project uses two bootloader options:

### grub4dos (menu.lst)
- File: [`CD/HBCD/menu.lst`](../CD/HBCD/menu.lst)
- Universal boot loader based on GNU GRUB — works from DOS, Linux, or Windows boot manager
- Handles Mini Windows XP, DOS programs, Parted Magic, password changers, and more

### isolinux (isolinux.cfg)
- File: [`CD/HBCD/isolinux.cfg`](../CD/HBCD/isolinux.cfg)
- Standard Linux bootloader for ISO 9660 (El Torito) media
- Used when booting the ISO as a CD/DVD

Both bootloaders **only support Legacy BIOS** — this is why the project is being rebuilt with Ventoy.

---

## Legacy Tool List by Category

For the complete 250+ tool inventory, see [`CD/HBCD.txt`](../CD/HBCD.txt).

**Categories included in HBCD 15.2:**

| Category | Notable Tools |
|----------|---------------|
| Antivirus | Avira 2012, ClamWin, Malwarebytes 1.51, TDSSKiller, Spybot |
| Backup | DriveImage XML, CloneDisk, FastCopy, TeraCopy, ImgBurn |
| BIOS/CMOS | !BIOS, CMOS Save/Restore, UniFlash, BIOS Cracker |
| Browsers/File Managers | Opera 12, Total Commander 8, 7-Zip, Everything |
| Disk Tools | CrystalDiskInfo, HDTune, MHDD, Victoria, SeaTools, HDAT2 |
| MBR Tools | BootICE, Grub4Dos, MBRWizard, HDHacker |
| Network | Angry IP Scanner, PuTTY, WinSCP, SmartSniff, TFTPd32 |
| Partition | GParted 0.14, Partition Wizard 7, TestDisk, PhotoRec |
| Password | Offline NT Password Changer, NTPWEdit, ProduKey, Kon-Boot |
| Recovery | Recuva, DiskDigger, TestDisk, IsoBuster |
| Registry | ERUNT, RegShot, RegScanner, Registry Restore Wizard |
| System Info | CPU-Z, GPU-Z, Speccy, HWiNFO, SIW |
| Testing | MemTest86+, Prime95, HDD Scan, GoldMemory |
| Mini Windows XP | Full XP PE with 300 WiFi/LAN drivers, Remote Desktop |

---

## Frequently Asked Questions

**Can I still update the tools in HBCD 15.2?**
Not easily. The tools are bundled inside compressed archives within the submodule. Updating individual tools would require re-extracting, replacing, and recompressing. This is why the project now uses Ventoy with modern standalone ISOs instead.

**Where are the actual tool binaries?**
Most tools are inside 7z archives in `CD/HBCD/Programs/Files/` (a separate git submodule). They are not in this repo by default. Run `git submodule update --init --recursive` to download them, or build the ISO with the `.bat` files.

**Can I add HBCD 15.2 to a Rufus/Balena Etcher USB?**
Yes — treat `MyHBCD.iso` like any other bootable ISO. However, you can only put one ISO on the drive this way, which is why Ventoy is recommended instead.
