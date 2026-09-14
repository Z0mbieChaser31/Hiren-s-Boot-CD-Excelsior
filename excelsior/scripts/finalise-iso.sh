#!/usr/bin/env bash
# finalise-iso.sh
# Run as the WSL user (not root) so DrvFs write permissions are satisfied.
set -euo pipefail

DEST="/mnt/c/Users/gerla/OneDrive/Desktop/Hiren-s-Boot-CD-reborn/Excelsior.iso"
WORKDIR="/mnt/c/excelsior-build"

echo "[BUILD] Writing ISO directly to DrvFs as WSL user (owns the target file)..."
xorriso -as mkisofs \
  -iso-level 3 \
  -full-iso9660-filenames \
  -volid "EXCELSIOR" \
  -appid "Hirens Boot CD Excelsior" \
  -publisher "HBCD Excelsior Project" \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -b boot/isolinux/isolinux.bin \
  -c boot/isolinux/boot.cat \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -eltorito-alt-boot \
  -e boot/grub/efiboot.img \
  -no-emul-boot \
  -isohybrid-gpt-basdat \
  -output "${DEST}" \
  "${WORKDIR}/iso_root"

echo "[ OK ] ISO written: ${DEST}"
ls -lh "${DEST}"
sha256sum "${DEST}" | tee "${DEST}.sha256"
echo "[ OK ] Done."
