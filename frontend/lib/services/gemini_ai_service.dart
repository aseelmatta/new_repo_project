import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiAIService {
  static const String API_KEY = 'AIzaSyCxoS-a4TMGKTVjiev9PswukosCN0N4rIc'; // Replace with your actual API key
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
          maxOutputTokens: 200,
        ),
      );
    } catch (e) {
      print('Error initializing Gemini AI: $e');
    }
  }
  
  static Future<String> getResponse(String message) async {
    try {
      if (_model == null) {
        await initialize();
      }
      
      if (_model == null) {
        return _getFallbackResponse(message);
      }
      
      final prompt = '''
You are FETCH Assistant, a helpful AI chatbot for a delivery management mobile app called FETCH.

Your role: Help business users with their delivery needs in a friendly, concise way.

You can help with:
• Delivery tracking and status updates
• Creating new delivery requests
• Courier information and ratings  
• Account settings and profile management
• Billing and payment questions
• App navigation and features
• General delivery-related questions

Guidelines:
- Keep responses friendly and conversational
- Be concise (1-3 sentences usually)
- Use emojis occasionally to be engaging
- If you can't help with something specific, suggest connecting to human support
- Always stay in character as FETCH Assistant
- Focus on delivery and logistics topics

User message: "$message"

Respond as FETCH Assistant:''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      
      String? generatedText = response.text;
      
      if (generatedText != null && generatedText.isNotEmpty) {
        // Clean up the response
        String cleanedResponse = generatedText.trim();
        
        // Remove any "FETCH Assistant:" prefix if present
        if (cleanedResponse.startsWith('FETCH Assistant:')) {
          cleanedResponse = cleanedResponse.substring('FETCH Assistant:'.length).trim();
        }
        
        return cleanedResponse;
      } else {
        return _getFallbackResponse(message);
      }
      
    } catch (e) {
      print('Gemini AI Error: $e');
      return _getFallbackResponse(message);
    }
  }
  
  static String _getFallbackResponse(String message) {
    // Fallback pattern matching when AI is unavailable
    String lowercaseMessage = message.toLowerCase();
    
    // Delivery status and tracking
    if (lowercaseMessage.contains('status') || 
        lowercaseMessage.contains('track') || 
        lowercaseMessage.contains('where is') ||
        lowercaseMessage.contains('find my')) {
      return "I can help you track your deliveries! 📦\n\nTo check your delivery status:\n1. Go to your Dashboard\n2. Find your delivery in the list\n3. Tap on it for real-time tracking\n\nOr tell me your delivery ID and I'll help you locate it!";
    }

    // Creating deliveries
    if (lowercaseMessage.contains('create') || 
        lowercaseMessage.contains('new delivery') || 
        lowercaseMessage.contains('send') ||
        lowercaseMessage.contains('ship')) {
      return "Creating a new delivery is easy! ✨\n\n1. Tap the 'New Delivery' button on your dashboard\n2. Set pickup and dropoff locations on the map\n3. Add package details and recipient info\n4. Submit your request\n\nCouriers in your area will be notified immediately!";
    }

    // Courier related
    if (lowercaseMessage.contains('courier') || 
        lowercaseMessage.contains('driver') || 
        lowercaseMessage.contains('delivery person')) {
      return "About our couriers: 🚗\n\n• All couriers are verified and rated by users\n• You can message them directly during delivery\n• Rate your courier after each delivery\n• View courier location in real-time\n\nNeed to contact your current courier? Check your active delivery for the message option!";
    }

    // Pricing and billing
    if (lowercaseMessage.contains('price') || 
        lowercaseMessage.contains('cost') || 
        lowercaseMessage.contains('billing') || 
        lowercaseMessage.contains('payment') ||
        lowercaseMessage.contains('money')) {
      return "Pricing information: 💰\n\n• Pricing based on distance and package size\n• You'll see the cost before confirming\n• Multiple payment methods accepted\n• Receipts available in your delivery history\n\nFor specific pricing questions, would you like me to connect you with our billing team?";
    }

    // Account and profile
    if (lowercaseMessage.contains('account') || 
        lowercaseMessage.contains('profile') || 
        lowercaseMessage.contains('settings') ||
        lowercaseMessage.contains('update')) {
      return "Account management: ⚙️\n\nYou can update your:\n• Business information in Profile tab\n• Contact details and preferences\n• Notification settings\n• Payment methods\n\nGo to Profile → Settings to make changes. Need help with something specific?";
    }

    // Problems or issues
    if (lowercaseMessage.contains('problem') || 
        lowercaseMessage.contains('issue') || 
        lowercaseMessage.contains('help') || 
        lowercaseMessage.contains('support') ||
        lowercaseMessage.contains('error')) {
      return "I'm sorry you're experiencing an issue! 😔\n\nI can help with common problems, or connect you with our human support team if needed.\n\nCould you tell me more about what's happening? For example:\n• Delivery delays\n• App problems\n• Billing issues\n• Courier concerns";
    }

    // Cancel or refund
    if (lowercaseMessage.contains('cancel') || 
        lowercaseMessage.contains('refund') || 
        lowercaseMessage.contains('return')) {
      return "Cancellations and refunds: 🔄\n\n• Cancel pending deliveries anytime from your dashboard\n• Partial refunds for cancellations after courier assignment\n• Full refund if courier cancels\n• Report issues for case-by-case review\n\nNeed to cancel a specific delivery? I can guide you through the process!";
    }

    // Greetings
    if (lowercaseMessage.contains('hello') || 
        lowercaseMessage.contains('hi') || 
        lowercaseMessage.contains('hey')) {
      return "Hello! 👋 Great to see you!\n\nI'm FETCH Assistant, here to help you with all your delivery needs. How can I assist you today?";
    }

    // Thanks
    if (lowercaseMessage.contains('thank') || lowercaseMessage.contains('thanks')) {
      return "You're very welcome! 😊\n\nIs there anything else I can help you with regarding your deliveries today?";
    }

    // Connect to human
    if (lowercaseMessage.contains('human') || 
        lowercaseMessage.contains('person') || 
        lowercaseMessage.contains('agent') || 
        lowercaseMessage.contains('representative')) {
      return "I'm connecting you with our customer service team! 👨‍💼\n\nA human agent will be with you shortly. Please wait a moment while I transfer your chat...";
    }

    // Default response
    return "I understand you're asking about \"$message\" 🤔\n\nI'm here to help with:\n• Delivery tracking and status\n• Creating new deliveries\n• Courier information\n• Account settings\n• Billing questions\n\nCould you be more specific about what you need help with? Or would you like me to connect you with a human agent?";
  }
}