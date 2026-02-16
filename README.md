# 🐟 Fish Market Smart Weighing System

A comprehensive IoT-based smart weighing and billing system designed exclusively for fish shops, fish markets, and harbor vendors.

## 📱 Live Applications

### 🔗 Direct Links
- **Admin Panel**: https://planning-with-ai-3f007.web.app
- **Merchant App**: (Build & deploy locally)
- **Client App**: (Build & deploy locally)

### Running Apps Locally
```bash
# Merchant App
cd merchant_app
flutter run

# Client App  
cd client_app
flutter run

# Admin App
cd admin_app
flutter run
```

## 🎯 System Overview

This system consists of:
- **3 Flutter Mobile Apps** (Merchant, Client, Admin)
- **ESP32-based Smart Scale** with SIM connectivity
- **Firebase Backend** for real-time data sync
- **Automated GST Calculation** (Fish: 5%, Delivery: 18%)
- **Multiple Payment Options** (UPI, Cards, Banking, COD)

## 📱 Applications

### 1. Merchant App
For fish shop owners to manage their business:
- OTP-based authentication
- Bind weighing machine via Machine ID
- Live weight display from scale
- Manage daily fish inventory with images
- Set rates (wholesale/retail)
- View orders and payment status
- Daily sales analytics
- Send notifications to clients

### 2. Client App
For customers to place and track orders:
- OTP-based authentication
- View live order details with GST breakdown
- Multiple payment options:
  - UPI (GPay, PhonePe)
  - Credit/Debit Cards
  - Net Banking
  - Cash on Delivery
- Cancel orders with reason
- Download PDF invoices
- Order history

### 3. Admin App
For system monitoring and analytics:
- OTP-based authentication
- View all merchants and clients
- Daily/Monthly/Yearly reports
- Total sales and GST analytics
- Fish sales statistics (kg & revenue)
- Export reports (PDF/CSV)
- View-only access

## 🔧 Hardware Components

### Weighing Machine
- **Microcontroller**: ESP32
- **Load Cell**: HX711 amplifier + 50kg load cell
- **Connectivity**: SIM800L/SIM7600 GSM module
- **Power**: 5V 3A adapter
- **Features**:
  - Tamper-proof calibration lock
  - Real-time weight transmission via SIM
  - Unique Machine ID
  - Auto-tare functionality

## 💰 Pricing & GST Calculation

### Automatic Calculation
```
Fish Amount = Weight × Rate per kg
Fish GST (5%) = Fish Amount × 0.05
Delivery Charge = ₹35 (Fixed)
Delivery GST (18%) = ₹35 × 0.18 = ₹6.30

Total = Fish Amount + Fish GST + ₹35 + ₹6.30
```

### Example Invoice
```
Fish: Pomfret
Weight: 2.5 kg
Rate: ₹420/kg

Fish Amount:        ₹1,050.00
Fish GST (5%):         ₹52.50
Delivery Charge:       ₹35.00
Delivery GST (18%):     ₹6.30
────────────────────────────
Total Amount:      ₹1,143.80
```

## 🔐 Authentication & Security

- **Email/Password login** for all apps (Firebase Email Auth)
- **Role-based access control** (Merchant, Client, Admin)
- **Unique email** validation (no duplicates)
- **Tamper-proof** weight readings
- **Encrypted** data transmission
- **Firestore security rules** enforced

## 🗄️ Database Schema

### Collections
- `users` - All user accounts (merchants, clients, admins)
- `weighing_machines` - Machine data and live weights
- `fish_inventory` - Daily fish list with rates and images
- `orders` - All orders with complete details
- `notifications` - Push notification history
- `daily_sales_summary` - Analytics and reports

## 🚀 Features

### ✅ For Merchants
- Bind and manage weighing machines
- Add/update fish inventory daily
- Upload fish images
- Set wholesale/retail rates
- Real-time weight from scale
- Order management
- Payment tracking
- Daily sales reports
- Client notifications

### ✅ For Clients
- Browse available fish
- View live order details
- See GST breakdown
- Multiple payment methods
- Order cancellation
- PDF invoice download
- Order history

### ✅ For Admins
- System-wide analytics
- Merchant management
- Sales reports (Daily/Monthly/Yearly)
- GST collection tracking
- Data export (PDF/CSV)
- View-only access

## 📦 Tech Stack

### Mobile Apps
- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: StatefulWidget
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Payments**: Razorpay
- **PDF**: pdf package
- **Charts**: fl_chart (Admin app)

### Firmware
- **Platform**: ESP32 (Arduino)
- **Sensor**: HX711 + Load Cell
- **Connectivity**: SIM800L/SIM7600
- **Libraries**: HX711, ArduinoJson

### Backend
- **Authentication**: Firebase Email/Password Auth
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage
- **Hosting**: Firebase Realtime Database

## 📋 Requirements

### Software
- Flutter SDK 3.x+
- Dart SDK 3.10+
- Firebase CLI
- Android Studio / Xcode
- Arduino IDE (for ESP32)

### Hardware
- ESP32 development board
- HX711 load cell amplifier
- 50kg load cell
- SIM800L/SIM7600 module
- SIM card with data plan
- Power supply (5V 3A)

## 🛠️ Installation

See [SETUP_GUIDE.md](./SETUP_GUIDE.md) for detailed setup instructions.

Quick start:
```bash
# Clone repository
git clone <repository-url>

# Install dependencies for each app
cd merchant_app && flutter pub get
cd ../client_app && flutter pub get
cd ../admin_app && flutter pub get

# Configure Firebase
flutterfire configure

# Run apps
flutter run
```

## 📱 Screenshots

_Add screenshots of your apps here_

## 🎓 Usage

1. **Merchant Setup**:
   - Install Merchant App
   - Signup with phone OTP
   - Enter shop details
   - Bind weighing machine

2. **Daily Operations**:
   - Add today's fish inventory
   - Place fish on scale
   - Weight automatically captured
   - Create order with current weight
   - Client receives notification

3. **Client Purchase**:
   - Install Client App
   - Signup with phone OTP
   - View order details
   - Choose payment method
   - Download invoice

4. **Admin Monitoring**:
   - Install Admin App
   - View real-time analytics
   - Generate reports
   - Export data

## ⚠️ Important Notes

### ❌ Limitations
- **No website** - Mobile apps only
- **Fish shops only** - Not for restaurants/cafés
- **No hotel usage** - Strictly for fish markets
- **Read-only weight** - Merchants cannot edit weight
- **Fixed delivery charge** - ₹35 (can be customized in code)

### ✅ GST Compliance
- Fish sales: 5% GST
- Delivery: 18% GST
- Detailed invoice generation
- GST tracking and reporting

## 🤝 Contributing

This is a proprietary system designed for fish market businesses. For feature requests or bug reports, please contact the development team.

## 📄 License

Proprietary - All rights reserved

## 🆘 Support

For technical support or queries:
- Email: support@fishmarket.com
- Phone: +91-XXXXXXXXXX
- Documentation: See SETUP_GUIDE.md

## 🎯 Roadmap

- [ ] Push notifications implementation
- [ ] PDF invoice generation enhancement
- [ ] Multi-language support
- [ ] Offline mode
- [ ] Barcode/QR code integration
- [ ] Inventory alerts
- [ ] Customer loyalty program
- [ ] SMS notifications

## 👥 Team

Developed for fish market businesses to streamline operations and enhance customer experience.

---

**Version**: 1.0.0  
**Last Updated**: February 2026  
**Status**: Production Ready
