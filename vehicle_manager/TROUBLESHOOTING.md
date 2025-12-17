# Troubleshooting: Connection Timeout to EC2 API

## Problem: Timeout when accessing `http://YOUR_EC2_IP:3000/health`

This usually means the connection is being blocked. Here are the most common causes and solutions:

## ✅ Solution 1: Check Security Group Rules

**The most common issue!** EC2 Security Group must allow inbound traffic on port 3000.

### Steps to Fix:

1. **Go to AWS Console** → EC2 → Security Groups
2. **Select your instance's security group**
3. **Click "Edit inbound rules"**
4. **Add rule:**
   ```
   Type: Custom TCP
   Port: 3000
   Source: My IP (or 0.0.0.0/0 for testing - change later!)
   Description: API Server
   ```
5. **Save rules**

### Verify:
```bash
# From your local machine
curl -v http://YOUR_EC2_IP:3000/health
```

## ✅ Solution 2: Check if Containers are Running

On EC2, run:
```bash
sudo docker-compose ps
```

You should see:
```
NAME                   STATUS          PORTS
vehicle_manager_api    Up X minutes    0.0.0.0:3000->3000/tcp
vehicle_manager_db     Up X minutes    0.0.0.0:5432->5432/tcp
```

If containers are not running:
```bash
cd ~/vehicle_manager
sudo docker-compose up -d
sudo docker-compose logs api
```

## ✅ Solution 3: Check EC2 Firewall (UFW)

Ubuntu may have a firewall blocking the port.

On EC2:
```bash
# Check firewall status
sudo ufw status

# If active, allow port 3000
sudo ufw allow 3000/tcp

# Or disable firewall for testing (NOT recommended for production)
sudo ufw disable
```

## ✅ Solution 4: Test from EC2 Itself

First, verify the API works locally on EC2:

```bash
# SSH into EC2
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# Test from within EC2
curl http://localhost:3000/health

# Should return: {"status":"ok"}
```

If this works but external access doesn't, it's a Security Group or firewall issue.

## ✅ Solution 5: Check API is Binding Correctly

The API must bind to `0.0.0.0`, not just `localhost`.

Check `backend/server.js`:
```javascript
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
```

Or in `docker-compose.yml`, the port mapping should be:
```yaml
ports:
  - "3000:3000"  # This maps host:container
```

## ✅ Solution 6: Check Docker Port Mapping

On EC2:
```bash
# Check what ports Docker is listening on
sudo netstat -tlnp | grep 3000

# Should show something like:
# tcp6  0  0 :::3000  :::*  LISTEN  <docker-process>
```

## ✅ Solution 7: Verify Correct EC2 IP

Make sure you're using the **Public IPv4 address**, not private IP.

In AWS Console → EC2 → Your Instance:
- Use **Public IPv4 address** (e.g., `54.123.45.67`)
- NOT Private IPv4 address (e.g., `172.31.x.x`)

## ✅ Solution 8: Check API Logs for Errors

On EC2:
```bash
# View real-time logs
sudo docker-compose logs -f api

# Check for errors
sudo docker-compose logs api | grep -i error
```

Common errors:
- Database connection failed
- Port already in use
- Permission denied

## Quick Diagnostic Checklist

Run these commands on EC2:

```bash
# 1. Are containers running?
sudo docker-compose ps

# 2. Can you access from localhost?
curl http://localhost:3000/health

# 3. Is port 3000 listening?
sudo netstat -tlnp | grep 3000

# 4. Check firewall
sudo ufw status

# 5. Check API logs
sudo docker-compose logs api --tail 50

# 6. Check database is ready
sudo docker-compose logs postgres --tail 20
```

## Step-by-Step Fix Procedure

1. **SSH into EC2:**
   ```bash
   ssh -i your-key.pem ubuntu@YOUR_EC2_IP
   ```

2. **Check containers:**
   ```bash
   cd ~/vehicle_manager
   sudo docker-compose ps
   ```

3. **If containers not running, start them:**
   ```bash
   sudo docker-compose up -d
   sudo docker-compose logs -f  # Watch for errors
   ```

4. **Test locally on EC2:**
   ```bash
   curl http://localhost:3000/health
   ```

5. **If local works, check Security Group:**
   - Go to AWS Console
   - EC2 → Security Groups
   - Edit inbound rules
   - Add Custom TCP port 3000 from your IP

6. **Check firewall:**
   ```bash
   sudo ufw allow 3000/tcp
   ```

7. **Test from your local machine:**
   ```bash
   curl http://YOUR_EC2_IP:3000/health
   ```

## Alternative: Use Nginx Reverse Proxy (Recommended for Production)

Instead of exposing port 3000 directly, use Nginx on port 80:

1. **Install Nginx on EC2:**
   ```bash
   sudo apt update
   sudo apt install nginx
   ```

2. **Create Nginx config:**
   ```bash
   sudo nano /etc/nginx/sites-available/vehicle-manager
   ```

3. **Add configuration:**
   ```nginx
   server {
       listen 80;
       server_name YOUR_EC2_IP;

       location /api {
           proxy_pass http://localhost:3000;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_cache_bypass $http_upgrade;
       }
   }
   ```

4. **Enable site:**
   ```bash
   sudo ln -s /etc/nginx/sites-available/vehicle-manager /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl restart nginx
   ```

5. **Update Security Group:**
   - Remove port 3000 rule
   - Ensure port 80 is open

6. **Update Flutter app config:**
   ```dart
   static const String baseUrl = 'http://YOUR_EC2_IP/api';
   ```

7. **Test:**
   ```bash
   curl http://YOUR_EC2_IP/api/health
   ```

## Common Error Messages

### "Connection refused"
- Container not running
- Wrong port
- API not started

### "Connection timed out"
- Security Group blocking
- Firewall blocking
- Wrong IP address

### "502 Bad Gateway" (if using Nginx)
- API container not running
- API not accessible on localhost:3000

## Still Not Working?

1. **Verify EC2 instance is running:**
   - Check AWS Console
   - Instance state should be "running"

2. **Check instance has public IP:**
   - Some VPC configurations need Elastic IP

3. **Try telnet to test connection:**
   ```bash
   telnet YOUR_EC2_IP 3000
   ```
   - If connection opens: Port is reachable, issue is with API
   - If timeout: Security Group or firewall issue

4. **Review all logs:**
   ```bash
   sudo docker-compose logs
   ```

5. **Restart everything:**
   ```bash
   sudo docker-compose down
   sudo docker-compose up -d
   ```

