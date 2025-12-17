# Deployment Guide - Vehicle Manager on EC2

This guide will help you deploy the Vehicle Manager application on an EC2 server using Docker.

## Architecture

- **Frontend**: Flutter web app
- **Backend**: Node.js/Express API
- **Database**: PostgreSQL
- **Containerization**: Docker & Docker Compose

## Prerequisites

1. AWS EC2 instance (Ubuntu 22.04 LTS recommended)
2. SSH access to EC2 instance
3. Docker and Docker Compose installed on EC2

## Step 1: Setup EC2 Instance

### Launch EC2 Instance

1. Go to AWS Console → EC2 → Launch Instance
2. Choose Ubuntu 22.04 LTS
3. Select instance type (t2.micro or t3.small)
4. Configure security group:
   - Allow SSH (port 22) from your IP
   - Allow HTTP (port 80)
   - Allow HTTPS (port 443)
   - Allow Custom TCP (port 3000) - for API
5. Launch and save your key pair

### Connect to EC2

```bash
ssh -i your-key.pem ubuntu@YOUR_EC2_IP
```

## Step 2: Install Docker on EC2

```bash
# Update system
sudo apt update

# Install Docker
sudo apt install -y docker.io docker-compose

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group (optional, to avoid sudo)
sudo usermod -aG docker ubuntu

# Logout and login again for group changes to take effect
```

## Step 3: Clone Repository on EC2

```bash
# Install git if not already installed
sudo apt install -y git

# Clone your repository
git clone YOUR_REPOSITORY_URL
cd vehicle_manager

# Or upload files via SCP
# From your local machine:
# scp -i your-key.pem -r vehicle_manager ubuntu@YOUR_EC2_IP:~/
```

## Step 4: Configure Environment Variables

```bash
cd backend
cp env.example .env
nano .env
```

Update the `.env` file:

```env
PORT=3000
DB_HOST=postgres
DB_PORT=5432
DB_NAME=vehicle_manager
DB_USER=postgres
DB_PASSWORD=CHANGE_THIS_TO_SECURE_PASSWORD
JWT_SECRET=CHANGE_THIS_TO_RANDOM_SECRET_STRING
```

**Important**: Change `DB_PASSWORD` and `JWT_SECRET` to secure random strings!

## Step 5: Update Docker Compose

Edit `docker-compose.yml` and ensure the database password matches your `.env` file.

## Step 6: Build and Run Containers

```bash
# From project root
cd ~/vehicle_manager

# Build and start containers
sudo docker-compose up -d

# Check logs
sudo docker-compose logs -f

# Check running containers
sudo docker-compose ps
```

## Step 7: Configure Flutter App

Update the API base URL in your Flutter app:

1. Edit `lib/services/config.dart`:

```dart
class ApiConfig {
  // Replace with your EC2 public IP or domain
  static const String baseUrl = 'http://YOUR_EC2_IP:3000/api';
  // Or if using domain:
  // static const String baseUrl = 'https://yourdomain.com/api';
  
  static String getBaseUrl() {
    return baseUrl;
  }
}
```

2. Rebuild your Flutter app:

```bash
flutter pub get
flutter build web  # For web deployment
# or
flutter build apk  # For Android
```

## Step 8: (Optional) Setup Nginx Reverse Proxy

For production, use Nginx as reverse proxy:

```bash
# Install Nginx
sudo apt install -y nginx

# Create Nginx config
sudo nano /etc/nginx/sites-available/vehicle-manager
```

Add configuration:

```nginx
server {
    listen 80;
    server_name YOUR_DOMAIN_OR_IP;

    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location / {
        root /var/www/vehicle_manager;
        try_files $uri $uri/ /index.html;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/vehicle-manager /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Copy Flutter web build to /var/www/vehicle_manager
sudo mkdir -p /var/www/vehicle_manager
sudo cp -r build/web/* /var/www/vehicle_manager/
sudo chown -R www-data:www-data /var/www/vehicle_manager
```

## Step 9: (Optional) Setup SSL with Let's Encrypt

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d yourdomain.com

# Auto-renewal is set up automatically
```

## Step 10: Update Security Group

If using Nginx reverse proxy:
- Remove port 3000 from security group (only expose 80/443)
- Keep port 22 for SSH

## Step 11: Verify Deployment

1. Test API health:
   ```bash
   curl http://YOUR_EC2_IP:3000/health
   ```

2. Test from browser:
   - API: `http://YOUR_EC2_IP:3000/health`
   - App: `http://YOUR_EC2_IP` (if using Nginx)

## Maintenance Commands

```bash
# View logs
sudo docker-compose logs -f

# Restart services
sudo docker-compose restart

# Stop services
sudo docker-compose stop

# Start services
sudo docker-compose start

# Rebuild after code changes
sudo docker-compose up -d --build

# Backup database
sudo docker-compose exec postgres pg_dump -U postgres vehicle_manager > backup.sql

# Restore database
sudo docker-compose exec -T postgres psql -U postgres vehicle_manager < backup.sql
```

## Troubleshooting

### Container won't start
```bash
# Check logs
sudo docker-compose logs api
sudo docker-compose logs postgres

# Check container status
sudo docker ps -a
```

### Database connection issues
- Verify `.env` file has correct database credentials
- Check if postgres container is healthy: `sudo docker-compose ps`
- Test connection: `sudo docker-compose exec postgres psql -U postgres -d vehicle_manager`

### API not accessible
- Check security group allows port 3000 (or 80/443 if using Nginx)
- Verify containers are running: `sudo docker-compose ps`
- Check firewall: `sudo ufw status`

### Flutter app can't connect to API
- Update `lib/services/config.dart` with correct EC2 IP
- Verify API is accessible: `curl http://YOUR_EC2_IP:3000/health`
- Check CORS settings in backend (should allow your domain)

## Database Migrations

The database tables are automatically created on first run. To reset:

```bash
# Stop containers
sudo docker-compose down

# Remove volumes (WARNING: This deletes all data!)
sudo docker-compose down -v

# Start again
sudo docker-compose up -d
```

## Security Recommendations

1. **Change default passwords** in `.env` file
2. **Use strong JWT secret** (generate with: `openssl rand -base64 32`)
3. **Set up firewall** rules properly
4. **Use HTTPS** in production (Let's Encrypt)
5. **Regular backups** of database
6. **Keep Docker images updated**: `sudo docker-compose pull`
7. **Use environment-specific configs** (dev/staging/prod)
8. **Implement rate limiting** on API
9. **Use AWS Secrets Manager** for sensitive data (production)

## Backup Strategy

```bash
# Create backup script
cat > backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/ubuntu/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR
sudo docker-compose exec -T postgres pg_dump -U postgres vehicle_manager | gzip > $BACKUP_DIR/backup_$DATE.sql.gz
# Keep only last 7 days
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +7 -delete
EOF

chmod +x backup.sh

# Add to crontab (daily at 2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * /home/ubuntu/backups/backup.sh") | crontab -
```

## Cost Optimization

- Use EC2 t2.micro or t3.small for small applications
- Consider using AWS RDS for managed PostgreSQL (if scaling)
- Use CloudFront + S3 for Flutter web app static hosting
- Implement auto-scaling if needed

## Next Steps

- Set up monitoring (CloudWatch, Prometheus)
- Configure CI/CD pipeline
- Set up staging environment
- Implement API versioning
- Add API documentation (Swagger)

