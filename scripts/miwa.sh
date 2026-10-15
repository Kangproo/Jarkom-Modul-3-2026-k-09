#!/bin/sh
# ============================================================
# miwa.sh - Klien Network 3 (Long Lease 43200s)
# Alokasi Target: 10.68.3.100 - 10.68.3.199
# Image: ardhptr21/alpinet:latest
# ============================================================

# Matikan instance udhcpc sebelumnya jika ada
killall udhcpc 2>/dev/null

# Hapus alamat IP lama di eth0
ip addr flush dev eth0

# Request DHCP:
# -i eth0 : interface
# -c miwa : Client ID (Option 61 - sesuai instruksi Soal 4)
# -H miwa : Hostname (Option 12)
# -s /usr/share/udhcpc/default.script : script default Alpine
udhcpc -i eth0 -H miwa -s /usr/share/udhcpc/default.script

echo ""
echo "=== Verifikasi miwa ==="
ip addr show eth0
ip route show
cat /etc/resolv.conf
