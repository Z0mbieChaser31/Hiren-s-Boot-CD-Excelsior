#!/usr/bin/env bash
# write-iso-to-wsl-home.sh
# Writes the ISO to /root/ on the WSL native ext4 disk (persistent, not tmpfs).
# From Windows, copy it with:
#   Copy-Item "\\wsl$\Ubuntu\root\Excelsior.iso" "C:\...\Excelsior.iso" -Force
set -euo pipefail

DEST="/root/Excelsior.iso"
WORKDIR="/mnt/c/excelsior-build"

echo "[BUILD] Writing ISO to WSL native filesystem: ${DEST}"
echo "[BUILD] (Will copy to Windows via PowerShell UNC path after)"

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

echo "[ OK ] ISO written to WSL home: ${DEST}"
ls -lh "${DEST}"
sha256sum "${DEST}"
echo "[ OK ] Done. Copy to Windows with:"
echo "       Copy-Item \"\\\\wsl\$\\Ubuntu\\root\\Excelsior.iso\" \"C:\\Users\\gerla\\OneDrive\\Desktop\\Hiren-s-Boot-CD-reborn\\Excelsior.iso\" -Force"
