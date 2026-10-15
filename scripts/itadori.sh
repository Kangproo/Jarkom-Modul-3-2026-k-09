#!/bin/sh
# ============================================================
# itadori.sh - Klien Network 2 (Pool 1)
# Alokasi Target: 10.68.2.10 - 10.68.2.35
# Image: ardhptr21/alpinet:latest
# ============================================================

# Matikan instance udhcpc sebelumnya jika ada
killall udhcpc 2>/dev/null

# Hapus alamat IP lama di eth0 agar request baru terlihat saat demo
ip addr flush dev eth0

# -c itadori mengirim Client ID (Option 61).
# -H itadori mengirim hostname (Option 12) yang dipakai class pool1.
udhcpc -i eth0 -c itadori -H itadori

echo ""
echo "=== Verifikasi itadori ==="
ip addr show eth0
ip route show
cat /etc/resolv.conf
