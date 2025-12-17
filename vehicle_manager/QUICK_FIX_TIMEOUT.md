# Quick Fix: Connection Timeout to EC2 API

## ⚡ Fastest Solution (Most Common Issue)

The timeout is almost always caused by **Security Group blocking port 3000**.

### Quick Fix (2 minutes):

1. **Go to AWS Console:**
   - EC2 → Instances
   - Click your instance
   - Click "Security" tab
   - Click the Security Group link

2. **Edit Inbound Rules:**
   - Click "Edit inbound rules"
   - Click "Add rule"
   - Type: **Custom TCP**
   - Port: **3000**
   - Source: **My IP** (automatically fills your IP) OR **0.0.0.0/0** (allows all IPs - use only for testing!)
   - Click "Save rules"

3. **Test again:**
   ```bash
   curl http://YOUR_EC2_IP:3000/health
   ```

## ✅ Verify Everything is Running

SSH into EC2 and run:

```bash
# Check containers
sudo docker-compose ps

# Should show both containers as "Up"

# Test locally on EC2
curl http://localhost:3000/health

# Should return: {"status":"ok"}
```

## ✅ If Security Group is Correct, Check Firewall

On EC2:
```bash
# Check firewall status
sudo ufw status

# If active, allow port 3000
sudo ufw allow 3000/tcp
```

## ✅ Verify API Server Configuration

The server.js was updated to bind to `0.0.0.0` (all interfaces), which is correct.

To verify:
```bash
# On EC2
sudo docker-compose logs api | grep "Server running"
```

Should show: `Server running on port 3000`

## Still Not Working?

Run this diagnostic script on EC2:

```bash
echo "=== Container Status ==="
sudo docker-compose ps

echo ""
echo "=== Port 3000 Status ==="
sudo netstat -tlnp | grep 3000

echo ""
echo "=== Firewall Status ==="
sudo ufw status

echo ""
echo "=== Local API Test ==="
curl http://localhost:3000/health

echo ""
echo "=== API Logs (last 10 lines) ==="
sudo docker-compose logs api --tail 10
```

Share the output if you need more help!

