#!/bin/bash
# geto - Weighted API load balancer, IP asli & failover (soal 15,17,18).
# Hanya konfigurasi Nginx. Tidak mengubah IP atau layanan worker lain.
set -euo pipefail
[ "$(hostname)" = "geto" ] || { echo "ERROR: khusus node geto"; exit 1; }

if ! command -v nginx >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx curl
fi

backup="$(mktemp -d /root/k09-geto-nginx-XXXXXX)"
for f in /etc/nginx/sites-available/default /etc/nginx/conf.d/k09-no17-realip.conf; do
    [ ! -f "$f" ] || cp -a "$f" "$backup/"
done

# IP client yang datang dari Gojo diterima sebagai X-Real-IP.
# Alamat asal lain TIDAK dipercaya sebagai proxy resmi.
cat > /etc/nginx/conf.d/k09-no17-realip.conf <<'CONF'
set_real_ip_from 10.68.1.4;
real_ip_header X-Real-IP;
CONF

cat > /etc/nginx/sites-available/default <<'CONF'
upstream k09_api_workers {
    server 10.68.4.5:80 weight=3 max_fails=2 fail_timeout=5s;
    server 10.68.4.6:80 weight=1 max_fails=2 fail_timeout=5s;
    server 10.68.4.7:80 backup;
}

server {
    listen 80 default_server;
    server_name _;

    location = /api {
        proxy_pass http://k09_api_workers;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location / {
        return 404;
    }
}
CONF

[ -e /etc/nginx/sites-enabled/default ] || ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
nginx -t
if service nginx status >/dev/null 2>&1; then
    service nginx reload
else
    service nginx start
fi
echo "Geto Nginx siap (3:1, Kirara backup). Backup: $backup"
echo "Periksa: curl -i http://127.0.0.1/api"
