# Step-by-Step: Deploy Flutter Web App on EC2

Complete walkthrough with exact commands to follow.

## Prerequisites
- EC2 instance running and accessible
- Backend API already deployed and running (from previous steps)
- Your EC2 public IP address (e.g., `54.123.45.67`)

---

## Step 1: Build Flutter Web App (On Your Local Machine)

### 1.1 Navigate to project directory
```bash
cd vehicle_manager
```

### 1.2 Install dependencies (if needed)
```bash
flutter pub get
```

### 1.3 Build web app
```bash
flutter build web --release
```

This will create the web app in `build/web/` directory.

**Verify it worked:**
```bash
ls build/web/
# Should show files like: index.html, main.dart.js, etc.
```

---

## Step 2: Install Nginx on EC2

### 2.1 SSH into your EC2 instance
```bash
ssh -i your-key.pem ubuntu@YOUR_EC2_IP
```

Replace:
- `your-key.pem` with your actual key file name
- `YOUR_EC2_IP` with your actual EC2 IP (e.g., `54.123.45.67`)

### 2.2 Update system packages
```bash
sudo apt update
```

### 2.3 Install Nginx
```bash
sudo apt install -y nginx
```

### 2.4 Start and enable Nginx
```bash
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 2.5 Verify Nginx is running
```bash
sudo systemctl status nginx
```

You should see "active (running)" in green.

**Test it:**
```bash
curl http://localhost
# Should show Nginx default welcome page HTML
```

---

## Step 3: Create Directory and Upload Files

### 3.1 Create web directory
Still on EC2, run:
```bash
sudo mkdir -p /var/www/vehicle_manager
sudo chown -R ubuntu:ubuntu /var/www/vehicle_manager
```

### 3.2 Upload Flutter web files from your local machine

**Open a NEW terminal window on your LOCAL machine** (keep EC2 SSH session open).

#### Option A: Using SCP (Recommended)

```bash
# From your local machine, navigate to project
cd vehicle_manager

# Upload all files
scp -i your-key.pem -r build/web/* ubuntu@YOUR_EC2_IP:/var/www/vehicle_manager/
```

Replace:
- `your-key.pem` with your key file path
- `YOUR_EC2_IP` with your EC2 IP

#### Option B: Using ZIP (If SCP has issues)

**On local machine:**
```bash
cd vehicle_manager/build
zip -r web_app.zip web/
scp -i your-key.pem web_app.zip ubuntu@YOUR_EC2_IP:~/
```

**Back on EC2 (in your SSH session):**
```bash
cd ~
unzip web_app.zip
sudo cp -r web/* /var/www/vehicle_manager/
sudo chown -R www-data:www-data /var/www/vehicle_manager
```

### 3.3 Set correct permissions
**On EC2:**
```bash
sudo chown -R www-data:www-data /var/www/vehicle_manager
sudo chmod -R 755 /var/www/vehicle_manager
```

### 3.4 Verify files are uploaded
```bash
ls -la /var/www/vehicle_manager/
# Should show: index.html, main.dart.js, assets/, etc.
```

---

## Step 4: Configure Nginx

### 4.1 Create Nginx configuration file

**On EC2:**
```bash
sudo nano /etc/nginx/sites-available/vehicle-manager
```

### 4.2 Paste this configuration

**Replace `YOUR_EC2_IP` with your actual EC2 IP** (e.g., `54.123.45.67`)

```nginx
server {
    listen 80;
    server_name YOUR_EC2_IP;

    # Serve Flutter web app
    root /var/www/vehicle_manager;
    index index.html;

    # Handle Flutter routing (SPA)
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API proxy - forwards /api requests to Node.js backend
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### 4.3 Save and exit

In nano editor:
- Press `Ctrl + O` to save
- Press `Enter` to confirm
- Press `Ctrl + X` to exit

### 4.4 Enable the site
```bash
sudo ln -s /etc/nginx/sites-available/vehicle-manager /etc/nginx/sites-enabled/
```

### 4.5 Remove default site (optional but recommended)
```bash
sudo rm /etc/nginx/sites-enabled/default
```

### 4.6 Test Nginx configuration
```bash
sudo nginx -t
```

Should output:
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

### 4.7 Reload Nginx
```bash
sudo systemctl reload nginx
```

---

## Step 5: Update Security Group (AWS Console)

### 5.1 Go to AWS Console
1. Open AWS Console → EC2
2. Click "Instances" in left menu
3. Click your EC2 instance

### 5.2 Open Security Group
1. Click "Security" tab (at bottom)
2. Click the Security Group link (e.g., `sg-0123456789abcdef0`)

### 5.3 Edit Inbound Rules
1. Click "Edit inbound rules" button
2. Click "Add rule"
3. Fill in:
   - **Type**: HTTP
   - **Port**: 80
   - **Source**: `0.0.0.0/0` (or select "My IP" if you only want your IP)
   - **Description**: Web App
4. Click "Save rules"

---

## Step 6: Test Everything

### 6.1 Test API through proxy (on EC2)
```bash
curl http://localhost/api/health
# Should return: {"status":"ok"}
```

### 6.2 Test web app locally (on EC2)
```bash
curl http://localhost
# Should return HTML content
```

### 6.3 Test from your local machine browser

Open browser and go to:
```
http://YOUR_EC2_IP
```

Replace `YOUR_EC2_IP` with your actual IP.

You should see your Flutter app login page!

### 6.4 Test from mobile device

1. Connect mobile to WiFi (or use mobile data)
2. Open browser
3. Go to: `http://YOUR_EC2_IP`
4. Should see your app!

---

## Step 7: Verify Complete Setup

### 7.1 Check all services are running

**On EC2:**
```bash
# Check Docker containers
sudo docker-compose ps

# Should show both api and postgres as "Up"

# Check Nginx
sudo systemctl status nginx

# Should show "active (running)"
```

### 7.2 Test the full flow

1. Open browser → `http://YOUR_EC2_IP`
2. Sign up with a new account
3. Add a vehicle
4. Verify it appears in dashboard

---

## Troubleshooting

### Issue: "502 Bad Gateway" when accessing app

**Solution:**
```bash
# Check if API container is running
sudo docker-compose ps

# If not running, start it
cd ~/vehicle_manager
sudo docker-compose up -d
```

### Issue: "404 Not Found" for web app

**Solution:**
```bash
# Check files exist
ls -la /var/www/vehicle_manager/

# Check Nginx config
sudo nginx -t

# Check Nginx error logs
sudo tail -f /var/log/nginx/error.log
```

### Issue: API calls fail (CORS or connection errors)

**Solution:**
- Verify API config uses `/api` (relative path)
- Check Nginx proxy config is correct
- Check backend logs: `sudo docker-compose logs api`

### Issue: Can't access from other device

**Solutions:**
1. Check Security Group allows port 80
2. Verify you're using correct public IP
3. Check firewall: `sudo ufw status`
4. If firewall is active: `sudo ufw allow 80/tcp`

---

## Quick Reference Commands

### View logs
```bash
# Nginx access logs
sudo tail -f /var/log/nginx/access.log

# Nginx error logs
sudo tail -f /var/log/nginx/error.log

# API logs
sudo docker-compose logs -f api
```

### Restart services
```bash
# Restart Nginx
sudo systemctl restart nginx

# Restart API
sudo docker-compose restart api
```

### Update app after changes
```bash
# 1. On local machine: Rebuild
flutter build web --release

# 2. Upload to EC2
scp -i your-key.pem -r build/web/* ubuntu@YOUR_EC2_IP:/var/www/vehicle_manager/

# 3. No restart needed - just refresh browser!
```

---

## Success Checklist

- [ ] Flutter web app built successfully
- [ ] Nginx installed and running
- [ ] Files uploaded to `/var/www/vehicle_manager/`
- [ ] Nginx configuration created and enabled
- [ ] Security Group allows port 80
- [ ] Can access app at `http://YOUR_EC2_IP`
- [ ] Can sign up and login
- [ ] Can add vehicles
- [ ] App works on mobile device

---

## Share Your App

Once everything works, you can share:

**URL:** `http://YOUR_EC2_IP`

Anyone with this URL can:
- Access your app from any device
- Sign up and create accounts
- Manage their vehicles
- Access from anywhere in the world!

**Note:** For production, consider:
- Setting up a domain name
- Adding SSL/HTTPS (Let's Encrypt)
- Securing with proper authentication
- Setting up backups

