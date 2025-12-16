##  4️⃣ QBittorrent
```bash

apt install software-properties-common
add-apt-repository ppa:qbittorrent-team/qbittorrent-stable
apt update
apt install qbittorrent-nox
```
---

## 4️⃣ QBittorrent Service 
```bash
cat <<'EOF' | sudo tee /etc/systemd/system/qbittorrent-nox.service > /dev/null
[Unit]
Description=qBittorrent NoX Service
After=network.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/bin/qbittorrent-nox --webui-port=8080
Restart=on-failure
LimitNOFILE=100000

[Install]
WantedBy=multi-user.target
EOF
```
---



```bash
systemctl daemon-reexec
systemctl daemon-reload

# Enable service on boot
systemctl enable qbittorrent-nox

Start the service
systemctl start qbittorrent-nox
```
---



## 4️⃣ PHP | 
```bash
# Install stack
sudo apt install -y nginx php php-fpm

# Directory to host files
mkdir -p ~/Downloads/http
chmod -R 755 ~/Downloads/http
sudo chown -R ubuntu:ubuntu /home/ubuntu/Downloads/http
sudo chmod -R 755 /home/ubuntu/Downloads/http
sudo chmod o+x /home
sudo chmod o+x /home/ubuntu
sudo chmod o+x /home/ubuntu/Downloads

# Default site config
cat <<'EOF' | sudo tee /etc/nginx/sites-available/default > /dev/null
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /home/ubuntu/Downloads/http;
    index index.html index.php;

    server_name _;

    location / {
        autoindex on;                # show file list
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;   # adjust if needed
    }

    location ~ /.ht { deny all; }
}
EOF

sudo systemctl restart nginx php8.4-fpm
```
> Place any static files in `~/Downloads/http` and access them via `<server-ip>/`.
---

