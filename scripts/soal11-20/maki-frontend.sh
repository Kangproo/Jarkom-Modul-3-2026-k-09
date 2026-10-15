#!/bin/bash
# maki - frontend PHP-FPM, soal 14. Tidak mengubah IP/gateway.
set -euo pipefail
[ "$(hostname)" = "maki" ] || { echo "ERROR: script khusus maki"; exit 1; }

if ! command -v nginx >/dev/null 2>&1 || ! command -v php >/dev/null 2>&1 || [ ! -f /etc/php/8.4/fpm/pool.d/www.conf ]; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx php-fpm php-cli curl
fi

backup="$(mktemp -d /root/k09-maki-frontend-XXXXXX)"
for f in /etc/nginx/sites-available/default /var/www/html/index.php; do
    [ ! -f "$f" ] || cp -a "$f" "$backup/"
done

mkdir -p /var/www/html
cat > /var/www/html/index.php <<'PHP'
<?php
$node = htmlspecialchars(gethostname() ?: 'unknown', ENT_QUOTES, 'UTF-8');
$address = htmlspecialchars($_SERVER['SERVER_ADDR'] ?? '-', ENT_QUOTES, 'UTF-8');
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Frontend K-09</title>
</head>
<body>
    <h1>Frontend K-09</h1>
    <p>Server: <?= $node ?></p>
    <p>IP Server: <?= $address ?></p>
</body>
</html>
PHP

cat > /etc/nginx/sites-available/default <<'CONF'
server {
    listen 80 default_server;
    server_name _;
    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }
}
CONF

[ -e /etc/nginx/sites-enabled/default ] || ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
php -l /var/www/html/index.php
nginx -t
service php8.4-fpm start
if service nginx status >/dev/null 2>&1; then
    service nginx reload
else
    service nginx start
fi
echo "Frontend maki aktif. Backup: $backup"
curl -fsS --max-time 5 http://127.0.0.1/ | grep -E 'Frontend K-09|Server:'
