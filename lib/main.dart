import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          ChatScreen(),
          HistoryScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _userInput = TextEditingController();
  final TextEditingController _promptInput = TextEditingController();

  static const apiKey = "AIzaSyBuOxyDHjX167NOaz-fFb24CVhQj31D9-k";
  final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);

  List<Message> _messages = [];

  Future<void> sendMessage() async {
    final userMessage = _userInput.text;
    final prompt = _promptInput.text.isEmpty ? "Plan for Travel" : _promptInput.text;

    final fullPrompt = "$prompt\nUser: $userMessage";

    setState(() {
      _messages.add(Message(isUser: true, message: userMessage, date: DateTime.now()));
    });

    final content = [Content.text(fullPrompt)];
    final response = await model.generateContent(content);

    setState(() {
      _messages.add(Message(isUser: false, message: response.text ?? "", date: DateTime.now()));
    });

    _userInput.clear();
    _promptInput.clear();

    // Save chat after each message
    await saveChat();
  }

  Future<void> saveChat() async {
    final prefs = await SharedPreferences.getInstance();
    final chatData = _messages.map((m) => m.toJson()).toList();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await prefs.setString('chat_$timestamp', jsonEncode(chatData));

    // Save chat history
    List<String> history = prefs.getStringList('chat_history') ?? [];
    history.add('chat_$timestamp');
    await prefs.setStringList('chat_history', history);
  }

  Future<void> loadChat(String chatKey) async {
    final prefs = await SharedPreferences.getInstance();
    final savedChat = prefs.getString(chatKey);
    if (savedChat != null) {
      final chatData = jsonDecode(savedChat) as List;
      setState(() {
        _messages = chatData.map((m) => Message.fromJson(m)).toList();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadLatestChat();
  }

  Future<void> loadLatestChat() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('chat_history') ?? [];
    if (history.isNotEmpty) {
      await loadChat(history.last);
    }
  }

  @override
  void dispose() {
    _userInput.dispose();
    _promptInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveChat,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.8), BlendMode.dstATop),
            image: const NetworkImage('https://static.vecteezy.com/system/resources/previews/001/225/154/non_2x/black-low-poly-geometric-background-vector.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Messages(isUser: message.isUser, message: message.message, date: DateFormat('HH:mm').format(message.date));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _promptInput,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Enter AI Prompt (Default: Plan for Travel)',
                      labelStyle: const TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 15,
                        child: TextFormField(
                          controller: _userInput,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Enter Your Message',
                            labelStyle: const TextStyle(color: Colors.white),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        padding: const EdgeInsets.all(12),
                        iconSize: 30,
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(Colors.black),
                          foregroundColor: WidgetStateProperty.all(Colors.white),
                          shape: WidgetStateProperty.all(const CircleBorder()),
                        ),
                        onPressed: sendMessage,
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<String> chatHistory = [];

  @override
  void initState() {
    super.initState();
    loadChatHistory();
  }

  Future<void> loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      chatHistory = prefs.getStringList('chat_history') ?? [];
    });
  }

  Future<void> loadChat(String chatKey) async {
    final chatScreen = context.findAncestorStateOfType<_ChatScreenState>();
    if (chatScreen != null) {
      await chatScreen.loadChat(chatKey);
      Navigator.of(context).pop(); // Close the history screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat History'),
      ),
      body: ListView.builder(
        itemCount: chatHistory.length,
        itemBuilder: (context, index) {
          final chatKey = chatHistory[index];
          final timestamp = int.parse(chatKey.split('_')[1]);
          final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
          return ListTile(
            title: Text('Chat from ${DateFormat('yyyy-MM-dd HH:mm').format(date)}'),
            onTap: () => loadChat(chatKey),
          );
        },
      ),
    );
  }
}

class Message {
  final bool isUser;
  final String message;
  final DateTime date;

  Message({required this.isUser, required this.message, required this.date});

  Map<String, dynamic> toJson() {
    return {
      'isUser': isUser,
      'message': message,
      'date': date.toIso8601String(),
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      isUser: json['isUser'],
      message: json['message'],
      date: DateTime.parse(json['date']),
    );
  }
}

class Messages extends StatelessWidget {
  final bool isUser;
  final String message;
  final String date;

  const Messages({
    super.key,
    required this.isUser,
    required this.message,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.symmetric(vertical: 15).copyWith(
        left: isUser ? 100 : 10,
        right: isUser ? 10 : 100,
      ),
      decoration: BoxDecoration(
        color: isUser ? Colors.blueAccent : Colors.grey.shade400,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(10),
          bottomLeft: isUser ? const Radius.circular(10) : Radius.zero,
          topRight: const Radius.circular(10),
          bottomRight: isUser ? Radius.zero : const Radius.circular(10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(fontSize: 16, color: isUser ? Colors.white : Colors.black),
          ),
          Text(
            date,
            style: TextStyle(fontSize: 10, color: isUser ? Colors.white : Colors.black),
          ),
        ],
      ),
    );
  }
}