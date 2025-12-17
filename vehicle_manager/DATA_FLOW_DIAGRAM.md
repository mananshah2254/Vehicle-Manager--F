# Data Flow Diagram

## Complete Data Journey: From User Action to Database Storage

### Example: User Adds a Vehicle

```
┌─────────────────────────────────────────────────────────────────┐
│  STEP 1: User Action in Flutter App                            │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  User fills form:                                        │ │
│  │  - Make: "Toyota"                                        │ │
│  │  - Model: "Camry"                                        │ │
│  │  - Year: 2023                                            │ │
│  │  - Color: "Red"                                          │ │
│  │  - License: "ABC123"                                     │ │
│  │  User clicks "Add Vehicle"                               │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 2: Flutter App Processing                                │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  vehicle_form_screen.dart                                 │ │
│  │    ↓                                                      │ │
│  │  VehicleService.addVehicle()                              │ │
│  │    ↓                                                      │ │
│  │  ApiService.addVehicle()                                  │ │
│  │    ↓                                                      │ │
│  │  HTTP POST request created                                │ │
│  │  URL: http://EC2_IP:3000/api/vehicles                    │ │
│  │  Headers: {                                               │ │
│  │    "Authorization": "Bearer JWT_TOKEN",                  │ │
│  │    "Content-Type": "application/json"                    │ │
│  │  }                                                        │ │
│  │  Body: {                                                  │ │
│  │    "id": "1699123456789",                                │ │
│  │    "make": "Toyota",                                     │ │
│  │    "model": "Camry",                                     │ │
│  │    "year": 2023,                                         │ │
│  │    "color": "Red",                                       │ │
│  │    "licensePlate": "ABC123"                              │ │
│  │  }                                                        │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                           ↓
                    HTTP Request
                    (over internet)
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 3: EC2 Server Receives Request                           │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  Network Interface receives HTTP request                  │ │
│  │  Port 3000 (configured in Security Group)                 │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 4: Docker Container - API Server                         │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  Container: vehicle_manager_api                           │ │
│  │  Image: Custom Node.js image                              │ │
│  │  Port: 3000                                               │ │
│  │                                                            │ │
│  │  Express.js receives POST /api/vehicles                   │ │
│  │    ↓                                                      │ │
│  │  authenticateToken middleware:                            │ │
│  │  - Extracts JWT token from header                         │ │
│  │  - Validates token signature                              │ │
│  │  - Extracts user email from token                         │ │
│  │    ↓                                                      │ │
│  │  Route handler: POST /api/vehicles                        │ │
│  │  - Validates request body                                 │ │
│  │  - Prepares SQL INSERT query                              │ │
│  │  - Connects to PostgreSQL container                       │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                           ↓
              Docker Internal Network
                    (postgres hostname)
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 5: Docker Container - PostgreSQL Database                │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  Container: vehicle_manager_db                            │ │
│  │  Image: postgres:15-alpine                                │ │
│  │  Port: 5432 (internal only)                               │ │
│  │                                                            │ │
│  │  Receives SQL Query:                                      │ │
│  │  INSERT INTO vehicles (                                   │ │
│  │    id, user_email, make, model,                           │ │
│  │    year, color, license_plate                             │ │
│  │  ) VALUES (                                               │ │
│  │    '1699123456789', 'user@example.com',                   │ │
│  │    'Toyota', 'Camry', 2023,                               │ │
│  │    'Red', 'ABC123'                                        │ │
│  │  )                                                        │ │
│  │    ↓                                                      │ │
│  │  Executes query on database: vehicle_manager              │ │
│  │    ↓                                                      │ │
│  │  Data written to disk (Docker volume)                     │ │
│  │  Location: /var/lib/postgresql/data                       │ │
│  │  Physical: EC2 instance disk                              │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 6: Database Storage (Physical Location)                  │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  Docker Volume: postgres_data                             │ │
│  │  Mounted at: /var/lib/postgresql/data                     │ │
│  │  Physical Location: EC2 Instance EBS Volume               │ │
│  │                                                            │ │
│  │  Data Structure:                                          │ │
│  │  ┌─────────────────────────────────────────┐             │ │
│  │  │  vehicles table                        │             │ │
│  │  │  ┌─────┬────────────┬───────┬──────┐  │             │ │
│  │  │  │ id  │ user_email │ make  │ ...  │  │             │ │
│  │  │  ├─────┼────────────┼───────┼──────┤  │             │ │
│  │  │  │169..│user@ex.com │Toyota │ ...  │  │ ← New row   │ │
│  │  │  └─────┴────────────┴───────┴──────┘  │             │ │
│  │  └─────────────────────────────────────────┘             │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                           ↓
                    SQL Response (Success)
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 7: API Server Response                                    │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  PostgreSQL returns: INSERT successful                     │ │
│  │    ↓                                                      │ │
│  │  Express.js sends HTTP response:                          │ │
│  │  Status: 201 Created                                      │ │
│  │  Body: { "message": "Vehicle created successfully" }      │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                           ↓
                    HTTP Response
                    (over internet)
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 8: Flutter App Updates UI                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  ApiService receives 201 response                         │ │
│  │    ↓                                                      │ │
│  │  VehicleService.addVehicle() completes                    │ │
│  │    ↓                                                      │ │
│  │  Navigator.pop() - closes form                            │ │
│  │    ↓                                                      │ │
│  │  Dashboard reloads vehicles from API                      │ │
│  │    ↓                                                      │ │
│  │  New vehicle appears in list                              │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Key Technologies Used

### 1. **Data Storage**: PostgreSQL
   - **Type**: Relational Database Management System (RDBMS)
   - **Storage Format**: Structured tables with rows and columns
   - **Location**: EC2 server disk (via Docker volume)
   - **Persistence**: Data survives container restarts

### 2. **API Server**: Node.js + Express
   - **Language**: JavaScript
   - **Framework**: Express.js
   - **Purpose**: Handles HTTP requests, validates data, executes database queries
   - **Authentication**: JWT tokens

### 3. **Containerization**: Docker
   - **Technology**: Docker containers
   - **Benefits**: 
     - Isolated environments
     - Easy deployment
     - Consistent across servers
     - Resource efficient

### 4. **Client**: Flutter
   - **Language**: Dart
   - **HTTP Client**: http package
   - **Storage**: SharedPreferences (only for JWT token, not data)

## Data Persistence Details

### Where Data is Actually Stored

```
EC2 Instance
│
├── Docker Volume: postgres_data
│   │
│   └── PostgreSQL Data Directory: /var/lib/postgresql/data
│       │
│       ├── base/              (Database files)
│       ├── global/            (Global data)
│       ├── pg_wal/            (Write-ahead logs)
│       └── ...                (Other PostgreSQL files)
│
└── Physical Storage: EBS Volume (Elastic Block Store)
    - Attached to EC2 instance
    - Persists even if container stops
    - Can be backed up via EBS snapshots
```

### Data Structure in Database

```sql
-- users table
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,  -- bcrypt hashed
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- vehicles table
CREATE TABLE vehicles (
  id VARCHAR(255) PRIMARY KEY,
  user_email VARCHAR(255) NOT NULL,
  make VARCHAR(255) NOT NULL,
  model VARCHAR(255) NOT NULL,
  year INTEGER NOT NULL,
  color VARCHAR(255) NOT NULL,
  license_plate VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_email) REFERENCES users(email) ON DELETE CASCADE
);
```

## Container Communication

```
┌─────────────────────────────────────────────────────────┐
│  Docker Network: vehicle_manager_default                │
│                                                         │
│  ┌──────────────────┐         ┌──────────────────┐    │
│  │  API Container   │         │  DB Container    │    │
│  │                  │         │                  │    │
│  │  Name: api       │────────▶│  Name: postgres  │    │
│  │  Port: 3000      │  SQL    │  Port: 5432      │    │
│  │                  │  Query  │                  │    │
│  │  Connects via:   │         │  Listens on:     │    │
│  │  postgres:5432   │         │  localhost:5432  │    │
│  └──────────────────┘         └──────────────────┘    │
│                                                         │
│  Docker Compose creates internal network automatically  │
│  Containers can reach each other by service name        │
└─────────────────────────────────────────────────────────┘
```

This is why in `docker-compose.yml`, the API connects to `DB_HOST=postgres` (the service name), not `localhost`!

