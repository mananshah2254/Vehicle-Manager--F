# Quick Start Guide

## Where Data is Stored

### Before (Old System)
- **Location**: Device local storage (SharedPreferences)
- **Storage**: JSON strings in browser localStorage / mobile SharedPreferences
- **Scope**: Per-device only

### After (New System)
- **Location**: PostgreSQL database on backend server
- **Storage**: Structured database tables (`users` and `vehicles`)
- **Scope**: Centralized, synced across all devices

## Quick Setup for Local Development

### 1. Setup Backend

```bash
cd backend
npm install
cp env.example .env
# Edit .env if needed (defaults work for local dev)
```

### 2. Start Database & API

**Option A: Using Docker Compose (Recommended)**
```bash
# From project root
docker-compose up -d
```

**Option B: Manual**
```bash
# Start PostgreSQL
docker run --name vehicle_db -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=vehicle_manager -p 5432:5432 -d postgres:15-alpine

# Start API (in backend directory)
npm run dev
```

### 3. Setup Flutter App

```bash
# Install dependencies
flutter pub get

# Update API URL (optional, defaults to localhost)
# Edit lib/services/config.dart if needed

# Run app
flutter run -d chrome
```

### 4. Verify Setup

1. Open app in browser
2. Sign up with a new account
3. Add a vehicle
4. Check database:
   ```bash
   docker exec -it vehicle_manager_db psql -U postgres -d vehicle_manager
   SELECT * FROM vehicles;
   ```

## Deploying to EC2

See `DEPLOYMENT.md` for complete EC2 deployment instructions.

Quick summary:
1. Launch EC2 instance
2. Install Docker
3. Clone repository
4. Configure `.env` file
5. Run `docker-compose up -d`
6. Update Flutter app API URL
7. Deploy!

## Key Files

- **Backend API**: `backend/server.js`
- **Database Config**: `backend/.env`
- **Docker Setup**: `docker-compose.yml`
- **API Config**: `lib/services/config.dart`
- **API Service**: `lib/services/api_service.dart`

## Testing API

```bash
# Health check
curl http://localhost:3000/health

# Signup
curl -X POST http://localhost:3000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123"}'

# Login (use token from signup response)
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123"}'
```

