# Deploy Flutter Web App on EC2 - Accessible from Any Device

This guide will help you deploy your Flutter web app on EC2 so it's accessible via public IP from any device.

## Overview

You'll need to:
1. Build the Flutter web app
2. Copy it to EC2
3. Serve it using Nginx (web server)
4. Update API configuration to use EC2 IP
5. Access from any device using `http://YOUR_EC2_IP`

## Step 1: Build Flutter Web App

On your **local machine**:

```bash
# Navigate to project directory
cd vehicle_manager

# Install dependencies (if not done)
flutter pub get

# Update API config first (see Step 2 below)
# Then build web app
flutter build web --release

# The built files will be in: build/web/
```

## Step 2: Update API Configuration

Before building, update the API URL in your Flutter app:

**Edit `lib/services/config.dart`:**

```dart
class ApiConfig {
  // Replace YOUR_EC2_IP with your actual EC2 public IP
  // Example: 'http://54.123.45.67:3000/api'
  static const String baseUrl = 'http://YOUR_EC2_IP:3000/api';
  
  static String getBaseUrl() {
    return baseUrl;
  }
}
```

**Then rebuild:**
```bash
flutter build web --release
```

## Step 3: Install Nginx on EC2

SSH into your EC2 instance:

```bash
ssh -i your-key.pem ubuntu@YOUR_EC2_IP
```

Install Nginx:

```bash
# Update packages
sudo apt update

# Install Nginx
sudo apt install -y nginx

# Start Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Check status
sudo systemctl status nginx
```

## Step 4: Configure Nginx

Create Nginx configuration:

```bash
sudo nano /etc/nginx/sites-available/vehicle-manager
```

Add this configuration (replace `YOUR_EC2_IP` with your actual IP):

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

Enable the site:

```bash
# Create symlink
sudo ln -s /etc/nginx/sites-available/vehicle-manager /etc/nginx/sites-enabled/

# Remove default site (optional)
sudo rm /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# If test passes, reload Nginx
sudo systemctl reload nginx
```

## Step 5: Upload Flutter Web App to EC2

### Option A: Using SCP (from your local machine)

```bash
# From your local machine (replace with your EC2 IP)
scp -i your-key.pem -r build/web/* ubuntu@YOUR_EC2_IP:/tmp/vehicle_manager/
```

Then on EC2:

```bash
# Create directory
sudo mkdir -p /var/www/vehicle_manager

# Copy files
sudo cp -r /tmp/vehicle_manager/* /var/www/vehicle_manager/

# Set permissions
sudo chown -R www-data:www-data /var/www/vehicle_manager
sudo chmod -R 755 /var/www/vehicle_manager
```

### Option B: Using Git (Recommended)

If your code is in a Git repository:

On EC2:
```bash
# Clone repository
cd ~
git clone YOUR_REPOSITORY_URL vehicle_manager
cd vehicle_manager

# Build on EC2 (requires Flutter SDK installed, or use Option A instead)
# Or just copy build/web/ from local machine
```

### Option C: Using ZIP

On local machine:
```bash
cd vehicle_manager
cd build
zip -r web_app.zip web/
```

Upload to EC2:
```bash
scp -i your-key.pem web_app.zip ubuntu@YOUR_EC2_IP:~/
```

On EC2:
```bash
# Extract
cd ~
unzip web_app.zip

# Move to web directory
sudo mkdir -p /var/www/vehicle_manager
sudo cp -r web/* /var/www/vehicle_manager/
sudo chown -R www-data:www-data /var/www/vehicle_manager
sudo chmod -R 755 /var/www/vehicle_manager
```

## Step 6: Update Security Group

Ensure Security Group allows HTTP (port 80):

1. AWS Console → EC2 → Security Groups
2. Select your security group
3. Edit inbound rules
4. Add rule:
   - Type: HTTP
   - Port: 80
   - Source: 0.0.0.0/0 (or specific IPs)
   - Description: Web App

## Step 7: Verify Everything Works

### Test API (should work):
```bash
curl http://localhost/api/health
```

### Test from browser:
1. Open browser
2. Go to: `http://YOUR_EC2_IP`
3. You should see your Flutter app!

### Test from another device:
1. Connect to same network (or use mobile data)
2. Open browser
3. Go to: `http://YOUR_EC2_IP`
4. Sign up and test the app

## Step 8: Update API Config (Important!)

Since we're now using Nginx proxy, the API calls should go through `/api` path (not `:3000/api`).

**Update `lib/services/config.dart`:**

```dart
class ApiConfig {
  // Use relative path since we're on same domain
  // This will work: http://YOUR_EC2_IP/api
  static const String baseUrl = '/api';
  
  // OR use full URL (works too)
  // static const String baseUrl = 'http://YOUR_EC2_IP/api';
  
  static String getBaseUrl() {
    return baseUrl;
  }
}
```

**Rebuild and redeploy:**
```bash
# On local machine
flutter build web --release

# Upload again (Step 5)
scp -i your-key.pem -r build/web/* ubuntu@YOUR_EC2_IP:/var/www/vehicle_manager/
```

## Access from Different Devices

### From Same Network:
- Desktop/Laptop: `http://YOUR_EC2_IP`
- Mobile (WiFi): `http://YOUR_EC2_IP`
- Tablet: `http://YOUR_EC2_IP`

### From Different Network (Internet):
- Any device: `http://YOUR_EC2_IP`
- Works from anywhere in the world!

### Share with Others:
Just share the URL: `http://YOUR_EC2_IP`

## Troubleshooting

### 404 Not Found
- Check files are in `/var/www/vehicle_manager/`
- Check Nginx config: `sudo nginx -t`
- Check Nginx logs: `sudo tail -f /var/log/nginx/error.log`

### API Calls Fail
- Check API is running: `sudo docker-compose ps`
- Check Nginx proxy config
- Check browser console for errors
- Verify API config uses `/api` path

### CORS Errors
- Nginx proxy should handle this
- If still issues, check backend CORS settings

### Can't Access from Other Device
- Check Security Group allows port 80
- Check if using correct public IP
- Try accessing from same network first

## Update App (After Changes)

Whenever you make changes:

1. **Update code and rebuild:**
   ```bash
   flutter build web --release
   ```

2. **Upload to EC2:**
   ```bash
   scp -i your-key.pem -r build/web/* ubuntu@YOUR_EC2_IP:/var/www/vehicle_manager/
   ```

3. **No restart needed** - just refresh browser!

## Optional: Setup Domain Name

Instead of using IP address, you can use a domain:

1. Buy domain (Namecheap, GoDaddy, etc.)
2. Point DNS A record to EC2 IP
3. Update Nginx config:
   ```nginx
   server_name yourdomain.com www.yourdomain.com;
   ```
4. Access via: `http://yourdomain.com`

## Optional: Setup HTTPS (SSL)

For secure connection:

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Get SSL certificate (if you have domain)
sudo certbot --nginx -d yourdomain.com

# Auto-renewal is set up automatically
```

## Complete Setup Summary

```
┌─────────────────────────────────────────────────────────┐
│  EC2 Instance                                           │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  Nginx (Port 80)                                  │ │
│  │  - Serves Flutter web app from /var/www/...      │ │
│  │  - Proxies /api requests to localhost:3000       │ │
│  └──────────────────┬────────────────────────────────┘ │
│                     │                                    │
│  ┌──────────────────▼────────────────────────────────┐ │
│  │  Docker Container: API (Port 3000)                │ │
│  └──────────────────┬────────────────────────────────┘ │
│                     │                                    │
│  ┌──────────────────▼────────────────────────────────┐ │
│  │  Docker Container: PostgreSQL (Port 5432)         │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  Accessible at: http://YOUR_EC2_IP                    │
└─────────────────────────────────────────────────────────┘
```

## Quick Reference Commands

```bash
# View Nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# Restart Nginx
sudo systemctl restart nginx

# Check Nginx status
sudo systemctl status nginx

# Test Nginx config
sudo nginx -t

# View API logs
sudo docker-compose logs -f api

# Check containers
sudo docker-compose ps
```

