# Fish Market Smart Weighing System - Setup Guide

## Prerequisites

- Flutter SDK (3.x or later)
- Firebase account
- Android Studio / VS Code
- Node.js (for Firebase CLI)
- ESP32 development environment (Arduino IDE)

## Part 1: Firebase Setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Enter project name: `fish-market-system`
4. Enable Google Analytics (optional)
5. Create project

### Step 2: Enable Authentication

1. In Firebase Console, go to **Authentication**
2. Click "Get Started"
3. Enable **Phone** authentication
4. Configure your phone authentication settings
5. Add test phone numbers if needed for development

### Step 3: Create Firestore Database

1. Go to **Firestore Database**
2. Click "Create Database"
3. Start in **Production Mode**
4. Choose your region
5. Click "Enable"

### Step 4: Set up Security Rules

Copy and paste these rules in Firestore Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    match /weighing_machines/{machineId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    
    match /fish_inventory/{inventoryId} {
      allow read: if request.auth != null;
      allow create, update, delete: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'merchant';
    }
    
    match /orders/{orderId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
        (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'merchant' ||
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'client');
    }
    
    match /notifications/{notificationId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    match /daily_sales_summary/{summaryId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### Step 5: Set up Firebase Storage

1. Go to **Storage**
2. Click "Get Started"
3. Start in **Production Mode**
4. Configure storage rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /fish_images/{merchantId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == merchantId;
    }
    
    match /invoices/{orderId}.pdf {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## Part 2: Configure Flutter Apps

### Step 1: Install FlutterFire CLI

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

### Step 2: Login to Firebase

```bash
firebase login
```

### Step 3: Configure Each App

#### For Merchant App:
```bash
cd merchant_app
flutterfire configure --project=fish-market-system
```

#### For Client App:
```bash
cd client_app
flutterfire configure --project=fish-market-system
```

#### For Admin App:
```bash
cd admin_app
flutterfire configure --project=fish-market-system
```

This will create `firebase_options.dart` file in each app's `lib` folder.

### Step 4: Update Android Configuration

For each app, update `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Changed from 16
        multiDexEnabled true
    }
}
```

### Step 5: Add Razorpay Configuration

1. Sign up at [Razorpay](https://razorpay.com/)
2. Get your API keys
3. Update in `client_app/lib/screens/home/order_detail_screen.dart`:

```dart
'key': 'YOUR_RAZORPAY_KEY',  // Replace with your key
```

## Part 3: Run the Apps

### Merchant App

```bash
cd merchant_app
flutter pub get
flutter run
```

### Client App

```bash
cd client_app
flutter pub get
flutter run
```

### Admin App

```bash
cd admin_app
flutter pub get
flutter run
```

## Part 4: ESP32 Firmware Setup

### Step 1: Install Arduino IDE

1. Download from [Arduino.cc](https://www.arduino.cc/en/software)
2. Install ESP32 board support:
   - Go to File → Preferences
   - Add URL: `https://dl.espressif.com/dl/package_esp32_index.json`
   - Go to Tools → Board → Boards Manager
   - Search "ESP32" and install

### Step 2: Install Libraries

In Arduino IDE:
1. Sketch → Include Library → Manage Libraries
2. Install:
   - HX711 by Bodge
   - ArduinoJson by Benoit Blanchon

### Step 3: Configure Firmware

Edit `esp32_firmware/fish_scale_firmware.ino`:

```cpp
const char* apn = "your_mobile_apn";  // e.g., "airtelgprs.com"
const char* firebaseHost = "fish-market-system.firebaseio.com";
const char* firebaseAuth = "YOUR_DATABASE_SECRET";
const char* machineId = "MACHINE_001";
```

### Step 4: Upload Firmware

1. Connect ESP32 via USB
2. Select correct board and port in Arduino IDE
3. Click Upload
4. Open Serial Monitor (115200 baud)
5. Follow calibration instructions

## Part 5: Testing

### Create Test Users

1. **Admin User**:
   - Signup using Admin App
   - Phone: Your test number
   - Role will be set to "admin"

2. **Merchant User**:
   - Signup using Merchant App
   - Add shop details
   - Bind machine ID

3. **Client User**:
   - Signup using Client App
   - Browse available fish

### Test Workflow

1. **Merchant**: Add fish inventory with images and rates
2. **ESP32**: Place fish on scale, verify weight in merchant app
3. **Merchant**: Create order with current weight
4. **Client**: View order, see price breakdown with GST
5. **Client**: Make payment or select COD
6. **Admin**: View analytics and reports

## Part 6: Production Deployment

### Android APK Build

For each app:

```bash
flutter build apk --release
```

APK will be in `build/app/outputs/flutter-apk/app-release.apk`

### Firebase App Distribution (Optional)

```bash
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app YOUR_FIREBASE_APP_ID \
  --groups testers
```

## Troubleshooting

### Firebase Authentication Issues

- Ensure Phone authentication is enabled
- Check SHA-1 fingerprint is added in Firebase console
- Verify app package names match

### Weight Not Updating

- Check ESP32 serial monitor for errors
- Verify Firebase credentials in firmware
- Test internet connectivity on SIM card
- Check Firestore security rules

### Build Errors

```bash
flutter clean
flutter pub get
flutter pub upgrade
```

### Payment Integration Issues

- Verify Razorpay keys
- Test in test mode first
- Check Razorpay dashboard for logs

## Support & Documentation

- Firebase: https://firebase.google.com/docs
- Flutter: https://flutter.dev/docs
- Razorpay: https://razorpay.com/docs
- ESP32: https://docs.espressif.com/

## Security Checklist

- [ ] Enable App Check in Firebase
- [ ] Add SHA certificates to Firebase
- [ ] Use environment variables for secrets
- [ ] Enable ProGuard for Android release builds
- [ ] Set up Firebase App Distribution for testing
- [ ] Configure proper Firestore security rules
- [ ] Use HTTPS for all API calls
- [ ] Implement rate limiting
- [ ] Enable 2FA for Firebase console
- [ ] Regular security audits

## License

This system is proprietary software for fish market businesses only.
