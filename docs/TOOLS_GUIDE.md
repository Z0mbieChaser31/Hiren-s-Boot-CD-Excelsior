# Tools Guide — When to Use What

Quick reference for choosing the right rescue tool for any situation.

---

## Quick Decision Tree

```
What problem are you facing?
│
├── Computer won't boot at all
│   ├── Black screen after POST ──────────────────────► Hiren's BootCD PE or SystemRescue
│   ├── "NTLDR is missing" / "BOOTMGR missing" ────────► Hiren's BootCD PE (Boot Repair)
│   ├── Windows Startup Repair loop ────────────────────► Hiren's BootCD PE
│   └── Completely dead (POST failure) ────────────────► MemTest86+ (RAM), HDAT2 (HDD)
│
├── Windows problems
│   ├── Forgot Windows password ──────────────────────► Hiren's BootCD PE (NTPWEdit)
│   ├── Blue Screen of Death (BSOD) ──────────────────► Hiren's BootCD PE (BlueScreenView)
│   ├── Virus / ransomware infection ─────────────────► Hiren's BootCD PE (Malwarebytes)
│   ├── Registry corruption ──────────────────────────► Hiren's BootCD PE (Registry tools)
│   ├── Missing / corrupt system files ──────────────► Hiren's BootCD PE (sfc offline)
│   ├── Driver issues / unknown devices ─────────────► Hiren's BootCD PE (3DP Chip)
│   ├── Windows won't start (general) ───────────────► Hiren's BootCD PE or Sergei Strelec
│   └── Need to reinstall Windows ────────────────────► Sergei Strelec (WinNTSetup)
│
├── Hard drive / SSD problems
│   ├── Clicking sounds / read errors ────────────────► HDAT2, then ddrescue (SystemRescue)
│   ├── S.M.A.R.T. warnings ──────────────────────────► Hiren's BootCD PE (CrystalDiskInfo)
│   ├── Need to clone drive before it fails ──────────► Rescuezilla or Clonezilla
│   ├── Bad sectors ──────────────────────────────────► HDAT2 (regenerate), Victoria
│   ├── Slow performance / high temps ────────────────► Hiren's BootCD PE (HDTune)
│   └── Lost partition / corrupted partition table ───► SystemRescue (TestDisk)
│
├── Data recovery
│   ├── Accidentally deleted files ────────────────────► Hiren's BootCD PE (Recuva)
│   ├── Deleted partition ────────────────────────────► SystemRescue (TestDisk)
│   ├── Formatted drive ──────────────────────────────► SystemRescue (PhotoRec)
│   └── Corrupted filesystem ─────────────────────────► SystemRescue (fsck, ntfsfix)
│
├── Partitioning & disk management
│   ├── Resize / create / delete partitions ──────────► GParted Live
│   ├── Convert MBR ↔ GPT ────────────────────────────► GParted Live or Hiren's PE
│   ├── Full disk backup image ────────────────────────► Rescuezilla (GUI) / Clonezilla
│   └── Clone many machines over network ────────────► Clonezilla (multicast)
│
├── Memory (RAM) problems
│   ├── Random crashes / BSODs / freezes ────────────► MemTest86+ (run 2+ passes)
│   ├── UEFI system, need a detailed report ─────────► MemTest86 (PassMark edition)
│   └── Suspect specific DIMM slot ──────────────────► MemTest86+ (remove sticks one by one)
│
├── Network / internet from rescue environment
│   ├── Need a working browser ────────────────────────► Ubuntu Live or SystemRescue
│   ├── Need SSH / SCP / rsync access ───────────────► SystemRescue
│   ├── USB is almost full, need more tools ─────────► netboot.xyz (2 MB — boots over internet)
│   └── Need anonymous / secure browsing ───────────► Tails OS
│
├── Security & forensics
│   ├── Collect digital evidence safely ──────────────► CAINE (all drives read-only by default)
│   ├── Penetration testing / auditing ──────────────► Kali Linux
│   ├── Secure anonymous operations ──────────────────► Tails OS
│   ├── Lightweight forensics fieldwork ─────────────► DEFT Zero
│   └── Securely wipe a drive ────────────────────────► SystemRescue (nwipe / shred)
│
└── Old / legacy hardware
    ├── Pre-2012 PC with Legacy BIOS only ───────────► HBCD 15.2 Legacy or Debian Live
    ├── DOS tools specifically needed ────────────────► HBCD 15.2 Legacy
    └── Very limited RAM (<512 MB) ──────────────────► Debian Live (XFCE) or GParted Live
```

---

## Tool-by-Tool Reference

### 🪟 Windows PE Environments

| Tool | Best For | Key Tools Inside |
|------|----------|-----------------|
| **Hiren's BootCD PE** | General Windows repair, password reset, virus removal | NTPWEdit, Malwarebytes, Recuva, BlueScreenView, ProduKey, CrystalDiskInfo, BootICE, 3DP Chip |
| **Sergei Strelec WinPE** | Advanced repair, driver installation, activation, reinstall | WinNTSetup, AOMEI, Acronis, driver packs, activation tools |
| **Microsoft DaRT PE** | Official Microsoft offline repair, Defender offline scan | Crash Analyzer, File Restore, Registry Editor, Windows Defender Offline |

---

### 🐧 Linux Rescue Environments

| Tool | Best For | Key Tools Inside |
|------|----------|-----------------|
| **SystemRescue** | Partition repair, data recovery, filesystem repair, network | GParted, TestDisk, PhotoRec, fsck, ntfsfix, ddrescue, SSH, nmap |
| **Rescuezilla** | Disk imaging/cloning for non-technical users | GUI disk imager, reads/writes Clonezilla + Foxclone formats |
| **Clonezilla** | Professional mass cloning, network multicast imaging | Partclone, ddrescue, network PXE boot, unicast/multicast |
| **GParted Live** | Partition editing | GParted (create/resize/move/delete/convert partitions) |
| **Ubuntu Live** | General rescue, hardware access, internet | Full desktop, Firefox, Terminal, file manager, Disks |
| **Fedora Live** | Modern hardware detection, Wayland | GNOME desktop, modern kernel, excellent Wi-Fi support |
| **Debian Live** | Older hardware, low RAM | Lightweight XFCE, very stable, large software library |
| **KNOPPIX** | Legacy hardware rescue, comprehensive toolkit | KDE desktop, huge software suite, excellent hardware detection |
| **Parted Magic** | Professional disk + data recovery (paid ~$15) | GParted, TestDisk, Clonezilla, dd, ddrescue, Truecrypt, Securely Erase |

---

### 🔬 Hardware Diagnostics

| Tool | Best For | Notes |
|------|----------|-------|
| **MemTest86+** | RAM testing (open source, legacy BIOS + UEFI) | Run at least 2 full passes. Any errors = bad RAM |
| **MemTest86 (PassMark)** | RAM testing (UEFI, graphical report) | Better UI, exportable HTML report, Secure Boot compatible |
| **HDAT2** | HDD/SSD bad sector scan and repair | Legacy BIOS only; can regenerate bad sectors |

---

### 🔐 Security & Forensics

| Tool | Best For | Key Feature |
|------|----------|-------------|
| **Tails OS** | Anonymous/private work | All traffic through Tor; leaves zero trace on host |
| **Kali Linux** | Penetration testing, security auditing | 600+ tools: Metasploit, Wireshark, Aircrack-ng, Burp Suite |
| **CAINE** | Digital forensics, evidence collection | All disks mounted **read-only** by default — preserves evidence integrity |
| **DEFT Zero** | Lightweight forensics | Less overhead than CAINE, good for field use |

---

### 🌐 Network Boot

| Tool | Best For | Notes |
|------|----------|-------|
| **netboot.xyz** | Booting any OS over the internet | Only 2 MB! Requires active internet connection |
| **iPXE** | Custom PXE/network boot setups | For IT professionals with PXE infrastructure |

---

## Common Tasks — Step by Step

### Reset a Forgotten Windows Password
1. Boot **Hiren's BootCD PE**
2. Launch **NTPWEdit** from the Password tools
3. Select the Windows system partition → select the locked user account
4. Click **Change password** or **Unlock** (remove the password)
5. Click **Save** → reboot into Windows

### Clone a Failing Hard Drive to Save Data
1. Boot **Rescuezilla** (easiest GUI) or **SystemRescue** (more control)
2. In Rescuezilla: **Backup** tab → select source → select destination → Start
3. In SystemRescue: `ddrescue -d -r3 /dev/sda /dev/sdb rescue.log` 
4. After cloning, swap drives — boot from the cloned drive to verify

### Recover Deleted Photos / Files
1. Boot **SystemRescue** (or Hiren's BootCD PE for NTFS drives)
2. In SystemRescue terminal: `photorec /dev/sda` (select the drive, not a partition)
3. Choose file types to search for → pick output location (on a *different* drive)
4. PhotoRec recovers by file signatures — works on formatted drives too

### Diagnose RAM Errors
1. Boot **MemTest86+** (Legacy BIOS) or **MemTest86** (UEFI)
2. Let it run automatically — it tests all memory across multiple algorithms
3. Run for **at least 2 full passes** (ideally leave overnight)
4. Any red error count > 0 = faulty RAM → remove one stick at a time to isolate

### Fix "BOOTMGR is missing" (Windows Vista/7/8/10/11)
1. Boot **Hiren's BootCD PE**
2. Open **Command Prompt**
3. Run these commands in order:
   ```
   bootrec /fixmbr
   bootrec /fixboot
   bootrec /scanos
   bootrec /rebuildbcd
   ```
4. Reboot

### Fix "NTLDR is missing" (Windows XP)
1. Boot **Hiren's BootCD PE**
2. Open **BootICE** → select the disk → **Manage MBR** → Restore standard MBR
3. Or copy `NTLDR` and `ntdetect.com` from a working XP source to the C: drive root

### Repair a Lost / Deleted Partition
1. Boot **SystemRescue**
2. Open terminal, run: `testdisk /dev/sda` (replace with your drive)
3. Select your partition table type (usually `Intel` / `EFI GPT`)
4. `Analyse` → `Quick Search` → it scans for lost partitions
5. If found, press `Write` to restore the partition table → reboot

### Securely Wipe a Drive Before Disposal
1. Boot **SystemRescue**
2. Run: `nwipe` (interactive GUI, DoD 5220.22-M wipe)
3. Or: `shred -vzn 3 /dev/sda` (3-pass overwrite, verbose)
4. For SSDs, prefer: `hdparm --security-erase` (manufacturer secure erase)

### Scan Windows for Malware Offline
1. Boot **Hiren's BootCD PE**
2. Launch **Malwarebytes** → scan the Windows partition (drive D: or whichever)
3. Also run **ESET Online Scanner** if internet is available
4. Remove anything found → reboot into Windows

---

## Profile Recommendation by Use Case

| Use Case | Recommended Profile |
|----------|---------------------|
| Home user, basic repairs | `core` |
| IT technician / support | `standard` |
| System administrator | `full` |
| Security researcher | `security` + `standard` |
| Hardware diagnostics lab | `diagnostics` |
| Windows-only shop | `windows-only` |
