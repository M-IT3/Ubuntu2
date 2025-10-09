> **TL;DR**
> 1. Upgrade to GNOME (or XFCE).
> 2. Install XRDP / SSH for remote access.
> 3. Add common GUI apps (Firefox, Chrome, VLC, qBittorrent).
> 4. Expose a public share via Samba or Nginx.
> 5. Optional: web‑file manager, JDownloader, aria2c + monitoring tools.

---

## Table of Contents

| Section | Description |
|---------|-------------|
| [Prerequisites](#prerequisites) | What you need before running the script |
| [1️⃣ Upgrade Ubuntu & Install Desktop](#upgrade-ubuntu-and-install-desktop) | GNOME or XFCE – choose your UI |
| [2️⃣ Remote Access (XRDP / SSH)](#remote-access-xrdp--ssh) | Set up RDP and/or SSH access |
| [3️⃣ Core GUI Apps](#core-gui-apps) | Firefox, Chrome, VLC, qBittorrent |
| [4️⃣ Shared Directories](#shared-directories) | Samba or Nginx file server |
| [5️⃣ Advanced Downloaders](#advanced-downloaders) | aria2c & JDownloader |
| [6️⃣ Monitoring / Utilities](#monitoring--utilities) | Glances, Netdata, etc. |
| [7️⃣ Cleanup & Reboot](#cleanup--reboot) | Final steps |
| [⚙️ Automate All of the Above](#automate-all-of-the-above) | One‑liner script |

---

## Prerequisites
```bash
sudo apt update && sudo apt upgrade -y          # keep your system up‑to‑date
```
> **Tip:** If you’re running a *cloud* VM, make sure the firewall allows at least port `22` (SSH) and later `3389` (RDP).

---

## 1️⃣ Upgrade Ubuntu & Install Desktop

### GNOME (default Ubuntu UI)
```bash
sudo apt install ubuntu-desktop -y
# Optional: set graphical.target as default boot target
sudo systemctl set-default graphical.target
```

### KDE Plasma (Kubuntu) lighter than GNOME.
```bash
sudo apt install kubuntu-desktop -y
# Optional: set graphical.target as default boot target
sudo systemctl set-default graphical.target
```

### XFCE (lighter alternative)
```bash
sudo apt install xfce4 xfce4-goodies -y
echo "xfce4-session" > ~/.xsession   # use XFCE for XRDP sessions
```

---

## 2️⃣ Remote Access (XRDP / SSH)
```bash
# ---- XRDP ----
sudo apt install xrdp -y
sudo systemctl enable --now xrdp
# Add your user to the ssl-cert group so RDP can authenticate
sudo adduser $USER ssl-cert
# Allow RDP in UFW
sudo ufw allow 3389/tcp
# sudo reboot   # required after adding user to ssl‑cert

# ---- SSH (if not already enabled) ----
sudo systemctl enable --now ssh
sudo ufw allow OpenSSH
```
> After reboot, you can connect with any RDP client (`mstsc` on Windows, Remmina on Linux, etc.).

---

## 3️⃣ Core GUI Apps
```bash
# Update package lists
sudo apt update

# Firefox (pre‑installed on most Ubuntu flavours)
sudo apt install -y firefox

# Google Chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y ./google-chrome-stable_current_amd64.deb
sudo apt -f install -y   # fix deps if needed

# VLC + codecs
sudo apt install -y vlc
sudo apt install -y ubuntu-restricted-extras gstreamer1.0-libav \
    gstreamer1.0-plugins-{good,bad,ugly} ffmpeg

# qBittorrent (works well with XRDP)
sudo apt install -y qbittorrent

# Optional: set up dedicated download folders
mkdir -p ~/Downloads/TMP ~/Downloads/N
chown -R $USER:$USER ~/Downloads/{TMP,N}
chmod -R 755 ~/Downloads/{TMP,N}
```
---


##  QBittorrent
```bash
sudo apt install -y qbittorrent

# Optional: set up dedicated download folders
mkdir -p ~/Downloads/TMP ~/Downloads/N
chown -R $USER:$USER ~/Downloads/{TMP,N}
chmod -R 755 ~/Downloads/{TMP,N}

sudo ufw status
sudo ufw allow 48844/tcp
sudo ufw allow 48844/udp
sudo ufw reload

# ~/.config/qBittorrent/


mkdir -p ~/.config/qBittorrent
wget https://raw.githubusercontent.com/M-IT3/Ubuntu2/refs/heads/main/qBittorrent.conf -O ~/.config/qBittorrent/qBittorrent.conf

```
---



## 4️⃣ Shared Directories
### A. Samba (SMB)
```bash
# Create public folder
sudo mkdir -p /home/ubuntu/public
sudo chown nobody:nogroup /home/ubuntu/public
sudo chmod 0777 /home/ubuntu/public

# Configure smb.conf
cat <<EOF | sudo tee /etc/samba/smb.conf > /dev/null
[global]
   workgroup = WORKGROUP
   security = user
   map to guest = bad user
   wins support = no
   no dns proxy = yes

[public]
   path = /home/ubuntu/public
   browsable = yes
   writable = yes
   guest ok = yes
   force user = nobody
EOF

sudo systemctl restart smbd
sudo ufw allow 137,138,139,445/tcp
sudo ufw allow 137,138,139,445/udp
```
> Browse the share from Windows or Linux with `\\<server-ip>\public`.

### B. Nginx (HTTP)
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


### Add index
```bash

cat <<'EOF' | sudo tee /home/ubuntu/Downloads/http/index.php > /dev/null
<!DOCTYPE html>
<html>
<head>
    <title>File Links</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 30px;
        }
        textarea {
            width: 100%;
            height: 300px;
            font-family: monospace;
            font-size: 14px;
        }
        button {
            margin-top: 10px;
            padding: 10px 15px;
            font-size: 16px;
            margin-right: 10px;
        }
    </style>
</head>
<body>

<h2>All File Links (excluding .php)</h2>

<?php
$directory = '.';
$baseUrl = (isset($_SERVER['HTTPS']) ? "https://" : "http://") . $_SERVER['HTTP_HOST'] . dirname($_SERVER['REQUEST_URI']);

$files = [];
if ($handle = opendir($directory)) {
    while (false !== ($entry = readdir($handle))) {
        $filePath = $directory . '/' . $entry;
        if ($entry != "." && $entry != ".." && is_file($filePath) && pathinfo($entry, PATHINFO_EXTENSION) !== 'php') {
            $files[] = $baseUrl . '/' . rawurlencode($entry);
        }
    }
    closedir($handle);
}
?>

<textarea id="fileLinks" readonly><?php echo implode("\n", $files); ?></textarea>
<br>
<button onclick="copyLinks()">Copy All Links</button>
<button onclick="downloadLinks()">Download All</button>

<script>
function copyLinks() {
    const textarea = document.getElementById('fileLinks');
    textarea.select();
    document.execCommand('copy');
}

function downloadLinks() {
    const links = document.getElementById('fileLinks').value.trim().split('\n');

    if (!links.length || links[0] === '') {
        alert("No links to send.");
        return;
    }

    fetch('aria2_download.php', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ links: links })
    })
    .then(response => response.json())
    .then(data => {
        alert(data.message);
        console.log(data);
    })
    .catch(error => {
        alert("Failed to send download request.");
        console.error(error);
    });
}
</script>

</body>
</html>

EOF


```

---



## 5️⃣ Advanced Downloaders
### aria2c (RPC + BitTorrent)
```bash
sudo apt install -y aria2
mkdir -p ~/Downloads/Aria
chmod -R 755 ~/Downloads/Aria
```

```bash
aria2c --enable-rpc \
  --rpc-listen-port=6800 \
  -D \
  -d /home/ubuntu/Downloads/Aria/ \
  --max-connection-per-server=16 \
  --min-split-size=1M \
  --split=16 \
  --max-concurrent-downloads=48 \
  --max-overall-download-limit=0 \
  --max-upload-limit=300 \
  --bt-request-peer-speed-limit=10M \
  --bt-max-peers=55 \
  --seed-ratio=1.0 \
  --follow-torrent=true \
  --disable-ipv6=true \
  --user-agent="Mozilla/5.0" \
  --check-certificate=false \
  --rpc-secure=false \
  --rpc-listen-all=true

```
> Stop with `killall aria2c` or check status with `ps aux | grep aria2c`.

### JDownloader (Java)
```bash
sudo apt install -y default-jre
mkdir -p ~/jd2 ~/jd2/JDownloader2

wget http://installer.jdownloader.org/JDownloader2Setup_unix_nojre.sh -O ~/jd2/JDownloader2Setup.sh
chmod +x ~/jd2/JDownloader2Setup.sh && ~/jd2/JDownloader2Setup.sh -q -dir ~/jd2/JDownloader2
```
---

## 6️⃣ Monitoring / Utilities
```bash
# Glances (CLI & web)
sudo apt install -y glances
pip install 'glances[web]'   # for the web UI

# Netdata (real‑time monitoring)
bash <(curl -L https://my-netdata.io/kickstart.sh) --dont-wait --dont-start-it

# Start services if you want them immediately:
sudo systemctl enable netdata
sudo systemctl start netdata
```
---

## 7️⃣ Cleanup & Reboot
```bash
sudo apt autoremove -y
sudo reboot   # final reboot to apply all changes
```
---

## Add -User
```bash
sudo adduser vortex
sudo adduser vortex ssl-cert
sudo systemctl restart ssh

## Root Access
sudo usermod -aG sudo vortex
groups vortex
sudo whoami

sudo visudo
Vortex ALL=(ALL) NOPASSWD: /usr/bin/apt-get, /usr/bin/dpkg
# vortex  ALL=(ALL) NOPASSWD: ALL

ssh Vortex@<your_server_ip>


## Delete User
 sudo deluser vortex
 sudo deluser --remove-home vortex
 sudo deluser vortex ssl-cert
 cat /etc/passwd | grep vortex


```
---



## ⚙️ Automate All of the Above
Copy the following script into a file, e.g. `setup.sh`, make it executable and run it.
```bash
#!/usr/bin/env bash
set -euo pipefail

# 1️⃣ Upgrade & install desktop
sudo apt update && sudo apt upgrade -y
sudo DEBIAN_FRONTEND=noninteractive apt install -y ubuntu-desktop   # or xfce4

# 2️⃣ XRDP + SSH
sudo apt install -y xrdp
sudo systemctl enable --now xrdp
sudo adduser $USER ssl-cert
sudo ufw allow 3389/tcp
sudo systemctl enable --now ssh
sudo ufw allow OpenSSH

# 3️⃣ GUI apps
sudo apt install -y firefox
wget -qO- https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb | sudo apt install -y -
sudo apt -f install -y
sudo apt install -y vlc ubuntu-restricted-extras gstreamer1.0-libav \
    gstreamer1.0-plugins-{good,bad,ugly} ffmpeg qbittorrent

# 4️⃣ Samba share
sudo mkdir -p /home/ubuntu/public
sudo chown nobody:nogroup /home/ubuntu/public
sudo chmod 0777 /home/ubuntu/public
cat <<'EOF' | sudo tee /etc/samba/smb.conf > /dev/null
[global]
   workgroup = WORKGROUP
   security = user
   map to guest = bad user
   wins support = no
   no dns proxy = yes

[public]
   path = /home/ubuntu/public
   browsable = yes
   writable = yes
   guest ok = yes
   force user = nobody
EOF
sudo systemctl restart smbd
sudo ufw allow 137,138,139,445/tcp

# 5️⃣ Nginx file server
sudo apt install -y nginx php php-fpm
mkdir -p ~/Downloads/http
chmod -R 755 ~/Downloads/http
cat <<'EOF' | sudo tee /etc/nginx/sites-available/default > /dev/null
server {
    listen 80 default_server;
    root /home/ubuntu/Downloads/http;
    index index.html index.php;
    location / { autoindex on; try_files $uri $uri/ =404; }
    location ~ \.php$ { include snippets/fastcgi-php.conf; fastcgi_pass unix:/run/php/php8.4-fpm.sock; }
}
EOF
sudo systemctl restart nginx php8.4-fpm

# 6️⃣ aria2c RPC
sudo apt install -y aria2
mkdir -p ~/Downloads/Aria
aria2c --enable-rpc --rpc-listen-port=6800 -D -d ~/Downloads/Aria/

# 7️⃣ JDownloader
sudo apt install -y default-jre
mkdir -p /home/ubuntu/JDownloader2
wget http://installer.jdownloader.org/JDownloader2Setup_unix_nojre.sh -O /home/ubuntu/JDownloader2/setup.sh
chmod +x /home/ubuntu/JDownloader2/setup.sh
/home/ubuntu/JDownloader2/setup.sh -q -dir /home/ubuntu/JDownloader2


# 7️⃣ Visual Studio Code (VS Code)
CD Downloads 
wget https://vscode.download.prss.microsoft.com/dbazure/download/stable/03c265b1adee71ac88f833e065f7bb956b60550a/code_1.105.0-1759933565_amd64.deb
sudo dpkg -i code_1.105.0-1759933565_amd64.deb
sudo apt --fix-broken install

# Python 
sudo apt install python3-pip
sudo apt install python3-venv

python3 -m venv ~/Desktop/myenv
source ~/Desktop/myenv/bin/activate




# 8️⃣ Monitoring
sudo apt install -y glances
pip install 'glances[web]'
bash <(curl -L https://my-netdata.io/kickstart.sh) --dont-wait --dont-start-it

echo "Setup complete! Rebooting..."
sudo reboot
```
> **Usage**
> ```bash
> chmod +x setup.sh
> ./setup.sh
> ```
---

## 🎉 Final Thoughts
- The script above is a *minimal* but powerful starting point.
- Feel free to tweak versions (e.g., PHP 8.1 vs 8.4) or add additional services like Docker, GitLab, etc.
- Always test in a non‑production environment first.

Happy hacking! 🚀
