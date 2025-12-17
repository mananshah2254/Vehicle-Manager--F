# Vehicle Manager Backend API

Node.js/Express backend API for Vehicle Manager application.

## Features

- RESTful API with Express.js
- PostgreSQL database
- JWT authentication
- Bcrypt password hashing
- CORS enabled
- Docker support

## Setup

### Local Development

1. Install dependencies:
```bash
npm install
```

2. Create `.env` file from `env.example`:
```bash
cp env.example .env
```

3. Update `.env` with your database credentials

4. Start PostgreSQL database (using Docker):
```bash
docker run --name vehicle_db -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=vehicle_manager -p 5432:5432 -d postgres:15-alpine
```

5. Run the server:
```bash
npm run dev
```

The server will start on `http://localhost:3000`

### Using Docker Compose

From the project root:

```bash
docker-compose up -d
```

This will start both PostgreSQL and the API server.

## API Endpoints

### Authentication

- `POST /api/auth/signup` - Register new user
  - Body: `{ "email": "user@example.com", "password": "password123" }`
  
- `POST /api/auth/login` - Login user
  - Body: `{ "email": "user@example.com", "password": "password123" }`
  - Returns: `{ "token": "jwt_token" }`

### Vehicles (Requires Authentication)

All vehicle endpoints require `Authorization: Bearer <token>` header.

- `GET /api/vehicles` - Get all vehicles for logged-in user
- `POST /api/vehicles` - Create new vehicle
  - Body: `{ "id": "unique_id", "make": "Toyota", "model": "Camry", "year": 2023, "color": "Red", "licensePlate": "ABC123" }`
- `PUT /api/vehicles/:id` - Update vehicle
  - Body: `{ "make": "Toyota", "model": "Camry", "year": 2023, "color": "Blue", "licensePlate": "ABC123" }`
- `DELETE /api/vehicles/:id` - Delete vehicle

### Health Check

- `GET /health` - Server health check

## Environment Variables

- `PORT` - Server port (default: 3000)
- `DB_HOST` - Database host
- `DB_PORT` - Database port (default: 5432)
- `DB_NAME` - Database name
- `DB_USER` - Database user
- `DB_PASSWORD` - Database password
- `JWT_SECRET` - Secret key for JWT tokens

## Database Schema

### users
- id (SERIAL PRIMARY KEY)
- email (VARCHAR UNIQUE)
- password (VARCHAR - hashed)
- created_at (TIMESTAMP)

### vehicles
- id (VARCHAR PRIMARY KEY)
- user_email (VARCHAR - foreign key to users.email)
- make (VARCHAR)
- model (VARCHAR)
- year (INTEGER)
- color (VARCHAR)
- license_plate (VARCHAR)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)

