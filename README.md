# HostelFix 🏠

A modern mobile application for hostellers, designed to streamline complaints, reporting, and management. Built with Flutter and Firebase.

## 🚀 Getting Started

Follow these steps to get the project up and running on your local machine.

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.10.8 or higher)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio / Xcode (for mobile emulation)
- A Firebase project

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/HostelFix.git
   cd HostelFix
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - For **Android**: Place your `google-services.json` in `android/app/`.
   - For **iOS**: Place your `GoogleService-Info.plist` in `ios/Runner/`.
   - Ensure the Firebase project is configured with Authentication and Firestore.

4. **Run the App**
   ```bash
   flutter run
   ```

## 🔐 Environment Variables

Create a `.env` file in the root directory and add the following keys. Note: You may need to integrate a package like `flutter_dotenv` if not already present.

```env
# Firebase Configuration (if applicable via env)
FIREBASE_API_KEY=your_api_key_here
FIREBASE_PROJECT_ID=your_project_id_here

# API Endpoints
BASE_URL=https://api.example.com/v1

# Other Configuration
DEBUG_MODE=true
```

## ✨ Features

### 👤 Role-Based Dashboards
- **Students**: Report hostel issues, track complaint status, and manage profile information.
- **Wardens**: Oversight of hostel-specific complaints, student approval, and contractor assignment.
- **Contractors**: View assigned maintenance tasks and update status (Assigned, In Progress, Completed).
- **Admins**: Full system visibility and cross-hostel complaint management.

### 📝 Complaint Management
- **Detailed Reporting**: Categorize issues (Electricity, Water, Cleaning, etc.) with title, description, and room number.
- **Priority System**: Mark complaints as **Emergency (High Priority)** for immediate attention.
- **Status Tracking**: Live updates from "Pending" to "Completed".
- **Filtering**: View complaints by status or priority to focus on what matters most.

### 🔔 Smart Notifications
- **Emergency Alerts**: High-priority complaints trigger immediate local notifications.
- **Real-time Updates**: (Powered by Firestore) Ensures dashboards stay in sync without manual refreshes.

### 🛡️ Secure Authentication
- **Multi-Method Login**: Support for Email, Student ID, or Phone-based authentication.
- **Warden Approval**: New student accounts require verification from the respective warden before full access.

## 📸 Screenshots

*Screenshots coming soon...*

---
Made with ❤️ for hostellers.
