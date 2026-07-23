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
WORKDIR="${WORKDIR:-/tmp/excelsior-build}"
SKIP_DOWNLOAD="${SKIP_DOWNLOAD:-false}"
WITH_GUI="${WITH_GUI:-true}"
LABEL="EXCELSIOR"

# ── Payload versions (update these to upgrade) ───────────────────────────────
SYSRESCUE_VERSION="11.02"
SYSRESCUE_URL="https://fastly-cdn.system-rescue.org/releases/${SYSRESCUE_VERSION}/systemrescue-${SYSRESCUE_VERSION}-amd64.iso"
SYSRESCUE_ISO="${WORKDIR}/downloads/systemrescue-${SYSRESCUE_VERSION}-amd64.iso"

GPARTED_VERSION="1.6.0-3"
GPARTED_URL="https://downloads.sourceforge.net/gparted/gparted-live-${GPARTED_VERSION}-amd64.iso"
GPARTED_ISO="${WORKDIR}/downloads/gparted-live-${GPARTED_VERSION}-amd64.iso"

MEMTEST_VERSION="7.00"
MEMTEST_URL="https://www.memtest.org/download/${MEMTEST_VERSION}/mt86plus_${MEMTEST_VERSION}.binaries.zip"
MEMTEST_ZIP="${WORKDIR}/downloads/memtest86plus-${MEMTEST_VERSION}.zip"

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
  local syslinux_data
  # Try common locations
  for dir in /usr/lib/syslinux/bios /usr/lib/syslinux /usr/share/syslinux; do
    if [[ -f "${dir}/isolinux.bin" ]]; then
      syslinux_data="${dir}"; break
    fi
  done
  if [[ -z "${syslinux_data:-}" ]]; then
    # Also check for isolinux package path
    for dir in /usr/lib/ISOLINUX /usr/lib/isolinux; do
      if [[ -f "${dir}/isolinux.bin" ]]; then
        syslinux_data="${dir}"; break
      fi
    done
  fi
  [[ -n "${syslinux_data:-}" ]] || error "Cannot find isolinux.bin. Install 'isolinux' or 'syslinux' package."

  cp "${syslinux_data}/isolinux.bin" "${WORKDIR}/iso_root/boot/isolinux/"
  cp "${syslinux_data}/ldlinux.c32"  "${WORKDIR}/iso_root/boot/isolinux/" 2>/dev/null || true

  # vesamenu and other modules
  for mod in vesamenu.c32 libcom32.c32 libutil.c32 hdt.c32; do
    find /usr/lib/syslinux /usr/share/syslinux -name "${mod}" 2>/dev/null | \
      head -1 | xargs -I{} cp {} "${WORKDIR}/iso_root/boot/isolinux/" 2>/dev/null || true
  done

  success "ISOLINUX binaries installed"
}

install_grub_efi() {
  log "Installing GRUB2 EFI bootloader (UEFI support)..."
  grub-mkimage \
    --format=x86_64-efi \
    --output="${WORKDIR}/iso_root/EFI/BOOT/BOOTX64.EFI" \
    --prefix=/boot/grub \
    part_gpt part_msdos fat iso9660 udf ext2 ntfs \
    all_video gfxterm gfxmenu png \
    normal boot chain linux linuxefi loopback \
    configfile search search_fs_uuid search_fs_file search_label \
    echo read ls test true sleep \
    2>/dev/null || true

  # Copy GRUB EFI modules
  local grub_efi_dir
  for d in /usr/lib/grub/x86_64-efi /usr/share/grub/x86_64-efi; do
    [[ -d "$d" ]] && grub_efi_dir="$d" && break
  done
  if [[ -n "${grub_efi_dir:-}" ]]; then
    mkdir -p "${WORKDIR}/iso_root/boot/grub/x86_64-efi"
    cp "${grub_efi_dir}"/*.mod "${WORKDIR}/iso_root/boot/grub/x86_64-efi/" 2>/dev/null || true
  fi

  success "GRUB2 EFI bootloader installed"
}

install_grub_bios() {
  log "Installing GRUB2 BIOS bootloader..."
  local grub_bios_dir
  for d in /usr/lib/grub/i386-pc /usr/share/grub/i386-pc; do
    [[ -d "$d" ]] && grub_bios_dir="$d" && break
  done
  if [[ -n "${grub_bios_dir:-}" ]]; then
    mkdir -p "${WORKDIR}/iso_root/boot/grub/i386-pc"
    cp "${grub_bios_dir}"/*.img "${WORKDIR}/iso_root/boot/grub/i386-pc/" 2>/dev/null || true
    cp "${grub_bios_dir}"/*.mod "${WORKDIR}/iso_root/boot/grub/i386-pc/" 2>/dev/null || true
  fi
  success "GRUB2 BIOS modules installed"
}

install_memtest() {
  log "Installing Memtest86+..."
  download "${MEMTEST_URL}" "${MEMTEST_ZIP}" "Memtest86+ ${MEMTEST_VERSION}"
  local memtest_dir="${WORKDIR}/memtest_extracted"
  rm -rf "${memtest_dir}"
  mkdir -p "${memtest_dir}"
  unzip -q "${MEMTEST_ZIP}" -d "${memtest_dir}"
  # Copy EFI and binary versions
  find "${memtest_dir}" -name "*.efi" | head -1 | \
    xargs -I{} cp {} "${WORKDIR}/iso_root/boot/memtest86/memtest.efi" 2>/dev/null || true
  find "${memtest_dir}" -name "memtest.bin" | head -1 | \
    xargs -I{} cp {} "${WORKDIR}/iso_root/boot/memtest86/memtest.bin" 2>/dev/null || true
  find "${memtest_dir}" -name "memtest64.bin" | head -1 | \
    xargs -I{} cp {} "${WORKDIR}/iso_root/boot/memtest86/memtest64.bin" 2>/dev/null || true
  success "Memtest86+ installed"
}

extract_sysrescue() {
  log "Downloading and extracting SystemRescue ${SYSRESCUE_VERSION}..."
  download "${SYSRESCUE_URL}" "${SYSRESCUE_ISO}" "SystemRescue ${SYSRESCUE_VERSION}"

  local mnt="${WORKDIR}/mnt_sysrescue"
  mkdir -p "${mnt}"

  # Mount and extract the SystemRescue ISO
  mount -o loop,ro "${SYSRESCUE_ISO}" "${mnt}" 2>/dev/null || \
    error "Failed to mount ${SYSRESCUE_ISO}. Try running with sudo."

  # Copy entire SystemRescue payload into iso_root/sysrescue/
  rsync -a --exclude='EFI' --exclude='boot/grub' \
        "${mnt}/" "${WORKDIR}/iso_root/sysrescue/"

  umount "${mnt}"
  success "SystemRescue extracted"
}

extract_gparted() {
  log "Downloading and extracting GParted Live ${GPARTED_VERSION}..."
  download "${GPARTED_URL}" "${GPARTED_ISO}" "GParted Live ${GPARTED_VERSION}"

  local mnt="${WORKDIR}/mnt_gparted"
  mkdir -p "${mnt}"
  mount -o loop,ro "${GPARTED_ISO}" "${mnt}" 2>/dev/null || \
    error "Failed to mount ${GPARTED_ISO}"

  rsync -a --exclude='EFI' --exclude='boot/grub' --exclude='isolinux' \
        "${mnt}/" "${WORKDIR}/iso_root/gparted/"

  umount "${mnt}"
  success "GParted Live extracted"
}

grub_install_fonts() {
  log "Installing GRUB2 fonts..."
  if command -v grub-mkfont &>/dev/null; then
    mkdir -p "${WORKDIR}/iso_root/boot/grub/fonts"
    # Try to find unicode.pf2
    for f in /usr/share/grub/unicode.pf2 /boot/grub/fonts/unicode.pf2 \
              /boot/grub2/fonts/unicode.pf2; do
      if [[ -f "$f" ]]; then
        cp "$f" "${WORKDIR}/iso_root/boot/grub/fonts/"
        cp "$f" "${WORKDIR}/iso_root/boot/grub/themes/excelsior/fonts/"
        success "GRUB font installed"
        return 0
      fi
    done
    # Generate it
    if [[ -f /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf ]]; then
      grub-mkfont -o "${WORKDIR}/iso_root/boot/grub/themes/excelsior/fonts/unicode.pf2" \
        /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
    fi
  fi
}

create_hybrid_iso() {
  log "Creating hybrid ISO (UEFI + BIOS) with xorriso..."

  # The --grub2-mbr file is needed for BIOS/MBR hybrid support
  local mbr_img="${WORKDIR}/iso_root/boot/grub/i386-pc/boot_hybrid.img"
  [[ -f "${mbr_img}" ]] || mbr_img="/usr/lib/grub/i386-pc/boot_hybrid.img"
  [[ -f "${mbr_img}" ]] || mbr_img=""

  local mbr_opt=()
  [[ -n "${mbr_img}" ]] && mbr_opt=(--grub2-mbr "${mbr_img}")

  xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "${LABEL}" \
    -appid "Hiren's Boot CD Excelsior" \
    -publisher "HBCD Excelsior Project" \
    \
    "${mbr_opt[@]}" \
    \
    -eltorito-boot boot/isolinux/isolinux.bin \
    -eltorito-catalog boot/isolinux/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    \
    --efi-boot EFI/BOOT/BOOTX64.EFI \
    -efi-boot-part \
    --efi-boot-image \
    \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    \
    -output "${OUTPUT_ISO}" \
    "${WORKDIR}/iso_root"

  success "ISO created: ${OUTPUT_ISO}"
  local size; size=$(du -sh "${OUTPUT_ISO}" | cut -f1)
  log "  Size: ${size}"
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
  install_memtest
  extract_sysrescue
  extract_gparted
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
