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

## 4️⃣ PHP 

```bash
systemctl daemon-reexec
systemctl daemon-reload

# Enable service on boot
systemctl enable qbittorrent-nox

Start the service
systemctl start qbittorrent-nox
```
---



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

---
