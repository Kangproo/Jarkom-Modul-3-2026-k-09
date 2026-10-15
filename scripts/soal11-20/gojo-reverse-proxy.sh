#!/bin/bash
# gojo - reverse proxy, cache frontend, API rate limit (soal 16 dan 19).
# Script ini menggunakan konfigurasi AKHIR, agar fitur 19 tidak hilang.
set -euo pipefail
[ "$(hostname)" = "gojo" ] || { echo "ERROR: khusus node gojo"; exit 1; }

if ! command -v nginx >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx curl
fi

backup="$(mktemp -d /root/k09-gojo-nginx-XXXXXX)"
for f in /etc/nginx/sites-available/default /etc/nginx/conf.d/k09-performance.conf; do
    [ ! -f "$f" ] || cp -a "$f" "$backup/"
done
install -d -o www-data -g www-data -m 755 /var/cache/nginx/k09

# conf.d dimuat dalam konteks "http" pada konfigurasi Nginx Debian.
cat > /etc/nginx/conf.d/k09-performance.conf <<'CONF'
proxy_cache_path /var/cache/nginx/k09
    levels=1:2
    keys_zone=k09_cache:10m
    max_size=50m
    inactive=10m
    use_temp_path=off;

limit_req_zone $binary_remote_addr
    zone=k09_api_limit:10m
    rate=10r/s;
CONF

cat > /etc/nginx/sites-available/default <<'CONF'
upstream k09_frontend {
    server 10.68.4.3:80;
    server 10.68.4.4:80;
}

server {
    listen 80 default_server;
    server_name jujutsu.k09.com;

    location = /api {
        limit_req zone=k09_api_limit burst=10 nodelay;
        limit_req_status 429;

        proxy_pass http://10.68.4.2;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location / {
        proxy_pass http://k09_frontend;

        proxy_cache k09_cache;
        proxy_cache_valid 200 10m;
        proxy_cache_key "$scheme$host$request_uri";
        add_header X-Cache-Status $upstream_cache_status always;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
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
echo "Gojo Nginx aktif (reverse proxy + cache 10m + API 10r/s). Backup: $backup"
echo "Cache : curl -I -H 'Host: jujutsu.k09.com' http://127.0.0.1/"
echo "API   : curl -i -H 'Host: jujutsu.k09.com' http://127.0.0.1/api"
