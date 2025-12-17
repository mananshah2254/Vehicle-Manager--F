# Database Migration Guide

## Current Storage (Before Migration)

The app currently uses **SharedPreferences** which stores data locally on the device:
- User credentials stored in device local storage
- Vehicle data stored in device local storage
- No backend server needed
- Data is per-device (not synced)

## New Storage (After Migration)

The app now uses **PostgreSQL database** on a backend server:
- User credentials stored securely in database (passwords hashed with bcrypt)
- Vehicle data stored in database
- Data is centralized and synced across devices
- Requires backend API server

## Migration Steps

### For Development:

1. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

2. **Start backend locally:**
   ```bash
   cd backend
   npm install
   cp env.example .env
   # Edit .env with your database settings
   npm run dev
   ```

3. **Start database:**
   ```bash
   docker run --name vehicle_db -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=vehicle_manager -p 5432:5432 -d postgres:15-alpine
   ```

4. **Update API URL in Flutter app:**
   Edit `lib/services/config.dart`:
   ```dart
   static const String baseUrl = 'http://localhost:3000/api';
   ```

5. **Run Flutter app:**
   ```bash
   flutter run -d chrome
   ```

### For Production (EC2):

See `DEPLOYMENT.md` for complete deployment guide.

## Data Location

### Old System (SharedPreferences):
- **Location**: Device local storage (browser localStorage for web, SharedPreferences for mobile)
- **Path**: Platform-specific storage location
- **Format**: JSON strings stored as key-value pairs

### New System (PostgreSQL):
- **Location**: PostgreSQL database on backend server
- **Host**: Configured in `backend/.env` (DB_HOST)
- **Database**: `vehicle_manager`
- **Tables**: `users` and `vehicles`

## Important Notes

1. **Data Migration**: Existing local data will NOT be automatically migrated. Users will need to sign up again.

2. **API Configuration**: Make sure to update `lib/services/config.dart` with the correct backend URL:
   - Development: `http://localhost:3000/api`
   - Production: `http://YOUR_EC2_IP:3000/api` or `https://yourdomain.com/api`

3. **Authentication**: The app now uses JWT tokens for authentication. Tokens are stored locally in SharedPreferences (for session management), but all data is stored on the server.

4. **Backward Compatibility**: The old `storage_service.dart` file is kept but not used. You can remove it if you want, but it's safe to leave it.

## Testing the Setup

1. **Test API health:**
   ```bash
   curl http://localhost:3000/health
   ```

2. **Test signup:**
   ```bash
   curl -X POST http://localhost:3000/api/auth/signup \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"test123"}'
   ```

3. **Test login:**
   ```bash
   curl -X POST http://localhost:3000/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"test123"}'
   ```

## Troubleshooting

- **Connection refused**: Make sure backend server is running
- **Database connection error**: Check database is running and `.env` has correct credentials
- **CORS errors**: Backend has CORS enabled, but check if your API URL is correct
- **401 Unauthorized**: Check if JWT token is being sent in Authorization header

