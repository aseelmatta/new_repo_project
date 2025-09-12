class AppCodeKnowledge {
  // This class contains extracted knowledge from your app's codebase
  
  static String getAppArchitecture() {
    return '''
FETCH APP ARCHITECTURE & CODE STRUCTURE:

1. MAIN NAVIGATION FLOW:
   WelcomePage -> Authentication -> AccountSetupPage -> BusinessDashboard
   
2. BUSINESS DASHBOARD STRUCTURE:
   - Uses PageController with 3 tabs
   - Tab 0: Dashboard (deliveries list, create button, stats)
   - Tab 1: Chat (BusinessChatPage for customer service)  
   - Tab 2: Profile (BusinessProfilePage for account management)
   - Bottom Navigation Bar switches between tabs
   
3. AUTHENTICATION SYSTEM:
   - Firebase Authentication with AuthService
   - Google Sign-In integration
   - Facebook Sign-In integration
   - Role-based routing (business vs courier)
   - User profile stored in Firestore

4. DELIVERY CREATION WORKFLOW:
   - Multi-step form in DeliveryCreationPage
   - Step 1: Pickup location (Google Maps integration)
   - Step 2: Delivery destination (Google Maps)
   - Step 3: Package details (type, size, weight, description)
   - Step 4: Recipient information and special instructions
   - Step 5: Review and cost calculation
   - DeliveryService.createDelivery() submits to backend

5. REAL-TIME TRACKING SYSTEM:
   - DeliveryTrackingPage with Google Maps
   - Real-time courier location updates via Firestore listeners
   - Status progression: pending -> accepted -> picked_up -> in_transit -> delivered
   - Push notifications via Firebase Cloud Messaging
   - LocationService for GPS tracking

6. BUSINESS PROFILE MANAGEMENT:
   - BusinessSetupPage for initial profile creation
   - BusinessProfilePage for editing existing profile
   - Fields: businessName, businessType, taxId, address, phone
   - Location detection using device GPS
   - Profile data saved via AuthService.createUserProfile()

7. DATABASE SCHEMA (Firestore):
   Collections:
   - users: {id, email, role, businessName, phone, address, rating}
   - deliveries: {id, business_id, courier_id, status, pickup_address, delivery_address, package_type, cost, created_at}
   - business_accounts: {balance, payment_method, subscription_status}

8. TECHNICAL IMPLEMENTATION:
   - Flutter with Dart
   - Firebase services (Auth, Firestore, Cloud Messaging)
   - Google Maps SDK for location services
   - Provider for state management
   - Python backend API for complex operations
   ''';
  }

  static String getUIComponents() {
    return '''
UI COMPONENTS & NAVIGATION PATHS:

BUSINESS DASHBOARD:
- FloatingActionButton: "Create New Delivery" (navigates to DeliveryCreationPage)
- ListView of active deliveries (each item clickable for tracking)
- Stats cards showing monthly deliveries, active count, total cost
- Pull-to-refresh for updating delivery list
- Bottom navigation: Home, Chat, Profile icons

DELIVERY CREATION FORM:
- Google Maps widget for location selection
- Address text fields with autocomplete
- Package type dropdown: Food, Documents, Electronics, Clothing, Other
- Size selection: Small, Medium, Large, Extra Large  
- Weight input field (kg)
- Special instructions text area
- Recipient name and phone fields
- Cost display updates in real-time
- Submit button: "Create Delivery Request"

DELIVERY TRACKING PAGE:
- Full-screen Google Maps with markers
- Pickup location (green marker)
- Delivery location (red marker)  
- Courier location (blue marker, updates real-time)
- Status indicator at top: color-coded progress bar
- Courier info card: name, phone, rating, vehicle type
- Contact courier buttons: Call, Message
- Cancel delivery button (only if status = pending)

BUSINESS PROFILE PAGE:
- Edit mode toggle in AppBar
- Form fields: Business Name, Type, Tax ID, Address, Phone, Website
- Business type dropdown: Restaurant, Retail Store, Office, Warehouse, Other
- Location detection button uses GPS
- Save changes button
- Logout option

CHAT INTERFACE:
- Message bubbles (user=blue, assistant=gray)
- Quick action buttons below AI responses
- Typing indicator with animated dots
- "Connect to Human" button in AppBar
- Auto-scroll to bottom on new messages
''';
  }

  static String getCodeExamples() {
    return '''
KEY CODE IMPLEMENTATIONS:

1. CREATING DELIVERIES:
```dart
await DeliveryService.createDelivery({
  'business_id': userId,
  'pickup_address': pickupAddress,
  'delivery_address': deliveryAddress,
  'package_type': selectedPackageType,
  'special_instructions': instructions,
  'recipient_name': recipientName,
  'recipient_phone': recipientPhone,
});
```

2. REAL-TIME TRACKING:
```dart
StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
    .collection('deliveries')
    .doc(deliveryId)
    .snapshots(),
  builder: (context, snapshot) {
    // Updates UI when delivery status changes
  }
)
```

3. AUTHENTICATION FLOW:
```dart
// Sign in with Google
AuthResult result = await AuthService.signInWithGoogle();
if (result.success) {
  // Check if user has completed setup
  if (result.userData['role'] != null) {
    _navigateToDashboard(result.userData['role']);
  } else {
    // Navigate to AccountSetupPage
  }
}
```

4. LOCATION SERVICES:
```dart
// Get current location
Position position = await LocationService.getCurrentPosition();
String address = await LocationService.getCurrentAddress();
```

5. STATUS UPDATES:
```dart
await DeliveryService.updateDeliveryStatus(deliveryId, 'picked_up');
// Triggers notifications to business user
```
''';
  }

  static String getBusinessLogic() {
    return '''
BUSINESS LOGIC & WORKFLOWS:

DELIVERY STATUSES:
1. 'pending' - Just created, waiting for courier acceptance
2. 'accepted' - Courier assigned and accepted delivery
3. 'picked_up' - Package collected from pickup location
4. 'in_transit' - On route to delivery destination
5. 'delivered' - Successfully completed
6. 'cancelled' - Delivery cancelled by business or system

COST CALCULATION:
- Base price + distance multiplier + package size multiplier
- Different rates for different package types
- Rush delivery premium (if selected)
- Calculated in real-time as user inputs details

COURIER MATCHING:
- Find available couriers within pickup radius
- Filter by vehicle type capability
- Sort by distance and rating
- Automatic assignment or manual selection

NOTIFICATION TRIGGERS:
- Delivery created → notify nearby couriers
- Courier accepts → notify business
- Status changes → notify business and update tracking

ERROR HANDLING:
- Network errors → offline mode with local storage
- Location permission denied → manual address entry
- Payment failures → retry mechanism
- Courier unavailable → re-match algorithm

USER ROLES & PERMISSIONS:
- Business users: create deliveries, track couriers
- Courier users: accept jobs, update status, navigate
- Admin users: manage system, view analytics
''';
  }

  static String getCommonUserFlows() {
    return '''
COMMON USER FLOWS IN THE APP:

1. FIRST-TIME USER SETUP:
   WelcomePage → Google/Facebook login → AccountSetupPage → 
   Select "Business User" → BusinessSetupPage (multi-step) → 
   BusinessDashboard

2. CREATING A DELIVERY:
   Dashboard → "Create New Delivery" button → 
   Pick location on map → Set delivery destination → 
   Select package type → Add recipient details → 
   Review cost → Submit → Return to dashboard with new delivery

3. TRACKING DELIVERY:
   Dashboard → Tap delivery item → DeliveryTrackingPage → 
   View real-time map → See courier location → 
   Receive status updates → Delivery completed

4. MANAGING PROFILE:
   Profile tab → Edit mode → Update business info → 
   Change notification settings → Save changes

5. GETTING HELP:
   Chat tab → Ask question → Get AI response → 
   Use quick action buttons OR connect to human agent

6. DELIVERY PROBLEM:
   Dashboard → Problem delivery → Contact courier → 
   Or Chat tab → Report issue → Get assistance
''';
  }

  static String getAllAppKnowledge() {
    return '''
${getAppArchitecture()}

${getUIComponents()}

${getCodeExamples()}

${getBusinessLogic()}

${getCommonUserFlows()}
''';
  }
}