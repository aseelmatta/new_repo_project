# parallel_algo_project
 
# Courier Management System

A mobile application that connects businesses needing delivery services with available couriers, featuring real-time location tracking, delivery status updates, and efficient matching algorithms.

## Project Overview

The Courier Management System facilitates the entire delivery process:
- Businesses can create delivery requests with specific pickup and drop-off locations
- Couriers can accept deliveries, update their status, and navigate to destinations
- Admins can monitor all system activity, users, and deliveries

## Repository Structure

```
courier-management-system/
├── backend/           # Python API server
│   ├── app.py         # Main application file
│   ├── requirements.txt  # Python dependencies
│   └── ...            # Service modules, routes, etc.
├── frontend/          # Flutter mobile application
│   ├── android/       # Android-specific files
│   ├── ios/           # iOS-specific files
│   ├── lib/           # Dart source code
│   ├── pubspec.yaml   # Flutter dependencies
│   └── ...
└── venv/              # Python virtual environment (not committed)
```

## Technology Stack

- **Mobile Frontend**: Flutter/Dart (cross-platform for Android and iOS)
- **Backend API**: Python with Flask/FastAPI
- **Database**: Firebase Firestore
- **Authentication**: Firebase Authentication
- **Location Services**: Google Maps API
- **Notifications**: Firebase Cloud Messaging
- **Admin Interface**: Integrated in Python backend with web templates

## Features

### Core Features
- User authentication (business users, couriers, admins)
- Profile management
- Delivery request creation and tracking
- Real-time GPS location tracking
- Courier availability management
- Delivery status updates
- Push notifications

### Secondary Features
- Delivery history
- Rating system
- Basic analytics dashboard
- Search and filtering
- In-app chat

## Setup Instructions

### Prerequisites
- Flutter SDK (latest stable version)
- Python 3.8+
- Firebase account
- Google Maps API key

### Backend Setup
1. Create a virtual environment:
   ```
   cd backend
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. Install dependencies:
   ```
   pip install -r requirements.txt
   ```

3. Configure Firebase:
   - Create a Firebase project
   - Download service account key and save as `firebase-credentials.json`
   - Update configuration in backend settings

4. Run the backend server:
   ```
   python app.py
   ```

### Frontend Setup
1. Install Flutter dependencies:
   ```
   cd frontend
   flutter pub get
   ```

2. Configure Firebase:
   - Add Firebase configuration files:
     - Android: `google-services.json` to `android/app/`
     - iOS: `GoogleService-Info.plist` to `ios/Runner/`

3. Configure Google Maps:
   - Add API keys to appropriate platform files

4. Run the app:
   ```
   flutter run
   ```

## Development Timeline

- Phase 1 (Weeks 1-3): Setup & Core Architecture
- Phase 2 (Weeks 4-7): Core Functionality
- Phase 3 (Weeks 8-10): Advanced Features
- Phase 4 (Weeks 11-13): Refinement & Testing

## Contributors

- Aseel Matta
- Mayan Sussan
- Zina Assi


