import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/gemini_ai_service.dart';

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
    _initializeAI();
    _addWelcomeMessage();
  }

  Future<void> _initializeAI() async {
    await GeminiAiService.initialize();
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
    // Simulate thinking time
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      String response;
      
      if (_isConnectedToHuman) {
        // Simulate human responses
        response = _getHumanResponse(userMessage);
      } else {
        // Use Gemini AI
        response = await GeminiAiService.getResponseWithCodeKnowledge(userMessage);
      }
      
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
          isHuman: _isConnectedToHuman,
        ));
      });
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: "I'm experiencing some technical difficulties right now. Let me connect you with a human agent who can help you better!",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      // Auto-connect to human on error
      Future.delayed(const Duration(seconds: 1), () {
        _connectToHuman();
      });
    }

    _scrollToBottom();
  }

  String _getHumanResponse(String message) {
    // Simulate human agent responses
    List<String> humanResponses = [
      "I understand your concern. Let me look into that for you right away.",
      "Thank you for providing those details. I can definitely help you with that.",
      "I see what you're asking about. Let me check our system for the most up-to-date information.",
      "That's a great question! I've helped many customers with similar situations.",
      "I appreciate your patience. Let me get the exact information you need.",
    ];
    
    // Return a random human-like response
    return humanResponses[DateTime.now().millisecond % humanResponses.length];
  }

  Future<String> _generateResponse(String message) async {
    // This method is now replaced by _getAIResponse
    return await GeminiAiService.getResponseWithCodeKnowledge(message);
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