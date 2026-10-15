#!/bin/bash
# utahime - DNS Master, soal 11 dan 12. Jalankan hanya pada node utahime.
# Script ini TIDAK mengubah IP, gateway atau /etc/network/interfaces.
set -euo pipefail
[ "$(hostname)" = "utahime" ] || { echo "ERROR: khusus node utahime"; exit 1; }

if ! command -v named-checkconf >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9-utils dnsutils
fi

backup="$(mktemp -d /root/k09-utahime-dns-XXXXXX)"
for f in /etc/bind/named.conf.local /etc/bind/named.conf.options /etc/bind/k09-zones.conf; do
    [ ! -f "$f" ] || cp -a "$f" "$backup/"
done

# Simpan zone file lama beserta serialnya, jangan reset jika sudah ada.
if [ ! -f /etc/bind/db.jujutsu.k09.com ]; then
cat > /etc/bind/db.jujutsu.k09.com <<'ZONE'
$TTL 86400
@ IN SOA utahime.jujutsu.k09.com. admin.jujutsu.k09.com. (
    2026101503 3600 1800 604800 86400 )
@       IN NS    utahime.jujutsu.k09.com.
@       IN NS    shoko.jujutsu.k09.com.
@       IN A     10.68.1.4
utahime IN A     10.68.1.2
shoko   IN A     10.68.1.3
gojo    IN A     10.68.1.4
www     IN CNAME jujutsu.k09.com.
ZONE
fi

if [ ! -f /etc/bind/db.1.68.10.in-addr.arpa ]; then
cat > /etc/bind/db.1.68.10.in-addr.arpa <<'ZONE'
$TTL 86400
@ IN SOA utahime.jujutsu.k09.com. admin.jujutsu.k09.com. (
    2026101501 3600 1800 604800 86400 )
@ IN NS utahime.jujutsu.k09.com.
@ IN NS shoko.jujutsu.k09.com.
2 IN PTR utahime.jujutsu.k09.com.
3 IN PTR shoko.jujutsu.k09.com.
4 IN PTR gojo.jujutsu.k09.com.
ZONE
fi

cat > /etc/bind/k09-zones.conf <<'CONF'
zone "jujutsu.k09.com" {
    type master;
    file "/etc/bind/db.jujutsu.k09.com";
    allow-transfer { 10.68.1.3; };
    also-notify { 10.68.1.3; };
};
zone "1.68.10.in-addr.arpa" {
    type master;
    file "/etc/bind/db.1.68.10.in-addr.arpa";
    allow-transfer { 10.68.1.3; };
    also-notify { 10.68.1.3; };
};
CONF

touch /etc/bind/named.conf.local
if ! grep -Fq 'include "/etc/bind/k09-zones.conf";' /etc/bind/named.conf.local; then
    if grep -Eq '^[[:space:]]*zone[[:space:]]+"(jujutsu\.k09\.com|1\.68\.10\.in-addr\.arpa)"' /etc/bind/named.conf.local; then
        echo "Zona K09 sudah dideklarasikan di named.conf.local; deklarasi lama dipertahankan."
    else
        printf '\ninclude "/etc/bind/k09-zones.conf";\n' >> /etc/bind/named.conf.local
    fi
fi

cat > /etc/bind/named.conf.options <<'CONF'
options {
    directory "/var/cache/bind";
    recursion yes;
    forwarders { 192.168.122.1; };
    forward only;
    allow-query { 10.68.0.0/16; localhost; };
    allow-recursion { 10.68.0.0/16; localhost; };
    allow-query-cache { 10.68.0.0/16; localhost; };
    listen-on { any; };
    listen-on-v6 { none; };
};
CONF

named-checkconf
named-checkzone jujutsu.k09.com /etc/bind/db.jujutsu.k09.com
named-checkzone 1.68.10.in-addr.arpa /etc/bind/db.1.68.10.in-addr.arpa
service named restart
echo "DNS Master utahime aktif. Backup konfigurasi: $backup"
dig @127.0.0.1 jujutsu.k09.com SOA +short
