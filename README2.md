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
