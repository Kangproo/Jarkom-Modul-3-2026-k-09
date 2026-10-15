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

# BusyBox udhcpc pada image ini menggunakan -x untuk mengirim hostname DHCP
# (Option 12); opsi ini dicocokkan oleh class pool1 di server tengen.
udhcpc -i eth0 -x hostname:itadori

echo ""
echo "=== Verifikasi itadori ==="
ip addr show eth0
ip route show
cat /etc/resolv.conf
