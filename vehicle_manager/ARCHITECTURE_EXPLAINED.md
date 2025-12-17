# Architecture & Deployment Explained

## 📦 How Data is Saved

### Old System (Before Migration)

**Storage Method**: SharedPreferences (Flutter's local storage)

```
┌─────────────────────────────────────┐
│         Flutter App (Device)        │
│                                     │
│  ┌──────────────────────────────┐  │
│  │   SharedPreferences          │  │
│  │   (Local Device Storage)     │  │
│  │                              │  │
│  │  - users: JSON string        │  │
│  │  - vehicles: JSON string     │  │
│  └──────────────────────────────┘  │
│                                     │
│  Storage Location:                  │
│  - Web: Browser localStorage        │
│  - Mobile: App's private storage    │
└─────────────────────────────────────┘
```

**Limitations**:
- Data stored locally on each device
- No synchronization between devices
- Data lost if app is uninstalled
- No backend server

### New System (Current)

**Storage Method**: PostgreSQL Database on Backend Server

```
┌─────────────────────────────────────┐
│         Flutter App (Client)        │
│                                     │
│  HTTP Requests (REST API)           │
│         ↓                           │
│  ┌──────────────────────────────┐  │
│  │     API Service              │  │
│  │  - GET /api/vehicles         │  │
│  │  - POST /api/vehicles        │  │
│  │  - PUT /api/vehicles/:id     │  │
│  │  - DELETE /api/vehicles/:id  │  │
│  └──────────────────────────────┘  │
│         ↓                           │
└─────────┼───────────────────────────┘
          │
          │ HTTPS/HTTP
          │
          ↓
┌─────────────────────────────────────┐
│    Node.js/Express Backend Server   │
│                                     │
│  ┌──────────────────────────────┐  │
│  │   Authentication             │  │
│  │   - JWT Token Validation     │  │
│  │   - Bcrypt Password Hash     │  │
│  └──────────────────────────────┘  │
│         ↓                           │
│  ┌──────────────────────────────┐  │
│  │   Business Logic             │  │
│  │   - CRUD Operations          │  │
│  │   - Data Validation          │  │
│  └──────────────────────────────┘  │
│         ↓                           │
└─────────┼───────────────────────────┘
          │
          │ SQL Queries
          │
          ↓
┌─────────────────────────────────────┐
│      PostgreSQL Database            │
│                                     │
│  ┌──────────────────────────────┐  │
│  │   users Table                │  │
│  │   - id, email, password      │  │
│  └──────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │   vehicles Table             │  │
│  │   - id, user_email, make,    │  │
│  │     model, year, color,      │  │
│  │     license_plate            │  │
│  └──────────────────────────────┘  │
│                                     │
│  Storage: EC2 Server Disk           │
└─────────────────────────────────────┘
```

**Advantages**:
- ✅ Centralized data storage
- ✅ Data synchronized across all devices
- ✅ Secure password hashing (bcrypt)
- ✅ Scalable architecture
- ✅ Data persistence (survives app reinstall)

## 🐳 Docker Container Architecture

### What Docker Containers Contain

Our setup uses **2 Docker containers**:

```
┌─────────────────────────────────────────────────────────┐
│                   Docker Host (EC2)                     │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │         Container 1: PostgreSQL Database          │ │
│  │                                                    │ │
│  │  Image: postgres:15-alpine                        │ │
│  │  Port: 5432 (internal)                            │ │
│  │                                                    │ │
│  │  Contains:                                        │ │
│  │  - PostgreSQL database server                     │ │
│  │  - Database: vehicle_manager                      │ │
│  │  - Tables: users, vehicles                        │ │
│  │  - Data files stored in Docker volume             │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │         Container 2: Node.js API Server           │ │
│  │                                                    │ │
│  │  Image: Custom (built from Dockerfile)            │ │
│  │  Port: 3000 (exposed to host)                     │ │
│  │                                                    │ │
│  │  Contains:                                        │ │
│  │  - Node.js runtime                                │ │
│  │  - Express.js framework                           │ │
│  │  - Application code (server.js)                   │ │
│  │  - Dependencies (node_modules)                    │ │
│  │  - Connects to PostgreSQL container               │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  Docker Network: Containers can communicate internally │
└─────────────────────────────────────────────────────────┘
```

### Docker Compose Configuration

The `docker-compose.yml` file orchestrates both containers:

```yaml
services:
  postgres:              # Database container
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: vehicle_manager
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data  # Persistent storage

  api:                   # Backend API container
    build: ./backend
    environment:
      DB_HOST: postgres  # Connects to postgres container
      DB_PORT: 5432
    depends_on:
      postgres:          # Waits for database to be ready
```

### Data Flow

1. **User Action** (e.g., "Add Vehicle") in Flutter app
2. **HTTP Request** → `POST http://ec2-ip:3000/api/vehicles`
3. **API Container** receives request
4. **API Container** connects to **PostgreSQL Container**
5. **SQL INSERT** query executes
6. **Data saved** in PostgreSQL database
7. **Response** sent back to Flutter app

### Container Benefits

- **Isolation**: Each service runs in its own environment
- **Portability**: Works the same on any machine with Docker
- **Scalability**: Easy to scale containers independently
- **Easy Deployment**: One command (`docker-compose up`) starts everything
- **Data Persistence**: Docker volumes preserve data

## 🚀 Step-by-Step EC2 Deployment

### Prerequisites Checklist

- [ ] AWS Account
- [ ] EC2 instance running (Ubuntu 22.04 LTS recommended)
- [ ] SSH access to EC2 instance
- [ ] Security group configured (ports 22, 80, 443, 3000)

### Step 1: Launch EC2 Instance

1. **Go to AWS Console** → EC2 → Launch Instance
2. **Choose AMI**: Ubuntu 22.04 LTS (free tier eligible)
3. **Instance Type**: t2.micro (free tier) or t3.small
4. **Key Pair**: Create or select existing SSH key pair
5. **Security Group**: Configure rules:
   ```
   Type        Protocol    Port Range    Source
   SSH         TCP         22            My IP
   HTTP        TCP         80            0.0.0.0/0
   HTTPS       TCP         443           0.0.0.0/0
   Custom TCP  TCP         3000          0.0.0.0/0  (or your IP only)
   ```
6. **Launch Instance**
7. **Note your EC2 Public IP** (e.g., `54.123.45.67`)

### Step 2: Connect to EC2

**On Mac/Linux:**
```bash
chmod 400 your-key.pem
ssh -i your-key.pem ubuntu@YOUR_EC2_IP
```

**On Windows (using Git Bash or WSL):**
```bash
chmod 400 your-key.pem
ssh -i your-key.pem ubuntu@YOUR_EC2_IP
```

### Step 3: Install Docker on EC2

Once connected to EC2, run:

```bash
# Update system packages
sudo apt update

# Install Docker
sudo apt install -y docker.io docker-compose

# Verify installation
docker --version
docker-compose --version

# (Optional) Add user to docker group to avoid sudo
sudo usermod -aG docker ubuntu
# Logout and login again for this to take effect
```

### Step 4: Upload Your Code to EC2

**Option A: Using Git (Recommended)**

```bash
# On EC2
cd ~
git clone YOUR_REPOSITORY_URL
cd vehicle_manager
```

**Option B: Using SCP (from your local machine)**

```bash
# From your local machine
scp -i your-key.pem -r vehicle_manager ubuntu@YOUR_EC2_IP:~/
```

**Option C: Using ZIP**

```bash
# On local machine - create zip
cd vehicle_manager
zip -r vehicle_manager.zip . -x "*.git*" "node_modules/*" ".dart_tool/*" "build/*"

# Upload to EC2
scp -i your-key.pem vehicle_manager.zip ubuntu@YOUR_EC2_IP:~/

# On EC2 - extract
cd ~
unzip vehicle_manager.zip -d vehicle_manager
cd vehicle_manager
```

### Step 5: Configure Environment Variables

```bash
# On EC2
cd ~/vehicle_manager/backend
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
DB_PASSWORD=CHANGE_TO_SECURE_PASSWORD
JWT_SECRET=CHANGE_TO_RANDOM_SECRET_STRING
```

**Generate secure passwords:**
```bash
# Generate random password
openssl rand -base64 32

# Generate JWT secret
openssl rand -base64 32
```

### Step 6: Update Docker Compose (if needed)

Edit `docker-compose.yml` to match your `.env` password:

```bash
cd ~/vehicle_manager
nano docker-compose.yml
```

Make sure `POSTGRES_PASSWORD` matches your `.env` file.

### Step 7: Build and Start Containers

```bash
cd ~/vehicle_manager

# Build and start containers in detached mode
sudo docker-compose up -d --build

# Check logs
sudo docker-compose logs -f

# Check running containers
sudo docker-compose ps
```

You should see:
```
NAME                   STATUS          PORTS
vehicle_manager_api    Up 5 minutes    0.0.0.0:3000->3000/tcp
vehicle_manager_db     Up 5 minutes    0.0.0.0:5432->5432/tcp
```

### Step 8: Verify Deployment

```bash
# Test API health endpoint (from within EC2)
curl http://localhost:3000/health

# Should return: {"status":"ok"}
```

### Step 8b: Fix Connection Issues (IMPORTANT!)

If you get timeout when accessing from your local machine, check:

**1. Security Group Rules (MOST COMMON ISSUE):**
   - Go to AWS Console → EC2 → Security Groups
   - Select your instance's security group
   - Edit inbound rules
   - Add: Custom TCP, Port 3000, Source: My IP (or 0.0.0.0/0 for testing)

**2. EC2 Firewall:**
   ```bash
   sudo ufw allow 3000/tcp
   ```

**3. Verify containers are running:**
   ```bash
   sudo docker-compose ps
   ```

**4. Test from your local machine:**
   ```bash
   curl http://YOUR_EC2_IP:3000/health
   ```

**See TROUBLESHOOTING.md for detailed troubleshooting steps.**

### Step 9: Update Flutter App Configuration

On your **local machine**, update the API URL:

**Edit `lib/services/config.dart`:**

```dart
class ApiConfig {
  // Replace with your EC2 IP address
  static const String baseUrl = 'http://YOUR_EC2_IP:3000/api';
  
  // Or if you set up a domain:
  // static const String baseUrl = 'https://yourdomain.com/api';
  
  static String getBaseUrl() {
    return baseUrl;
  }
}
```

**Rebuild Flutter app:**
```bash
flutter pub get
flutter build web  # For web
# or
flutter run -d chrome  # For testing
```

### Step 10: Deploy Flutter Web App (Make Accessible from Any Device)

To make your app accessible from other devices using the EC2 public IP:

**See `DEPLOY_WEB_APP.md` for complete instructions.**

Quick steps:
1. Build Flutter web: `flutter build web --release`
2. Install Nginx on EC2: `sudo apt install nginx`
3. Copy build files to `/var/www/vehicle_manager/`
4. Configure Nginx to serve app and proxy API requests
5. Access from any device: `http://YOUR_EC2_IP`

### Step 11: Test the Application

1. **Access web app:**
   - From any device: Open browser → `http://YOUR_EC2_IP`
   - Or test locally on EC2: `http://localhost`

2. **Sign up with a new account**

3. **Add a vehicle**

4. **Verify data is saved in database:**

```bash
# On EC2, connect to database
sudo docker-compose exec postgres psql -U postgres -d vehicle_manager

# Run SQL queries
SELECT * FROM users;
SELECT * FROM vehicles;

# Exit
\q
```

5. **Share with others:**
   - Share the URL: `http://YOUR_EC2_IP`
   - Anyone can access it from any device!

## 🔧 Useful Management Commands

### View Logs
```bash
# All services
sudo docker-compose logs -f

# Specific service
sudo docker-compose logs -f api
sudo docker-compose logs -f postgres
```

### Restart Services
```bash
# Restart all
sudo docker-compose restart

# Restart specific service
sudo docker-compose restart api
```

### Stop/Start Services
```bash
# Stop
sudo docker-compose stop

# Start
sudo docker-compose start

# Stop and remove containers (keeps data)
sudo docker-compose down

# Stop and remove everything including volumes (DELETES DATA!)
sudo docker-compose down -v
```

### Update Code
```bash
# Pull latest code
git pull

# Rebuild and restart
sudo docker-compose up -d --build
```

### Backup Database
```bash
# Create backup
sudo docker-compose exec postgres pg_dump -U postgres vehicle_manager > backup_$(date +%Y%m%d).sql

# Restore backup
sudo docker-compose exec -T postgres psql -U postgres vehicle_manager < backup_20231201.sql
```

## 🔒 Security Best Practices

1. **Change Default Passwords**: Never use default passwords in production
2. **Use Strong JWT Secret**: Generate random 32+ character string
3. **Restrict Security Group**: Only allow port 3000 from specific IPs if possible
4. **Use HTTPS**: Set up SSL certificate (see DEPLOYMENT.md)
5. **Regular Backups**: Automate database backups
6. **Keep Updated**: Regularly update Docker images and packages

## 📊 Architecture Summary

```
┌─────────────────────────────────────────────────────────┐
│                    User's Device                        │
│  Flutter Web/Mobile App                                 │
│  - Makes HTTP requests                                  │
│  - Stores JWT token locally                            │
└──────────────────────┬──────────────────────────────────┘
                       │
                       │ HTTP/HTTPS
                       │
                       ↓
┌─────────────────────────────────────────────────────────┐
│                  AWS EC2 Instance                       │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Docker Container: API Server (Port 3000)        │  │
│  │  - Node.js/Express                               │  │
│  │  - Handles HTTP requests                         │  │
│  │  - Validates JWT tokens                          │  │
│  │  - Executes business logic                       │  │
│  └──────────────────┬───────────────────────────────┘  │
│                     │                                    │
│                     │ SQL Queries                        │
│                     │                                    │
│  ┌──────────────────▼───────────────────────────────┐  │
│  │  Docker Container: PostgreSQL (Port 5432)        │  │
│  │  - Database: vehicle_manager                     │  │
│  │  - Tables: users, vehicles                       │  │
│  │  - Data persisted in Docker volume               │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  Docker Volume: postgres_data                           │
│  (Persistent storage on EC2 disk)                       │
└─────────────────────────────────────────────────────────┘
```

## ✅ Deployment Checklist

- [ ] EC2 instance launched and accessible
- [ ] Docker installed on EC2
- [ ] Code uploaded to EC2
- [ ] Environment variables configured (`.env` file)
- [ ] Containers built and running (`docker-compose ps`)
- [ ] API health check passing (`/health` endpoint)
- [ ] Flutter app configured with EC2 IP
- [ ] Can sign up and login
- [ ] Can create/view vehicles
- [ ] Data persists in database

## 🆘 Troubleshooting

**Can't connect to API:**
- Check security group allows port 3000
- Check containers are running: `sudo docker-compose ps`
- Check logs: `sudo docker-compose logs api`

**Database connection errors:**
- Verify `.env` file has correct DB credentials
- Check postgres container is healthy: `sudo docker-compose ps`
- Check database logs: `sudo docker-compose logs postgres`

**CORS errors in browser:**
- Backend has CORS enabled
- Verify API URL is correct in Flutter app
- Check browser console for actual error

**Containers won't start:**
- Check logs: `sudo docker-compose logs`
- Verify `.env` file exists and is configured
- Check disk space: `df -h`

