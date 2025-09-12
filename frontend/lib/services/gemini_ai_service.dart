import 'package:google_generative_ai/google_generative_ai.dart';
import 'app_code_knowledge.dart';

class GeminiAiService{
  static const String API_KEY = 'AIzaSyCxoS-a4TMGKTVjiev9PswukosCN0N4rIc';
  static GenerativeModel? _model;
  
  static Future<void> initialize() async {
    try {
      _model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: API_KEY,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 600,
        ),
      );
    } catch (e) {
      print('Error initializing Gemini AI: $e');
    }
  }
  
  static Future<String> getResponseWithCodeKnowledge(
    String message,
    {String? conversationHistory,
    Map<String, dynamic>? businessContext}
  ) async {
    try {
      if (_model == null) {
        await initialize();
      }
      
      if (_model == null) {
        return _getFallbackWithCodeKnowledge(message);
      }
      
      // Build comprehensive prompt with actual app code knowledge
      final prompt = _buildCodeAwarePrompt(message, conversationHistory, businessContext);
      
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      
      String? generatedText = response.text;
      
      if (generatedText != null && generatedText.isNotEmpty) {
        String cleanedResponse = generatedText.trim();
        
        // Remove any assistant prefixes
        if (cleanedResponse.startsWith('FETCH Assistant:')) {
          cleanedResponse = cleanedResponse.substring('FETCH Assistant:'.length).trim();
        }
        
        return cleanedResponse;
      } else {
        return _getFallbackWithCodeKnowledge(message);
      }
      
    } catch (e) {
      print('Enhanced Gemini AI Error: $e');
      return _getFallbackWithCodeKnowledge(message);
    }
  }
  
  static String _buildCodeAwarePrompt(
    String message, 
    String? conversationHistory,
    Map<String, dynamic>? businessContext
  ) {
    // Get comprehensive app knowledge
    String appKnowledge = AppCodeKnowledge.getAllAppKnowledge();
    
    // Build business context if available
    String contextInfo = '';
    if (businessContext != null) {
      final businessName = businessContext['business_name'] ?? 'your business';
      final activeDeliveries = businessContext['active_deliveries'] ?? [];
      final monthlyStats = businessContext['monthly_stats'] ?? {};
      
      contextInfo = '''
CURRENT BUSINESS CONTEXT:
- Business: $businessName
- Active deliveries: ${activeDeliveries.length}
- Monthly deliveries: ${monthlyStats['total_deliveries'] ?? 0}
- Account balance: \$${(businessContext['account_balance'] ?? 0.0).toStringAsFixed(2)}

ACTIVE DELIVERIES:
${_formatActiveDeliveries(activeDeliveries)}
''';
    }
    
    // Add conversation history if available
    String historyInfo = '';
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      historyInfo = '''
CONVERSATION HISTORY:
$conversationHistory
''';
    }
    
    return '''
You are FETCH Assistant, an AI that has been trained on the complete FETCH delivery management app codebase.

$appKnowledge

$contextInfo

$historyInfo

INSTRUCTIONS:
You have deep knowledge of the FETCH app's code structure, UI components, navigation flows, and business logic. When answering questions:

1. Reference specific UI elements (buttons, tabs, pages) by their actual names from the code
2. Provide exact navigation paths (e.g., "Dashboard → Create New Delivery button → Step 2")
3. Mention actual field names, dropdown options, and form elements
4. Use knowledge of the database schema and business logic
5. Reference specific delivery statuses and their meanings
6. Guide users through actual app workflows with precise steps
7. If asked about features not in the codebase, clearly state what's available vs. not implemented
8. Use business context data when relevant (their active deliveries, stats, etc.)
9. Be conversational but technically accurate based on the actual code

USER QUESTION: "$message"

Respond as FETCH Assistant with detailed knowledge of the app's implementation:''';
  }
  
  static String _formatActiveDeliveries(List<dynamic> deliveries) {
    if (deliveries.isEmpty) return 'No active deliveries';
    
    String formatted = '';
    for (int i = 0; i < deliveries.length && i < 3; i++) {
      final delivery = deliveries[i];
      formatted += '- #${delivery['id']}: ${delivery['status']} to ${delivery['destination']}\n';
    }
    return formatted;
  }
  
  static String _getFallbackWithCodeKnowledge(String message) {
    String lowercaseMessage = message.toLowerCase();
    
    // Create delivery with specific app knowledge
    if (lowercaseMessage.contains('create') || 
        lowercaseMessage.contains('new delivery') ||
        lowercaseMessage.contains('send')) {
      return '''To create a new delivery in the FETCH app:

1. **Go to Dashboard tab** (first tab in bottom navigation)
2. **Tap the "Create New Delivery" FloatingActionButton** (+ icon)
3. **Step 1: Pickup Location**
   - Tap on the Google Maps to set pickup point
   - Or use "Use Current Location" button
   - Address auto-fills from map selection
4. **Step 2: Delivery Destination** 
   - Set delivery location on map
   - Confirm the address is correct
5. **Step 3: Package Details**
   - Select type: Food, Documents, Electronics, Clothing, Other
   - Choose size: Small, Medium, Large, Extra Large
   - Enter weight in kg
   - Add description
6. **Step 4: Recipient Info**
   - Enter recipient name and phone number
   - Add special delivery instructions
7. **Step 5: Review & Submit**
   - Check the calculated cost
   - Tap "Create Delivery Request"

The system will automatically notify available couriers in your area! 📦''';
    }
    
    // Track delivery with specific UI elements
    if (lowercaseMessage.contains('track') || 
        lowercaseMessage.contains('status') ||
        lowercaseMessage.contains('where')) {
      return '''To track your deliveries in FETCH:

**From Dashboard:**
1. Open the **Dashboard tab** (home icon)
2. Scroll through your **active deliveries list**
3. **Tap any delivery item** to open detailed tracking

**In Tracking View:**
- **Google Maps** shows real-time courier location (blue marker)
- **Pickup location** (green marker)
- **Delivery destination** (red marker)
- **Status bar** at top shows current progress
- **Courier info card** with name, phone, rating

**Delivery Statuses:**
🟡 **pending** - Waiting for courier
🔵 **accepted** - Courier assigned  
🟠 **picked_up** - Package collected
🚚 **in_transit** - On the way
✅ **delivered** - Completed

You'll also get **push notifications** for each status change! 📱''';
    }
    
    // Navigation help with exact paths
    if (lowercaseMessage.contains('navigate') ||
        lowercaseMessage.contains('find') ||
        lowercaseMessage.contains('where is')) {
      return '''FETCH App Navigation Guide:

**Main Tabs (Bottom Navigation):**
- 🏠 **Dashboard** - Your deliveries and stats
- 💬 **Chat** - Customer service (you're here!)  
- 👤 **Profile** - Business account settings

**Dashboard Features:**
- **Active Deliveries List** - Tap any item for tracking
- **"Create New Delivery" Button** - The + floating button
- **Stats Cards** - Monthly totals and costs
- **Pull to refresh** - Update delivery status

**Profile Management:**
- **Profile Tab** → **Edit Mode** (pencil icon)
- Update: Business name, address, phone, tax ID
- **Location Detection** button uses GPS
- **Notification Settings** for delivery updates

**Getting Help:**
- **Chat Tab** (where you are now)
- **Connect to Human** button in chat AppBar

What specific page or feature are you looking for? 🧭''';
    }
    
    // Problems/issues with code knowledge
    if (lowercaseMessage.contains('problem') ||
        lowercaseMessage.contains('issue') ||
        lowercaseMessage.contains('error') ||
        lowercaseMessage.contains('not working')) {
      return '''I can help troubleshoot FETCH app issues! 🔧

**Common Solutions:**

**Delivery Problems:**
- **Cancelled delivery**: Only possible when status = "pending"
- **Can't contact courier**: Use Call/Message buttons in tracking view
- **Wrong address**: Cancel if pending, or contact courier directly

**App Issues:**
- **Login problems**: Try clearing app data or re-authenticate
- **Maps not loading**: Check location permissions in device settings
- **No deliveries showing**: Pull to refresh on Dashboard tab

**Location Issues:**
- **Can't detect location**: Enable GPS permission for FETCH app
- **Wrong pickup address**: Use manual address entry instead of GPS
- **Map not accurate**: Tap directly on map to set precise location

**Account Issues:**
- **Profile not saving**: Check internet connection and try again
- **Notifications not working**: Enable push notifications in device settings

**For Complex Issues:**
- Tap **"Connect to Human"** button above for live support
- Or describe your specific problem and I'll provide detailed steps!

What exactly isn't working for you? 🤔''';
    }
    
    // Default with comprehensive app knowledge
    return '''Hi! I'm FETCH Assistant with complete knowledge of your app's codebase and features! 🤖

**I can help you with:**

📱 **App Navigation**
- Using the 3-tab interface (Dashboard/Chat/Profile)
- Finding specific buttons and features
- Understanding the user interface

📦 **Delivery Management** 
- Creating deliveries (5-step process)
- Real-time tracking with Google Maps
- Understanding delivery statuses (pending→accepted→picked_up→in_transit→delivered)
- Contacting couriers and managing deliveries

👤 **Account Management**
- Business profile setup and editing
- Notification settings and preferences
- Understanding your delivery history and stats

🔧 **Troubleshooting**
- Solving app problems and errors  
- Location and GPS issues
- Authentication and login problems

💬 **Technical Questions**
- How specific features work
- Database and backend functionality
- Integration with Firebase and Google Maps

 What would you like help with? 🚀''';
  }
}

// Extension to integrate with existing business chat page
extension GeminiWithCodeIntegration on GeminiAiService {
  
  // This method replaces the old GeminiAIService.getResponse() calls
  static Future<String> getResponse(String message) async {
    return await GeminiAiService.getResponseWithCodeKnowledge(message);
  }
  
  // Enhanced version with context (for the new chat implementation)
  static Future<String> getContextualResponse(
    String message,
    String conversationHistory,
    Map<String, dynamic> businessContext,
  ) async {
    return await GeminiAiService.getResponseWithCodeKnowledge(
      message,
      conversationHistory: conversationHistory,
      businessContext: businessContext,
    );
  }
}