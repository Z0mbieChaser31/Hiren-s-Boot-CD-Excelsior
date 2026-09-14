#!/usr/bin/env bash
# =============================================================================
# Hiren's Boot CD — Excelsior
# build.sh — Main ISO Build Script
#
# Usage:
#   sudo bash excelsior/scripts/build.sh [OPTIONS]
#
# Options:
#   --output FILE     Output ISO filename (default: Excelsior.iso)
#   --workdir DIR     Temporary working directory (default: /tmp/excelsior-build)
#   --skip-download   Skip re-downloading payloads if already cached
#   --no-gui          Skip graphical theme (for headless builds)
#   --help            Show this help
#
# Requirements (auto-installed on Debian/Ubuntu/Arch):
#   xorriso, mtools, grub-pc-bin, grub-efi-amd64-bin, syslinux, isolinux
#
# =============================================================================
set -euo pipefail

# ── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

# ── Defaults ─────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OUTPUT_ISO="${OUTPUT_ISO:-${REPO_ROOT}/Excelsior.iso}"
# Default WORKDIR to Windows C: drive to avoid WSL /tmp size limits (~3-4 GB needed)
WORKDIR="${WORKDIR:-/mnt/c/excelsior-build}"
SKIP_DOWNLOAD="${SKIP_DOWNLOAD:-false}"
WITH_GUI="${WITH_GUI:-true}"
LABEL="EXCELSIOR"

# ── Payload versions (update these to upgrade) ───────────────────────────────
SYSRESCUE_VERSION="13.01"
SYSRESCUE_URL="https://fastly-cdn.system-rescue.org/releases/${SYSRESCUE_VERSION}/systemrescue-${SYSRESCUE_VERSION}-amd64.iso"
SYSRESCUE_ISO="${WORKDIR}/downloads/systemrescue-${SYSRESCUE_VERSION}-amd64.iso"

# 32-bit Legacy Rescue (for Vortex86, Atom, Pentium, and 512MB RAM machines)
SYSRESCUE32_VERSION="5.3.2"
SYSRESCUE32_URL="https://archive.org/download/systemrescuecd-x86-5.3.2/systemrescuecd-x86-5.3.2.iso"
SYSRESCUE32_ISO="${WORKDIR}/downloads/systemrescuecd-x86-${SYSRESCUE32_VERSION}.iso"

# Memtest86+ is now installed via apt (package: memtest86+) instead of
# downloading a binary release — the upstream project no longer ships
# pre-built binaries in GitHub releases as of v8.x.

# ── Helpers ───────────────────────────────────────────────────────────────────
log()     { echo -e "${BOLD}${BLUE}[BUILD]${RESET} $*"; }
success() { echo -e "${BOLD}${GREEN}[ OK  ]${RESET} $*"; }
warn()    { echo -e "${BOLD}${YELLOW}[WARN ]${RESET} $*"; }
error()   { echo -e "${BOLD}${RED}[ERROR]${RESET} $*" >&2; exit 1; }

require_root() {
  if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root. Try: sudo bash $0"
  fi
}

detect_os() {
  if command -v apt-get &>/dev/null; then echo "debian"
  elif command -v pacman &>/dev/null; then echo "arch"
  elif command -v dnf &>/dev/null; then echo "fedora"
  else echo "unknown"; fi
}

install_deps() {
  local os; os="$(detect_os)"
  log "Detected OS family: ${os}"
  log "Installing build dependencies..."
  case "$os" in
    debian)
      apt-get update -qq
      apt-get install -y --no-install-recommends \
        xorriso mtools syslinux syslinux-common isolinux \
        grub-pc-bin grub-efi-amd64-bin grub-efi-amd64 \
        wget curl unzip cpio findutils rsync ;;
    arch)
      pacman -Sy --noconfirm --needed \
        xorriso mtools syslinux grub wget curl unzip cpio rsync ;;
    fedora)
      dnf install -y --quiet \
        xorriso mtools syslinux grub2-pc grub2-efi-x64 \
        wget curl unzip cpio rsync ;;
    *)
      warn "Unknown OS. Assuming dependencies are installed."
      warn "Required: xorriso mtools syslinux grub-pc grub-efi wget curl unzip" ;;
  esac
  success "Dependencies ready"
}

download() {
  local url="$1" dest="$2" desc="$3"
  if [[ "${SKIP_DOWNLOAD}" == "true" && -f "${dest}" ]]; then
    success "Using cached: ${desc}"
    return 0
  fi
  log "Downloading ${desc}..."
  mkdir -p "$(dirname "${dest}")"
  wget --quiet --show-progress --progress=bar:force \
       --continue -O "${dest}" "${url}" \
    || error "Failed to download: ${url}"
  success "Downloaded: ${desc}"
}

verify_sha256() {
  local file="$1" expected="$2" desc="$3"
  if [[ -z "${expected}" ]]; then
    warn "No checksum defined for ${desc}, skipping verification"
    return 0
  fi
  log "Verifying ${desc}..."
  local actual; actual="$(sha256sum "${file}" | awk '{print $1}')"
  if [[ "${actual}" != "${expected}" ]]; then
    error "Checksum mismatch for ${desc}!\\n  Expected: ${expected}\\n  Got:      ${actual}"
  fi
  success "Checksum OK: ${desc}"
}

# ── Build Steps ───────────────────────────────────────────────────────────────

prepare_dirs() {
  log "Preparing build directory: ${WORKDIR}"
  rm -rf "${WORKDIR}/iso_root"
  mkdir -p \
    "${WORKDIR}/iso_root/boot/grub/themes/excelsior" \
    "${WORKDIR}/iso_root/boot/grub/themes/excelsior/fonts" \
    "${WORKDIR}/iso_root/boot/grub/fonts" \
    "${WORKDIR}/iso_root/boot/isolinux" \
    "${WORKDIR}/iso_root/boot/memtest86" \
    "${WORKDIR}/iso_root/boot/hdt" \
    "${WORKDIR}/iso_root/EFI/BOOT" \
    "${WORKDIR}/iso_root/sysrescue" \
    "${WORKDIR}/iso_root/gparted" \
    "${WORKDIR}/downloads"
  success "Directories ready"
}

copy_boot_configs() {
  log "Copying GRUB2 and ISOLINUX configuration..."
  local excelsior_boot="${REPO_ROOT}/excelsior/boot"

  # GRUB2 config
  cp "${excelsior_boot}/grub/grub.cfg" \
     "${WORKDIR}/iso_root/boot/grub/grub.cfg"

  # GRUB2 theme
  cp -r "${excelsior_boot}/grub/themes/excelsior/." \
        "${WORKDIR}/iso_root/boot/grub/themes/excelsior/"

  # ISOLINUX config
  cp "${excelsior_boot}/isolinux/isolinux.cfg" \
     "${WORKDIR}/iso_root/boot/isolinux/isolinux.cfg"

  success "Boot configs installed"
}

install_isolinux_binaries() {
  log "Installing ISOLINUX binaries (legacy BIOS)..."

  # 1. isolinux.bin
  local isolinux_bin=""
  for f in /usr/lib/ISOLINUX/isolinux.bin /usr/lib/syslinux/bios/isolinux.bin /usr/lib/syslinux/isolinux.bin; do
    [[ -f "$f" ]] && isolinux_bin="$f" && break
  done
  [[ -n "${isolinux_bin}" ]] || error "Cannot find isolinux.bin"
  cp "${isolinux_bin}" "${WORKDIR}/iso_root/boot/isolinux/"

  # 2. Syslinux BIOS modules (.c32) including ldlinux.c32, vesamenu.c32, libcom32.c32, libutil.c32
  local modules_dir=""
  for d in /usr/lib/syslinux/modules/bios /usr/lib/syslinux/bios /usr/share/syslinux; do
    [[ -d "$d" ]] && modules_dir="$d" && break
  done
  if [[ -n "${modules_dir}" ]]; then
    cp -r "${modules_dir}"/*.c32 "${WORKDIR}/iso_root/boot/isolinux/" 2>/dev/null || true
  fi

  success "ISOLINUX binaries and modules installed"
}

install_grub_efi() {
  log "Installing GRUB2 EFI bootloader (UEFI support)..."

  # Generate to /tmp first (real Linux tmpfs) to avoid WSL /mnt/c/ write caching.
  local _tmpefi="/tmp/BOOTX64-$$.EFI"

  # Try grub-mkstandalone first — it auto-bundles all modules, no list needed
  if command -v grub-mkstandalone &>/dev/null; then
    grub-mkstandalone \
      --format=x86_64-efi \
      --output="${_tmpefi}" \
      --locales="" \
      --fonts="" \
      2>/dev/null || true
  fi

  # Fallback: grub-mkimage with minimal safe module list
  if [[ ! -s "${_tmpefi}" ]]; then
    grub-mkimage \
      --format=x86_64-efi \
      --output="${_tmpefi}" \
      --prefix=/boot/grub \
      part_gpt part_msdos fat iso9660 normal boot chain \
      configfile search search_label echo linux sleep \
      2>/dev/null || true
  fi

  if [[ -s "${_tmpefi}" ]]; then
    cp "${_tmpefi}" "${WORKDIR}/iso_root/EFI/BOOT/BOOTX64.EFI"
    rm -f "${_tmpefi}"
    success "GRUB2 EFI bootloader installed ($(du -sh "${WORKDIR}/iso_root/EFI/BOOT/BOOTX64.EFI" | cut -f1))"
  else
    rm -f "${_tmpefi}"
    error "grub-mkimage/mkstandalone EFI failed — cannot build bootable ISO without BOOTX64.EFI"
  fi

  # Copy GRUB EFI modules into the ISO for runtime module loading
  local grub_efi_dir=""
  for d in /usr/lib/grub/x86_64-efi /usr/share/grub/x86_64-efi; do
    [[ -d "$d" ]] && grub_efi_dir="$d" && break
  done
  if [[ -n "${grub_efi_dir}" ]]; then
    mkdir -p "${WORKDIR}/iso_root/boot/grub/x86_64-efi"
    cp "${grub_efi_dir}"/*.mod "${WORKDIR}/iso_root/boot/grub/x86_64-efi/" 2>/dev/null || true
  fi
}

install_grub_bios() {
  log "Installing GRUB2 BIOS bootloader..."
  local grub_bios_dir=""
  for d in /usr/lib/grub/i386-pc /usr/share/grub/i386-pc; do
    [[ -d "$d" ]] && grub_bios_dir="$d" && break
  done
  if [[ -n "${grub_bios_dir}" ]]; then
    mkdir -p "${WORKDIR}/iso_root/boot/grub/i386-pc"
    cp "${grub_bios_dir}"/*.img "${WORKDIR}/iso_root/boot/grub/i386-pc/" 2>/dev/null || true
    cp "${grub_bios_dir}"/*.mod "${WORKDIR}/iso_root/boot/grub/i386-pc/" 2>/dev/null || true
  fi

  # Generate GRUB2 BIOS El Torito boot image in /tmp first (real Linux tmpfs),
  # then copy to iso_root. Writing directly to /mnt/c/ via WSL can produce
  # silent empty files due to 9p/DrvFs filesystem quirks.
  log "Generating GRUB2 BIOS El Torito image..."
  local _tmpimg
  _tmpimg="/tmp/grub-eltorito-$$.img"
  grub-mkimage \
    --format=i386-pc-eltorito \
    --output="${_tmpimg}" \
    --prefix=/boot/grub \
    biosdisk iso9660 part_gpt part_msdos fat ext2 ntfs \
    normal configfile boot chain linux echo sleep search ls test \
    2>/dev/null || true

  if [[ -s "${_tmpimg}" ]]; then
    cp "${_tmpimg}" "${WORKDIR}/iso_root/boot/grub/i386-pc/eltorito.img"
    rm -f "${_tmpimg}"
    success "GRUB2 BIOS El Torito image generated ($(du -sh "${WORKDIR}/iso_root/boot/grub/i386-pc/eltorito.img" | cut -f1))"
  else
    rm -f "${_tmpimg}"
    warn "grub-mkimage BIOS failed — ISO will be UEFI-only (works on all modern hardware)"
  fi

  success "GRUB2 BIOS bootloader installed"
}

extract_sysrescue() {
  log "Downloading and extracting SystemRescue 64-bit ${SYSRESCUE_VERSION}..."
  download "${SYSRESCUE_URL}" "${SYSRESCUE_ISO}" "SystemRescue 64-bit ${SYSRESCUE_VERSION}"

  # Extract using xorriso directly — works reliably without root/loop mount issues
  log "Extracting SystemRescue 64-bit payload with xorriso..."
  rm -rf "${WORKDIR}/iso_root/sysresccd" "${WORKDIR}/iso_root/sysrescue.d"
  xorriso -osirrox on -indev "${SYSRESCUE_ISO}" \
    -extract /sysresccd "${WORKDIR}/iso_root/sysresccd" \
    -extract /sysrescue.d "${WORKDIR}/iso_root/sysrescue.d" \
    2>/dev/null || error "Failed to extract SystemRescue 64-bit payload"

  success "SystemRescue 64-bit extracted (${SYSRESCUE_VERSION})"
}

extract_sysrescue32() {
  log "Downloading and extracting SystemRescue 32-bit Legacy (${SYSRESCUE32_VERSION})..."
  download "${SYSRESCUE32_URL}" "${SYSRESCUE32_ISO}" "SystemRescue 32-bit Legacy ${SYSRESCUE32_VERSION}"

  mkdir -p "${WORKDIR}/iso_root/boot/sysrcd32"
  log "Extracting SystemRescue 32-bit payload with xorriso..."
  xorriso -osirrox on -indev "${SYSRESCUE32_ISO}" \
    -extract /isolinux/rescue32 "${WORKDIR}/iso_root/boot/sysrcd32/rescue32" \
    -extract /isolinux/initram.igz "${WORKDIR}/iso_root/boot/sysrcd32/initram.igz" \
    -extract /sysrcd.dat "${WORKDIR}/iso_root/sysrcd.dat" \
    -extract /sysrcd.md5 "${WORKDIR}/iso_root/sysrcd.md5" \
    2>/dev/null || error "Failed to extract SystemRescue 32-bit payload"

  success "SystemRescue 32-bit Legacy extracted (${SYSRESCUE32_VERSION} — supports 32-bit CPUs & 512MB RAM)"
}

install_memtest() {
  log "Installing Memtest86+..."
  mkdir -p "${WORKDIR}/iso_root/boot/memtest86"

  # SystemRescue includes Memtest86+ v7.20 (supports both UEFI and BIOS)
  local bundled="${WORKDIR}/iso_root/sysresccd/boot/memtest"
  if [[ -f "${bundled}" ]]; then
    cp "${bundled}" "${WORKDIR}/iso_root/boot/memtest86/memtest.bin"
    cp "${bundled}" "${WORKDIR}/iso_root/boot/memtest86/memtest.efi"
    success "Memtest86+ v7.20 installed (bundled with SystemRescue)"
    return 0
  fi

  warn "Bundled Memtest86+ not found — skipping"
}

# GParted is included in SystemRescue's graphical desktop (Xfce).
# No separate GParted Live download needed.

grub_install_fonts() {
  log "Installing GRUB2 fonts..."
  mkdir -p "${WORKDIR}/iso_root/boot/grub/fonts"
  mkdir -p "${WORKDIR}/iso_root/boot/grub/themes/excelsior/fonts"

  # 1. Install standard Unifont / unicode.pf2
  if [[ -f /usr/share/grub/unicode.pf2 ]]; then
    cp /usr/share/grub/unicode.pf2 "${WORKDIR}/iso_root/boot/grub/fonts/unicode.pf2"
    cp /usr/share/grub/unicode.pf2 "${WORKDIR}/iso_root/boot/grub/themes/excelsior/fonts/unicode.pf2"
  fi

  # 2. Generate exact DejaVu fonts requested by theme.txt
  if command -v grub-mkfont &>/dev/null; then
    local bold_ttf="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
    local regular_ttf="/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"

    if [[ -f "$bold_ttf" ]]; then
      grub-mkfont -s 14 -o "${WORKDIR}/iso_root/boot/grub/themes/excelsior/fonts/dejavu-14.pf2" "$bold_ttf" 2>/dev/null || true
      grub-mkfont -s 18 -o "${WORKDIR}/iso_root/boot/grub/themes/excelsior/fonts/dejavu-18.pf2" "$bold_ttf" 2>/dev/null || true
    fi
    if [[ -f "$regular_ttf" ]]; then
      grub-mkfont -s 11 -o "${WORKDIR}/iso_root/boot/grub/themes/excelsior/fonts/dejavu-11.pf2" "$regular_ttf" 2>/dev/null || true
      grub-mkfont -s 12 -o "${WORKDIR}/iso_root/boot/grub/themes/excelsior/fonts/dejavu-12.pf2" "$regular_ttf" 2>/dev/null || true
    fi
    success "GRUB fonts generated from DejaVu TTF"
  else
    warn "grub-mkfont not available — using unicode.pf2"
  fi
}

create_hybrid_iso() {
  log "Creating hybrid ISO (UEFI + BIOS El Torito + MBR) with xorriso..."

  # Locate ISOLINUX isohybrid MBR
  local isohdpfx=""
  for f in /usr/lib/ISOLINUX/isohdpfx.bin /usr/lib/syslinux/bios/isohdpfx.bin /usr/lib/syslinux/isohdpfx.bin; do
    [[ -f "$f" ]] && isohdpfx="$f" && break
  done

  local mbr_args=()
  if [[ -n "${isohdpfx}" ]]; then
    mbr_args=(-isohybrid-mbr "${isohdpfx}")
    log "  ISOLINUX isohybrid MBR: ${isohdpfx}"
  else
    warn "isohdpfx.bin not found — using default MBR"
  fi

  # Build FAT EFI system partition image for UEFI boot
  log "Creating FAT EFI system partition image..."
  local efiboot_img="${WORKDIR}/iso_root/boot/grub/efiboot.img"
  rm -f "${efiboot_img}"
  if command -v mkfs.vfat &>/dev/null && command -v mcopy &>/dev/null; then
    mkfs.vfat -C "${efiboot_img}" 8192 2>/dev/null
    mmd -i "${efiboot_img}" ::/EFI ::/EFI/BOOT 2>/dev/null || true
    mcopy -i "${efiboot_img}" "${WORKDIR}/iso_root/EFI/BOOT/BOOTX64.EFI" ::/EFI/BOOT/BOOTX64.EFI 2>/dev/null || true
    success "FAT EFI image created (8MB ESP)"
  fi

  local efi_args=()
  if [[ -s "${efiboot_img}" ]]; then
    efi_args=(
      -eltorito-alt-boot
      -e boot/grub/efiboot.img
      -no-emul-boot
      -isohybrid-gpt-basdat
    )
  fi

  # Build hybrid ISO:
  # 1. Primary El Torito boot entry: ISOLINUX (Legacy BIOS CD/DVD + Ventoy Normal Mode)
  # 2. Isohybrid MBR: isohdpfx.bin (Legacy BIOS USB dd-to-flash drive)
  # 3. Secondary El Torito boot entry: FAT EFI image (UEFI 64-bit boot)
  xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "${LABEL}" \
    -appid "Hiren's Boot CD Excelsior" \
    -publisher "HBCD Excelsior Project" \
    "${mbr_args[@]}" \
    -b boot/isolinux/isolinux.bin \
    -c boot/isolinux/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    "${efi_args[@]}" \
    -output "${OUTPUT_ISO}" \
    "${WORKDIR}/iso_root"

  success "ISO created: ${OUTPUT_ISO}"
  local size; size=$(du -sh "${OUTPUT_ISO}" | cut -f1)
  log "  Size:  ${size}"
  log "  Label: ${LABEL}"
  sha256sum "${OUTPUT_ISO}" | tee "${OUTPUT_ISO}.sha256"
  success "SHA256 checksum saved: ${OUTPUT_ISO}.sha256"
}

# ── Main ──────────────────────────────────────────────────────────────────────

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --output)    OUTPUT_ISO="$2"; shift 2 ;;
      --workdir)   WORKDIR="$2"; shift 2 ;;
      --skip-download) SKIP_DOWNLOAD=true; shift ;;
      --no-gui)    WITH_GUI=false; shift ;;
      --help|-h)
        echo "Usage: sudo bash build.sh [--output FILE] [--workdir DIR] [--skip-download] [--no-gui]"
        exit 0 ;;
      *) warn "Unknown argument: $1"; shift ;;
    esac
  done
}

main() {
  parse_args "$@"
  require_root

  echo ""
  echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════════${RESET}"
  echo -e "${BOLD}${CYAN}  Hiren's Boot CD — Excelsior ISO Builder${RESET}"
  echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════════${RESET}"
  echo ""

  install_deps
  prepare_dirs
  copy_boot_configs
  install_isolinux_binaries
  install_grub_efi
  install_grub_bios
  grub_install_fonts
  extract_sysrescue
  extract_sysrescue32
  install_memtest
  create_hybrid_iso

  echo ""
  echo -e "${BOLD}${GREEN}══════════════════════════════════════════════════════${RESET}"
  echo -e "${BOLD}${GREEN}  BUILD COMPLETE!${RESET}"
  echo -e "${BOLD}${GREEN}══════════════════════════════════════════════════════${RESET}"
  echo ""
  echo -e "  ISO:  ${BOLD}${OUTPUT_ISO}${RESET}"
  echo -e "  To flash to USB:  sudo bash excelsior/scripts/create-usb.sh ${OUTPUT_ISO} /dev/sdX"
  echo -e "  To test in QEMU:  bash excelsior/scripts/verify-iso.sh ${OUTPUT_ISO}"
  echo ""
}

main "$@"
