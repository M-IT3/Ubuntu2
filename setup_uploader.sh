#!/bin/bash

# Variables
SERVER_IP="51.91.102.9"
WEB_DIR="/home/ubuntu/Downloads/http/"
NGINX_CONF_FILE="/etc/nginx/sites-available/uploader"
NGINX_SITE_ENABLED="/etc/nginx/sites-enabled/uploader"
NODE_PORT=3000

# Step 1: Install Node.js, Nginx, and required dependencies
echo "Installing Node.js, Nginx, and other dependencies..."
sudo apt update
sudo apt install -y nodejs npm nginx

# Step 2: Set up project directory
echo "Setting up project directory at $WEB_DIR..."
mkdir -p $WEB_DIR
cd $WEB_DIR

# Step 3: Create package.json
cat <<EOF > package.json
{
  "name": "http",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC"
}
EOF

# Step 4: Install required npm packages
echo "Installing Node.js dependencies..."
npm install express multer

# Step 5: Create server.js file to handle file uploads
cat <<EOF > server.js
const express = require('express');
const multer = require('multer');
const fs = require('fs');
const path = require('path');

const app = express();

// Setup file storage with Multer
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/');  // Directory where files will be saved
  },
  filename: function (req, file, cb) {
    cb(null, file.originalname);  // Use the original file name
  }
});

// Set up Multer upload configuration for large files (7GB max)
const upload = multer({
  storage: storage,
  limits: { fileSize: 7 * 1024 * 1024 * 1024 }  // 7GB
});

// Create uploads folder if it doesn't exist
if (!fs.existsSync('uploads')) {
  fs.mkdirSync('uploads');
}

// Define upload route
app.post('/upload', upload.single('file'), (req, res) => {
  if (!req.file) {
    return res.status(400).send('No file uploaded.');
  }
  res.send('File uploaded successfully!');
});

// Start the server
const PORT = $NODE_PORT;
app.listen(PORT, () => {
  console.log(\`Server running on http://$SERVER_IP:\${PORT}\`);
});
EOF

# Step 6: Create index.html for front-end (simple file upload form)
cat <<EOF > index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>File Upload</title>
</head>
<body>
  <h1>Upload File (up to 7GB)</h1>
  <form action="http://$SERVER_IP:$NODE_PORT/upload" method="POST" enctype="multipart/form-data">
    <input type="file" name="file" required><br><br>
    <input type="submit" value="Upload File">
  </form>
</body>
</html>
EOF

# Step 7: Configure Nginx to serve Node.js app and handle large file uploads
echo "Configuring Nginx..."
sudo bash -c "cat <<EOF > $NGINX_CONF_FILE
server {
    listen 80;
    server_name $SERVER_IP;

    # Allow large file uploads (7GB)
    client_max_body_size 10G;

    location / {
        proxy_pass http://localhost:$NODE_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF"

# Step 8: Create a symbolic link in the Nginx sites-enabled directory
echo "Enabling Nginx site..."
sudo ln -s $NGINX_CONF_FILE $NGINX_SITE_ENABLED

# Step 9: Reload Nginx to apply configuration
echo "Reloading Nginx..."
sudo systemctl reload nginx

# Step 10: Increase system file descriptors and limits for large files
echo "Increasing system file descriptors and limits..."
sudo bash -c "cat <<EOF >> /etc/security/limits.conf
*          soft    nofile      65536
*          hard    nofile      65536
EOF"

# Increase the max allowed memory
sudo bash -c "cat <<EOF >> /etc/sysctl.conf
fs.file-max = 1000000
vm.max_map_count = 262144
EOF"
sudo sysctl -p

# Step 11: Open ports in firewall (if UFW is active)
echo "Configuring firewall..."
sudo ufw allow 'Nginx Full'
sudo ufw allow 3000/tcp  # Allow Node.js port

# Step 12: Start Node.js server
echo "Starting Node.js server..."
node server.js &

# Step 13: Final message
echo "Setup complete! You can now access the file uploader at http://$SERVER_IP"
echo "File upload form is located at http://$SERVER_IP"
