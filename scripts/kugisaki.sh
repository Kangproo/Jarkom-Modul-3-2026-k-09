#!/bin/sh
# ============================================================
# kugisaki.sh - Klien Network 3 (Fixed Address)
# Alokasi Target: 10.68.3.99
# Image: ardhptr21/alpinet:latest
# ============================================================

# Matikan instance udhcpc sebelumnya jika ada
killall udhcpc 2>/dev/null

# Hapus alamat IP lama di eth0
ip addr flush dev eth0

# Request DHCP:
# -i eth0 : interface
# -c kugisaki : Client ID (Option 61 - sesuai instruksi Soal 4)
# -H kugisaki : Hostname (Option 12)
# -s /usr/share/udhcpc/default.script : script default Alpine
udhcpc -i eth0 -H kugisaki -s /usr/share/udhcpc/default.script

echo ""
echo "=== Verifikasi kugisaki ==="
ip addr show eth0
ip route show
cat /etc/resolv.conf
