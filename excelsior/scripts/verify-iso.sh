#!/usr/bin/env bash
# =============================================================================
# Hiren's Boot CD — Excelsior
# verify-iso.sh — ISO Integrity Verification and QEMU Test Boot
#
# Usage:
#   bash excelsior/scripts/verify-iso.sh <iso-file> [--uefi] [--bios] [--check-only]
#
# Options:
#   --uefi        Test UEFI boot in QEMU (requires OVMF)
#   --bios        Test Legacy BIOS boot in QEMU
#   --check-only  Only verify structure, don't launch QEMU
# =============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; RESET='\033[0m'

error()   { echo -e "${BOLD}${RED}[ERROR]${RESET} $*" >&2; exit 1; }
warn()    { echo -e "${BOLD}${YELLOW}[WARN ]${RESET} $*"; }
success() { echo -e "${BOLD}${GREEN}[ OK  ]${RESET} $*"; }
log()     { echo -e "${BOLD}[INFO ]${RESET} $*"; }

[[ $# -ge 1 ]] || { echo "Usage: bash $0 <iso-file> [--uefi|--bios|--check-only]"; exit 1; }

ISO="$1"; shift
MODE="${1:---uefi}"

[[ -f "${ISO}" ]] || error "ISO not found: ${ISO}"

echo ""
echo -e "${BOLD}Hiren's Boot CD Excelsior — ISO Verification${RESET}"
echo "════════════════════════════════════════════"
echo ""

# ── 1. File checks ────────────────────────────────────────────────────────────
ISO_SIZE=$(du -sh "${ISO}" | cut -f1)
log "ISO: ${ISO} (${ISO_SIZE})"

# Verify SHA256 if checksum file exists
SHA_FILE="${ISO}.sha256"
if [[ -f "${SHA_FILE}" ]]; then
  log "Verifying SHA256..."
  if sha256sum --check --status "${SHA_FILE}"; then
    success "SHA256 checksum matches"
  else
    error "SHA256 MISMATCH — ISO may be corrupt!"
  fi
else
  warn "No .sha256 file found; skipping checksum verification"
fi

# ── 2. ISO structure checks ───────────────────────────────────────────────────
if command -v isoinfo &>/dev/null; then
  log "Checking ISO structure with isoinfo..."
  VOL_ID=$(isoinfo -d -i "${ISO}" 2>/dev/null | grep "Volume id:" | awk '{print $3}' || echo "unknown")
  log "  Volume label: ${VOL_ID}"
  [[ "${VOL_ID}" == "EXCELSIOR" ]] && success "Volume label correct (EXCELSIOR)" || \
    warn "Volume label is '${VOL_ID}', expected 'EXCELSIOR'"

  # Check for key files
  for EXPECTED in "/boot/grub/grub.cfg" "/boot/isolinux/isolinux.bin" \
                  "/EFI/BOOT/BOOTX64.EFI" "/sysrescue" "/gparted"; do
    if isoinfo -i "${ISO}" -f 2>/dev/null | grep -qi "${EXPECTED}"; then
      success "  Found: ${EXPECTED}"
    else
      warn "  Missing: ${EXPECTED}"
    fi
  done
else
  warn "isoinfo not installed (apt install genisoimage); skipping structure check"
fi

# ── 3. QEMU test boot ─────────────────────────────────────────────────────────
if [[ "${MODE}" == "--check-only" ]]; then
  echo ""
  success "Verification complete (no QEMU test)"
  exit 0
fi

command -v qemu-system-x86_64 &>/dev/null || \
  error "qemu-system-x86_64 not found. Install with: apt install qemu-system-x86 or skip with --check-only"

echo ""
log "Launching QEMU test boot (close QEMU window to exit)..."
echo "  Press Ctrl+Alt+G to release mouse, Ctrl+Alt to release keyboard"
echo ""

RAM=2048  # 2 GB minimum for rescue environments

if [[ "${MODE}" == "--uefi" ]]; then
  # Try common OVMF paths
  OVMF=""
  for f in /usr/share/OVMF/OVMF_CODE.fd \
            /usr/share/ovmf/x64/OVMF_CODE.fd \
            /usr/share/qemu/OVMF.fd; do
    [[ -f "$f" ]] && OVMF="$f" && break
  done
  [[ -n "${OVMF}" ]] || error "OVMF firmware not found. Install: apt install ovmf"

  log "Booting in UEFI mode (OVMF: ${OVMF})"
  qemu-system-x86_64 \
    -enable-kvm \
    -m "${RAM}" \
    -cpu host \
    -bios "${OVMF}" \
    -cdrom "${ISO}" \
    -boot d \
    -vga std \
    -usb \
    -device usb-tablet \
    -name "Excelsior UEFI Test"
else
  log "Booting in Legacy BIOS mode"
  qemu-system-x86_64 \
    -enable-kvm \
    -m "${RAM}" \
    -cpu host \
    -cdrom "${ISO}" \
    -boot d \
    -vga std \
    -usb \
    -device usb-tablet \
    -name "Excelsior BIOS Test"
fi
