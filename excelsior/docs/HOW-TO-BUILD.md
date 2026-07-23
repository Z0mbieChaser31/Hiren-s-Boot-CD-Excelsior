# How to Build the Excelsior ISO

This guide covers building `Excelsior.iso` from source on Linux, WSL (Windows Subsystem for Linux), and via GitHub Actions CI.

---

## Prerequisites

| Requirement | Notes |
|---|---|
| Linux or WSL2 | Ubuntu 22.04+ or Arch Linux recommended |
| Root / sudo | Required for mounting and installing bootloaders |
| ~15 GB free disk | For downloads and build workspace |
| Internet access | To download SystemRescue, GParted, Memtest86+ |

---

## Option A: Build on Linux / WSL2 (Recommended)

### 1. Clone the Repository

```bash
git clone https://github.com/HBCD/Hiren-s-Boot-CD-reborn.git
cd Hiren-s-Boot-CD-reborn
git checkout Hiren-s-Boot-CD-Excelsior
```

### 2. Run the Build Script

```bash
sudo bash excelsior/scripts/build.sh
```

The script will:
- Auto-detect your distro and install dependencies
- Download SystemRescue, GParted Live, and Memtest86+
- Install GRUB2 (UEFI) and ISOLINUX (Legacy BIOS) bootloaders
- Create a hybrid ISO: `Excelsior.iso`

### 3. Options

```bash
# Custom output filename
sudo bash excelsior/scripts/build.sh --output MyRescue.iso

# Skip re-downloading (use cached payloads)
sudo bash excelsior/scripts/build.sh --skip-download

# Different working directory
sudo bash excelsior/scripts/build.sh --workdir /mnt/bigdisk/excelsior-build
```

### 4. Flash to USB

```bash
# Replace /dev/sdX with your USB drive (use lsblk to identify it)
sudo bash excelsior/scripts/create-usb.sh Excelsior.iso /dev/sdX
```

> **Windows users**: Use [Rufus](https://rufus.ie/) (select DD mode) or [Ventoy](https://www.ventoy.net/) to flash the ISO.

---

## Option B: GitHub Actions (Automatic)

Every push to the `Hiren-s-Boot-CD-Excelsior` branch triggers a build.

1. Go to the **Actions** tab in GitHub
2. Click **Build Excelsior ISO** workflow
3. When complete, download the ISO from **Artifacts**

For release builds, tag a commit:
```bash
git tag v1.0.0
git push origin v1.0.0
```
The ISO is automatically uploaded to the GitHub Release.

---

## Option C: Manual Build (Advanced)

If you want full control without the build script:

### Install Dependencies (Ubuntu)

```bash
sudo apt-get install -y \
  xorriso mtools syslinux syslinux-common isolinux \
  grub-pc-bin grub-efi-amd64-bin grub-efi-amd64 \
  wget curl unzip cpio rsync
```

### Download Payloads

```bash
mkdir -p /tmp/excelsior-build/downloads

# SystemRescue
wget -c https://fastly-cdn.system-rescue.org/releases/11.02/systemrescue-11.02-amd64.iso \
     -O /tmp/excelsior-build/downloads/systemrescue.iso

# GParted Live
wget -c https://downloads.sourceforge.net/gparted/gparted-live-1.6.0-3-amd64.iso \
     -O /tmp/excelsior-build/downloads/gparted.iso

# Memtest86+
wget -c https://www.memtest.org/download/7.00/mt86plus_7.00.binaries.zip \
     -O /tmp/excelsior-build/downloads/memtest86plus.zip
```

### Assemble ISO Root

```bash
mkdir -p /tmp/excelsior-build/iso_root/{boot/grub/themes/excelsior,boot/isolinux,EFI/BOOT,sysrescue,gparted,boot/memtest86}

# Copy boot configs
cp excelsior/boot/grub/grub.cfg /tmp/excelsior-build/iso_root/boot/grub/
cp -r excelsior/boot/grub/themes/excelsior/ /tmp/excelsior-build/iso_root/boot/grub/themes/
cp excelsior/boot/isolinux/isolinux.cfg /tmp/excelsior-build/iso_root/boot/isolinux/

# Install ISOLINUX binaries
cp /usr/lib/ISOLINUX/isolinux.bin /tmp/excelsior-build/iso_root/boot/isolinux/

# Build GRUB EFI
grub-mkimage --format=x86_64-efi \
  --output=/tmp/excelsior-build/iso_root/EFI/BOOT/BOOTX64.EFI \
  --prefix=/boot/grub \
  part_gpt part_msdos fat iso9660 all_video gfxterm gfxmenu \
  normal boot chain linux linuxefi configfile search echo

# Mount and extract payloads
sudo mount -o loop,ro /tmp/excelsior-build/downloads/systemrescue.iso /mnt
sudo rsync -a /mnt/ /tmp/excelsior-build/iso_root/sysrescue/
sudo umount /mnt
```

### Create Final ISO with xorriso

```bash
xorriso -as mkisofs \
  -iso-level 3 \
  -full-iso9660-filenames \
  -volid "EXCELSIOR" \
  -appid "Hiren's Boot CD Excelsior" \
  -eltorito-boot boot/isolinux/isolinux.bin \
  -eltorito-catalog boot/isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  --efi-boot EFI/BOOT/BOOTX64.EFI \
  -efi-boot-part --efi-boot-image \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -output Excelsior.iso \
  /tmp/excelsior-build/iso_root
```

---

## Testing the ISO

### QEMU (UEFI mode)

```bash
# Install QEMU and OVMF
sudo apt install qemu-system-x86 ovmf

# Test
qemu-system-x86_64 \
  -enable-kvm -m 2048 \
  -bios /usr/share/OVMF/OVMF_CODE.fd \
  -cdrom Excelsior.iso -boot d \
  -vga std -usb -device usb-tablet
```

### QEMU (Legacy BIOS mode)

```bash
qemu-system-x86_64 \
  -enable-kvm -m 2048 \
  -cdrom Excelsior.iso -boot d \
  -vga std
```

### Using the verify script

```bash
# Check ISO structure only
bash excelsior/scripts/verify-iso.sh Excelsior.iso --check-only

# Launch QEMU UEFI test
bash excelsior/scripts/verify-iso.sh Excelsior.iso --uefi

# Launch QEMU BIOS test
bash excelsior/scripts/verify-iso.sh Excelsior.iso --bios
```

---

## Troubleshooting

| Problem | Solution |
|---|---|
| `isolinux.bin not found` | Install `isolinux` package: `apt install isolinux` |
| `OVMF not found` | Install `ovmf` package: `apt install ovmf` |
| `grub-mkimage fails` | Install `grub-efi-amd64-bin`: `apt install grub-efi-amd64-bin` |
| ISO won't boot on UEFI | Check Secure Boot — disable it in BIOS, or sign the EFI binary |
| Download fails | Check internet connectivity; mirrors may be temporarily down |
| Out of disk space | Set `--workdir` to a partition with 15+ GB free |
