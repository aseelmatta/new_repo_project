import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BusinessChatPage extends StatefulWidget {
  const BusinessChatPage({super.key});

  @override
  State<BusinessChatPage> createState() => _BusinessChatPageState();
}

class _BusinessChatPageState extends State<BusinessChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isConnectedToHuman = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text: "Hi! I'm FETCH Assistant 🤖\n\nI'm here to help you with:\n• Delivery status updates\n• Creating new deliveries\n• Courier information\n• Account settings\n• Billing questions\n\nHow can I assist you today?",
        isUser: false,
        timestamp: DateTime.now(),
        isWelcome: true,
      ));
    });
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate AI response
    await _getAIResponse(message);
  }

  Future<void> _getAIResponse(String userMessage) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    String response = await _generateResponse(userMessage);
    
    setState(() {
      _isTyping = false;
      _messages.add(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });

    _scrollToBottom();
  }

  Future<String> _generateResponse(String message) async {
    // Convert to lowercase for pattern matching
    String lowercaseMessage = message.toLowerCase();

    // Delivery status related
    if (lowercaseMessage.contains('status') || lowercaseMessage.contains('track') || lowercaseMessage.contains('where is')) {
      return "I can help you track your deliveries! 📦\n\nTo check your delivery status:\n1. Go to your Dashboard\n2. Look for your delivery in the list\n3. Tap on it for real-time tracking\n\nOr tell me your delivery ID and I'll check it for you!";
    }

    // Creating deliveries
    if (lowercaseMessage.contains('create') || lowercaseMessage.contains('new delivery') || lowercaseMessage.contains('send')) {
      return "Creating a new delivery is easy! ✨\n\n1. Tap the 'New Delivery' button on your dashboard\n2. Set pickup and dropoff locations\n3. Add package details\n4. Submit your request\n\nCouriers in your area will be notified immediately!";
    }

    // Courier related
    if (lowercaseMessage.contains('courier') || lowercaseMessage.contains('driver') || lowercaseMessage.contains('delivery person')) {
      return "About our couriers: 🚗\n\n• All couriers are verified and rated\n• You can message them directly during delivery\n• Rate your courier after each delivery\n• View courier location in real-time\n\nNeed to contact your current courier? Check your active delivery for the message option!";
    }

    // Pricing and billing
    if (lowercaseMessage.contains('price') || lowercaseMessage.contains('cost') || lowercaseMessage.contains('billing') || lowercaseMessage.contains('payment')) {
      return "Pricing information: 💰\n\n• Pricing is based on distance and package size\n• You'll see the cost before confirming\n• Multiple payment methods accepted\n• Receipts available in your delivery history\n\nFor specific pricing questions, would you like me to connect you with our billing team?";
    }

    // Account and profile
    if (lowercaseMessage.contains('account') || lowercaseMessage.contains('profile') || lowercaseMessage.contains('settings')) {
      return "Account management: ⚙️\n\nYou can update your:\n• Business information\n• Contact details\n• Notification preferences\n• Payment methods\n\nGo to Profile → Settings to make changes. Need help with something specific?";
    }

    // Problems or issues
    if (lowercaseMessage.contains('problem') || lowercaseMessage.contains('issue') || lowercaseMessage.contains('help') || lowercaseMessage.contains('support')) {
      return "I'm sorry you're experiencing an issue! 😔\n\nI can help with common problems, or if needed, connect you with our human support team.\n\nCould you tell me more about what's happening? For example:\n• Delivery delays\n• App problems\n• Billing issues\n• Courier concerns";
    }

    // Hours and availability
    if (lowercaseMessage.contains('hour') || lowercaseMessage.contains('time') || lowercaseMessage.contains('available') || lowercaseMessage.contains('open')) {
      return "Service availability: 🕐\n\n• Delivery service: 24/7\n• Customer support: 6 AM - 11 PM daily\n• Same-day delivery available\n• Express delivery for urgent items\n\nCouriers set their own availability, so you'll see who's active in your area!";
    }

    // Cancel or refund
    if (lowercaseMessage.contains('cancel') || lowercaseMessage.contains('refund') || lowercaseMessage.contains('return')) {
      return "Cancellations and refunds: 🔄\n\n• Cancel pending deliveries anytime\n• Partial refunds for cancellations after courier assignment\n• Full refund if courier cancels\n• Report issues for case-by-case review\n\nNeed to cancel a specific delivery? I can help with that!";
    }

    // Greetings
    if (lowercaseMessage.contains('hello') || lowercaseMessage.contains('hi') || lowercaseMessage.contains('hey')) {
      return "Hello! 👋 Great to see you again!\n\nHow can I help you with your FETCH deliveries today?";
    }

    // Thanks
    if (lowercaseMessage.contains('thank') || lowercaseMessage.contains('thanks')) {
      return "You're very welcome! 😊\n\nIs there anything else I can help you with today?";
    }

    // Connect to human
    if (lowercaseMessage.contains('human') || lowercaseMessage.contains('person') || lowercaseMessage.contains('agent') || lowercaseMessage.contains('representative')) {
      _connectToHuman();
      return "I'm connecting you with our customer service team! 👨‍💼\n\nA human agent will be with you shortly. Please wait a moment...";
    }

    // Default response for unclear queries
    return "I understand you're asking about \"$message\" 🤔\n\nI can help you with:\n• Delivery tracking and status\n• Creating new deliveries\n• Courier information\n• Account settings\n• Billing questions\n\nCould you be more specific about what you need help with? Or would you like me to connect you with a human agent?";
  }

  void _connectToHuman() {
    setState(() {
      _isConnectedToHuman = true;
    });
    
    // Simulate connecting to human agent
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _messages.add(ChatMessage(
          text: "Hi! This is Sarah from FETCH Customer Service. 👋\n\nI see you were chatting with our AI assistant. How can I personally help you today?",
          isUser: false,
          timestamp: DateTime.now(),
          isHuman: true,
        ));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _isConnectedToHuman ? Colors.green : Colors.blue,
              radius: 16,
              child: Icon(
                _isConnectedToHuman ? Icons.person : Icons.smart_toy,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isConnectedToHuman ? 'Customer Service' : 'FETCH Assistant',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _isConnectedToHuman ? 'Human agent' : 'AI Chatbot',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (!_isConnectedToHuman)
            TextButton.icon(
              onPressed: _connectToHuman,
              icon: const Icon(Icons.person, size: 18),
              label: const Text('Human'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Status indicator
          if (_isConnectedToHuman)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.green.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Connected to human agent',
                    style: GoogleFonts.inter(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Typing indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    radius: 16,
                    child: Icon(
                      _isConnectedToHuman ? Icons.person : Icons.smart_toy,
                      color: Colors.grey[600],
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Typing...',
                          style: GoogleFonts.inter(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: message.isHuman ? Colors.green : Colors.blue,
              radius: 16,
              child: Icon(
                message.isHuman ? Icons.person : Icons.smart_toy,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? Colors.blue 
                    : message.isWelcome 
                        ? Colors.green.withOpacity(0.1)
                        : message.isHuman
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                border: message.isWelcome 
                    ? Border.all(color: Colors.green.withOpacity(0.3))
                    : message.isHuman
                        ? Border.all(color: Colors.green.withOpacity(0.3))
                        : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: GoogleFonts.inter(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.inter(
                      color: message.isUser 
                          ? Colors.white.withOpacity(0.7) 
                          : Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: Colors.blue,
              radius: 16,
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isWelcome;
  final bool isHuman;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isWelcome = false,
    this.isHuman = false,
  });
}