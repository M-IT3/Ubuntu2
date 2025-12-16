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
mkdir -p /root/Downloads/q
chmod -R 755 /root/Downloads
sudo chown -R root:root /root/Downloads/q
sudo chmod -R 755 /root/Downloads/q
sudo chmod o+x /root
sudo chmod o+x /root/Downloads
sudo chmod o+x /root/Downloads/q

# Default site config
cat <<'EOF' | sudo tee /etc/nginx/sites-available/default > /dev/null
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /root/Downloads/q;
    index index.html index.php;

    server_name _;

    location / {
        autoindex on;                # show file list
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;   # adjust if needed
    }

    location ~ /.ht { deny all; }
}
EOF

sudo systemctl restart nginx php8.3-fpm
```
> Place any static files in `~/Downloads/http` and access them via `<server-ip>/`.
---

### Add index V-2 subDir
```bash

cat <<'EOF' | sudo tee /root/Downloads/q/index.php > /dev/null
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
            padding: 8px 14px;
            font-size: 15px;
            margin-right: 8px;
        }
        input[type="text"] {
            padding: 6px;
            font-size: 14px;
            width: 260px;
        }
        .controls {
            margin-bottom: 15px;
        }
    </style>
</head>
<body>

<h2>All File Links</h2>

<?php
set_time_limit(30);

/* ---------- CONFIG ---------- */
$baseDir = realpath('.');
$baseUrl = (isset($_SERVER['HTTPS']) ? "https://" : "http://")
    . $_SERVER['HTTP_HOST']
    . rtrim(dirname($_SERVER['REQUEST_URI']), '/');

/* ---------- IGNORE EXTENSIONS FROM INPUT ---------- */
$ignoreInput = $_GET['ignore'] ?? 'php,nfo,txt';
$ignoredExtensions = array_filter(array_map(
    'strtolower',
    array_map('trim', explode(',', $ignoreInput))
));

$files = [];

/* ---------- RECURSIVE SCAN ---------- */
function scanDirRecursive($dir, $baseDir, $baseUrl, &$files, $ignoredExtensions) {
    foreach (scandir($dir) as $item) {
        if ($item === '.' || $item === '..') continue;

        $fullPath = $dir . DIRECTORY_SEPARATOR . $item;

        if (is_dir($fullPath)) {
            scanDirRecursive($fullPath, $baseDir, $baseUrl, $files, $ignoredExtensions);
        } elseif (is_file($fullPath)) {
            $ext = strtolower(pathinfo($item, PATHINFO_EXTENSION));

            if (!in_array($ext, $ignoredExtensions)) {
                $relativePath = str_replace($baseDir . DIRECTORY_SEPARATOR, '', $fullPath);

                $encodedPath = implode('/', array_map(
                    'rawurlencode',
                    explode(DIRECTORY_SEPARATOR, $relativePath)
                ));

                $files[] = $baseUrl . '/' . $encodedPath;
            }
        }
    }
}

scanDirRecursive($baseDir, $baseDir, $baseUrl, $files, $ignoredExtensions);
sort($files);
$fileCount = count($files);
?>

<!-- ---------- CONTROLS ---------- -->
<div class="controls">
    <form method="get">
        <label>
            Ignore extensions:
            <input type="text" name="ignore"
                   value="<?php echo htmlspecialchars($ignoreInput); ?>">
        </label>
        <button type="submit">Refresh List</button>
    </form>
</div>

<h3>Total Files Found: <?php echo $fileCount; ?></h3>

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
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ links: links })
    })
    .then(res => res.json())
    .then(data => alert(data.message))
    .catch(err => {
        alert("Failed to send download request.");
        console.error(err);
    });
}
</script>

</body>
</html>
EOF
```


##  5️⃣ Advanced Downloaders

```bash

sudo apt install -y aria2
mkdir -p /root/Downloads/q/Aria
chmod -R 755 /root/Downloads/q/Aria
```
---

```bash

aria2c --enable-rpc \
  --rpc-listen-port=6800 \
  -D \
  -d /root/Downloads/q/Aria/ \
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
---
