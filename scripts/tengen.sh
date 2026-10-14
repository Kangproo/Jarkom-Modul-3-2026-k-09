#!/bin/bash
# ============================================================
# tengen.sh - DHCP Server
# Covers: Soal 2, 4, 5, 6, 7, 10
# Image: ardhptr21/debinet:latest
# ============================================================

echo 'nameserver 192.168.122.1' > /etc/resolv.conf

# === SOAL 1: IP Statis Runtime ===
ip addr flush dev eth0 2>/dev/null
ip addr add 10.68.4.10/24 dev eth0
ip link set eth0 up
ip route add default via 10.68.4.1 2>/dev/null

# === SOAL 10: Persistensi IP Statis (Tahan Reboot) ===
cat > /etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.68.4.10
    netmask 255.255.255.0
    gateway 10.68.4.1
EOF

# === SOAL 2: Install isc-dhcp-server ===
apt-get update
apt-get install -y isc-dhcp-server

cat > /etc/default/isc-dhcp-server << 'EOF'
INTERFACESv4="eth0"
INTERFACESv6=""
EOF

# === SOAL 2, 4, 5, 6: dhcpd.conf ===
cat > /etc/dhcp/dhcpd.conf << 'EOF'
# ============================================================
# dhcpd.conf - Konfigurasi DHCP Server tengen (K09)
# ============================================================

option domain-name "K09.com";
option domain-name-servers 10.68.1.2, 10.68.1.3;
default-lease-time 600;
max-lease-time 7200;
ddns-update-style none;
authoritative;

# === SOAL 4: DHCP Class Network 2 (Divisi A) ===
# Mendukung pencocokan via Client ID (Option 61) dan Hostname
class "pool1" {
    match if (option dhcp-client-identifier = "itadori") or
             (substring(option dhcp-client-identifier, 1, 20) = "itadori") or
             (option host-name = "itadori") or
             (option dhcp-client-identifier = "fushiguro") or
             (substring(option dhcp-client-identifier, 1, 20) = "fushiguro") or
             (option host-name = "fushiguro");
}

class "pool2" {
    match if (option dhcp-client-identifier = "zenin") or
             (substring(option dhcp-client-identifier, 1, 20) = "zenin") or
             (option host-name = "zenin") or
             (option dhcp-client-identifier = "okkotsu") or
             (substring(option dhcp-client-identifier, 1, 20) = "okkotsu") or
             (option host-name = "okkotsu");
}

# === SOAL 5: DHCP Class Network 3 (Divisi B) ===
class "short-lease" {
    match if (option dhcp-client-identifier = "ino") or
             (substring(option dhcp-client-identifier, 1, 20) = "ino") or
             (option host-name = "ino") or
             (option dhcp-client-identifier = "kusakabe") or
             (substring(option dhcp-client-identifier, 1, 20) = "kusakabe") or
             (option host-name = "kusakabe");
}

class "long-lease" {
    match if (option dhcp-client-identifier = "miwa") or
             (substring(option dhcp-client-identifier, 1, 20) = "miwa") or
             (option host-name = "miwa");
}

# === SOAL 2: Subnet Network 4 (Lokal Data Center - tanpa pool dinamis) ===
subnet 10.68.4.0 netmask 255.255.255.0 {
    option routers 10.68.4.1;
    option broadcast-address 10.68.4.255;
}

# === SOAL 2 & 4: Subnet Network 2 (Divisi A) ===
subnet 10.68.2.0 netmask 255.255.255.0 {
    option routers 10.68.2.1;
    option broadcast-address 10.68.2.255;
    option domain-name-servers 10.68.1.2, 10.68.1.3;
    option domain-search "K09.com";

    # Pool 1: 10.68.2.10 - 10.68.2.35 (itadori & fushiguro)
    pool {
        allow members of "pool1";
        range 10.68.2.10 10.68.2.35;
    }

    # Pool 2: 10.68.2.70 - 10.68.2.95 (zenin & okkotsu)
    pool {
        allow members of "pool2";
        range 10.68.2.70 10.68.2.95;
    }
    # Rentang 10.68.2.36 - 10.68.2.69 TIDAK dialokasikan
}

# === SOAL 2, 5, 6: Subnet Network 3 (Divisi B) ===
subnet 10.68.3.0 netmask 255.255.255.0 {
    option routers 10.68.3.1;
    option broadcast-address 10.68.3.255;
    option domain-name-servers 10.68.1.2, 10.68.1.3;
    option domain-search "K09.com";

    # Short lease pool: 10.68.3.10 - 10.68.3.89 (ino & kusakabe)
    pool {
        allow members of "short-lease";
        range 10.68.3.10 10.68.3.89;
        default-lease-time 1800;
        max-lease-time 1800;
    }

    # Long lease pool: 10.68.3.100 - 10.68.3.199 (miwa)
    pool {
        allow members of "long-lease";
        range 10.68.3.100 10.68.3.199;
        default-lease-time 43200;
        max-lease-time 43200;
    }
}

# === SOAL 6: Fixed Address kugisaki (10.68.3.99) ===
# Ganti MAC_ADDRESS_KUGISAKI dengan MAC asli container kugisaki!
# Cek di kugisaki: ip link show eth0 | grep ether
host kugisaki {
    # Ganti dengan MAC asli kugisaki saat mengerjakan Soal 6 (ip link show eth0)
    hardware ethernet 02:42:0a:44:03:99;
    fixed-address 10.68.3.99;
    option routers 10.68.3.1;
    option broadcast-address 10.68.3.255;
    option domain-name-servers 10.68.1.2, 10.68.1.3;
    option domain-search "K09.com";
}
EOF

# Restart Service
service isc-dhcp-server restart

# === SOAL 10: Autostart DHCP Server ===
systemctl enable isc-dhcp-server 2>/dev/null || update-rc.d isc-dhcp-server defaults 2>/dev/null

echo "=== tengen.sh selesai ==="
