# 🌿 UrbanLeafs

A comprehensive business management Flutter application designed for small to medium enterprises to manage their daily operations, including attendance tracking, inventory management, order processing, payment tracking, and financial reporting.

## 📱 Features

### 🏠 Dashboard
- **Real-time Overview**: Get instant insights into daily operations
- **Quick Access Cards**: Navigate to key modules with one tap
- **Live Statistics**: View today's attendance, orders, payments, and expenses
- **Date Navigation**: Switch between different dates to view historical data

### 👥 Attendance Management
- **Daily Attendance Tracking**: Monitor employee presence for morning and afternoon shifts
- **Attendance Status**: Track present, absent, and half-day statuses
- **Shift Management**: Support for morning and afternoon shifts
- **Attendance History**: View historical attendance data

### 📦 Inventory Management
- **Stock Tracking**: Monitor inventory levels in real-time
- **Item Management**: Add, edit, and manage inventory items
- **Unit Support**: Multiple units (kg, pcs, liters, units)
- **Stock History**: Track inventory changes over time
- **Low Stock Alerts**: Get notified when items are running low

### 📋 Order Management
- **Order Creation**: Create and manage customer orders
- **Order Tracking**: Monitor order status and progress
- **Customer Integration**: Link orders to customer profiles
- **Daily Order Summary**: View today's orders at a glance

### 💰 Payment Management
- **Payment Tracking**: Record and track customer payments
- **Multiple Payment Methods**: Support for cash and online payments
- **Payment History**: Maintain complete payment records
- **Daily Revenue Summary**: Track daily earnings

### 💸 Expense Management
- **Expense Categories**: Organize expenses by type (raw material, transportation, labor, other)
- **Daily Expense Tracking**: Monitor daily operational costs
- **Expense History**: Maintain complete expense records
- **Cost Analysis**: Analyze spending patterns

### 📊 Balance Sheet
- **Financial Overview**: Comprehensive financial reporting
- **Customer Details**: Track customer-wise transactions
- **Transaction History**: Complete audit trail
- **Filtering Options**: Filter data by date ranges and categories

### 👤 User Management
- **Role-based Access**: Admin and regular user roles
- **Profile Management**: User profile customization
- **Password Management**: Secure password change functionality
- **User Settings**: Personalized app preferences

### ⚙️ Settings & Configuration
- **Theme Support**: Light and dark theme options
- **Language Settings**: Multi-language support
- **Notification Preferences**: Customizable notification settings
- **Privacy Settings**: Data privacy controls
- **App Information**: Version and legal information

### 🔔 Notifications
- **Real-time Alerts**: Get notified of important events
- **Customizable Notifications**: Configure notification preferences
- **Notification History**: View past notifications

## 🛠️ Technology Stack

- **Framework**: Flutter 3.8.1+
- **State Management**: Riverpod
- **Backend**: Firebase (Firestore, Authentication, Storage)
- **Routing**: Go Router
- **Local Storage**: Shared Preferences
- **UI Components**: Material Design 3
- **Image Handling**: Image Picker, Cached Network Image
- **Date/Time**: Intl, Table Calendar
- **Code Generation**: Freezed

## 📋 Prerequisites

- Flutter SDK 3.8.1 or higher
- Dart SDK 3.0 or higher
- Android Studio / VS Code
- Firebase project setup
- Android SDK (for Android builds)

## 🚀 Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/abh1shek017/urbanleafs.git
   cd urbanleafs
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Enable Authentication, Firestore, and Storage
   - Download `google-services.json` and place it in `android/app/`
   - Configure Firebase in your project

4. **Run the application**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### Firebase Configuration

1. **Authentication Setup**
   - Enable Email/Password authentication in Firebase Console
   - Configure sign-in methods as needed

2. **Firestore Setup**
   - Create the following collections:
     - `users`
     - `attendance`
     - `expenses`
     - `inventory`
     - `orders`
     - `payments`
     - `workers`

3. **Storage Setup**
   - Configure Firebase Storage rules for image uploads
   - Set up appropriate security rules

### Environment Variables

Create a `.env` file in the root directory:
```env
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id
```

## 📱 Platform Support

- ✅ Android (API 21+)


## 🏗️ Project Structure

```
lib/
├── constants/          # App constants and configurations
├── models/            # Data models and entities
├── providers/         # Riverpod providers
├── repositories/      # Data access layer
├── routes/           # Navigation and routing
├── screens/          # UI screens organized by feature
│   ├── activity/     # Activity tracking screens
│   ├── appearance/   # Theme and appearance settings
│   ├── attendance/   # Attendance management
│   ├── auth/         # Authentication screens
│   ├── balance_sheet/ # Financial reporting
│   ├── customer/     # Customer management
│   ├── dashboard/    # Main dashboard
│   ├── expense/      # Expense management
│   ├── inventory/    # Inventory management
│   ├── legal/        # Legal and terms screens
│   ├── master_data/  # Data management
│   ├── notifications/ # Notification screens
│   ├── orders/       # Order management
│   ├── payments/     # Payment tracking
│   ├── profile/      # User profile management
│   ├── settings/     # App settings
│   ├── support/      # Help and support
│   └── workers/      # Worker management
├── services/         # Business logic and external services
├── themes/          # App theming
├── utils/           # Utility functions
├── viewmodels/      # Business logic layer
└── widgets/         # Reusable UI components
```

## 🔐 Security Features

- **Authentication**: Firebase Authentication with email/password
- **Role-based Access**: Admin and regular user permissions
- **Data Validation**: Input validation and sanitization
- **Secure Storage**: Encrypted local storage for sensitive data
- **Firebase Security Rules**: Database and storage security

## 📊 Data Models

The application uses comprehensive data models for:
- **User Management**: User profiles, roles, and permissions
- **Attendance**: Daily attendance records with shift tracking
- **Inventory**: Stock items with units and quantities
- **Orders**: Customer orders with status tracking
- **Payments**: Payment records with multiple methods
- **Expenses**: Expense tracking with categorization
- **Workers**: Employee management and profiles

## 🎨 UI/UX Features

- **Material Design 3**: Modern, accessible design system
- **Dark/Light Themes**: User preference support
- **Responsive Design**: Works across different screen sizes
- **Loading States**: Smooth loading indicators
- **Error Handling**: User-friendly error messages
- **Animations**: Smooth transitions and micro-interactions

## 🧪 Testing

Run tests using:
```bash
flutter test
```

## 📦 Building for Production

### Android
```bash
flutter build apk --release
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue in the GitHub repository
- Contact the development team
- Check the documentation in the `/docs` folder

## 🔄 Version History

- **v1.0.0** - Initial release with core features
  - Dashboard with real-time data
  - Attendance management
  - Inventory tracking
  - Order and payment management
  - User authentication and roles

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Riverpod for state management

---

**UrbanLeafs** - Empowering businesses with smart management solutions 🌿
