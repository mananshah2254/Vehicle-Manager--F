# Vehicle Manager

A simple Flutter application for managing vehicle information with authentication. The app supports both web and iOS platforms.

## Features

- **Authentication**: Simple signup and login functionality
- **Vehicle CRUD Operations**: Create, Read, Update, and Delete vehicle records
- **Local Storage**: Data is persisted locally using SharedPreferences
- **Cross-Platform**: Works on both web and iOS

## Vehicle Information

Each vehicle record contains:
- Make (e.g., Toyota)
- Model (e.g., Camry)
- Year
- Color
- License Plate

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- For iOS: Xcode (for iOS development)
- For Web: Chrome or any modern browser

### Installation

1. Navigate to the project directory:
   ```bash
   cd vehicle_manager
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

### Running the App

#### For Web:
```bash
flutter run -d chrome
```

#### For iOS Simulator:
```bash
flutter run -d ios
```

#### For iOS Device:
1. Connect your iPhone
2. Run: `flutter run -d ios`

## Usage

1. **Sign Up**: Create a new account with your email and password
2. **Login**: Use your credentials to log in
3. **Add Vehicle**: Tap the + button to add a new vehicle
4. **Edit Vehicle**: Tap the edit icon on any vehicle card
5. **Delete Vehicle**: Tap the delete icon on any vehicle card
6. **Logout**: Tap the logout icon in the app bar

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── vehicle.dart         # Vehicle data model
├── screens/
│   ├── login_screen.dart    # Login page
│   ├── signup_screen.dart   # Signup page
│   ├── dashboard_screen.dart # Main dashboard
│   └── vehicle_form_screen.dart # Add/Edit vehicle form
└── services/
    ├── auth_service.dart    # Authentication logic
    ├── vehicle_service.dart # Vehicle CRUD operations
    └── storage_service.dart # Local storage wrapper
```

## Notes

- All data is stored locally on the device
- User accounts and vehicle data persist between app sessions
- No backend server required - everything works offline

