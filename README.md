# Vehicle Manager (Flutter + Node API + PostgreSQL)

Vehicle Manager is a Flutter app with a Node.js/Express backend and a PostgreSQL database.  
The backend provides CRUD APIs + auth, and the Flutter app consumes those APIs.

---

## Tech Stack
- Frontend: Flutter (mobile + web)
- Backend: Node.js + Express
- Database: PostgreSQL
- Infra: Docker + Docker Compose, Nginx (optional for web hosting)

---

## Prerequisites
Install:
- Flutter SDK 
- Docker + Docker Compose
- Gi
---


## Local Setup (Run Everything)

### 1) Clone and enter project
git clone https://github.com/mananshah2254/Vehicle-Manager--F.git
cd Vehicle-Manager--F/vehicle_manager

### 2) Start Backend + DB (Docker Compose)
docker compose up -d --build

### 3) Verify backend is up
curl -i http://localhost:3000/health

### 4) Install Flutter dependencies
flutter pub get

### 5) If web is not enabled, enable it
flutter create . --platforms web

### 6) Configure API base URL (IMPORTANT)
Open this file and set baseUrl depending on where backend runs:
lib/services/config.dart
#
For local dev:
  http://localhost:3000/api
#
For EC2:
  http://<EC2_PUBLIC_IP>:3000/api

### 7) Run Flutter (Web)
flutter run -d chrome


---

## Deploy Flutter Web on EC2 with Nginx (Optional)
This hosts the Flutter web build at:
http://<EC2_PUBLIC_IP>/

### 1) Build Flutter web
cd ~/Vehicle-Manager--F/vehicle_manager
flutter clean
flutter pub get
flutter create . --platforms web
flutter build web --release

### 2) Install Nginx
sudo apt update
sudo apt install -y nginx

### 3) Copy build output to Nginx web root
sudo mkdir -p /var/www/vehicle_manager
sudo rm -rf /var/www/vehicle_manager/*
sudo cp -r build/web/* /var/www/vehicle_manager/

### 4) Create Nginx site config
sudo tee /etc/nginx/sites-available/vehicle-manager > /dev/null <<'EOF'
server {
  listen 80;
  server_name _;

  root /var/www/vehicle_manager;
  index index.html;

  location / {
    try_files $uri $uri/ /index.html;
  }
}
EOF

### 5) Enable site + reload Nginx
sudo ln -sf /etc/nginx/sites-available/vehicle-manager /etc/nginx/sites-enabled/vehicle-manager
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx

