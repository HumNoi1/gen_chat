import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';
import 'package:gen_chat/message.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
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
  late final GenerativeModel model;
  List<Message> _messages = [];

  @override
  void initState() {
    super.initState();
    model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
  }

  Future<void> sendMessage() async {
    if (_userInput.text.isEmpty) return;

    final userMessage = _userInput.text;
    final prompt = _promptInput.text.isEmpty ? "Plan for Travel" : _promptInput.text;

    final fullPrompt = "$prompt\nUser: $userMessage";

    setState(() {
      _messages.add(Message(isUser: true, message: userMessage, date: DateTime.now()));
    });

    try {
      final content = [Content.text(fullPrompt)];
      final response = await model.generateContent(content);

      setState(() {
        _messages.add(Message(isUser: false, message: response.text ?? "No response", date: DateTime.now()));
      });
    } catch (e) {
      print("Error generating content: $e");
      setState(() {
        _messages.add(Message(isUser: false, message: "Error: Unable to generate response", date: DateTime.now()));
      });
    }

    _userInput.clear();
  }

  Future<void> saveChat() async {
    if (_messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No messages to save')),
      );
      return;
    }

    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Chat'),
        content: TextField(
          decoration: const InputDecoration(hintText: "Enter a title for this chat"),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () => Navigator.of(context).pop(_promptInput.text),
          ),
        ],
      ),
    );

    if (title != null && title.isNotEmpty) {
      try {
        await DatabaseHelper.instance.saveChat(title, _messages);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat saved successfully')),
        );
      } catch (e) {
        print("Error saving chat: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving chat')),
        );
      }
    }
  }

  void viewSavedChats() async {
    try {
      final savedChats = await DatabaseHelper.instance.getSavedChats();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Saved Chats'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300, // Set a fixed height or use MediaQuery for responsiveness
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: savedChats.length,
              itemBuilder: (context, index) {
                final chat = savedChats[index];
                return ListTile(
                  title: Text(chat['title'] as String),
                  subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(chat['date'] as String))),
                  onTap: () async {
                    final messages = await DatabaseHelper.instance.getChatMessages(chat['id'] as int);
                    if (!mounted) return;
                    setState(() {
                      _messages = messages.cast<Message>();
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } catch (e) {
      print("Error viewing saved chats: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading saved chats')),
      );
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
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: viewSavedChats,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.8), BlendMode.dstATop),
            image: const NetworkImage('https://i.pinimg.com/564x/35/bd/1b/35bd1b5d2a5392fea1c42a7b5d25398c.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return MessageWidget(message: message);
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

class Message {
  final bool isUser;
  final String message;
  final DateTime date;

  Message({required this.isUser, required this.message, required this.date});
}

class MessageWidget extends StatelessWidget {
  final Message message;

  const MessageWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      margin: EdgeInsets.only(
        top: 5,
        bottom: 5,
        left: message.isUser ? 100 : 10,
        right: message.isUser ? 10 : 100,
      ),
      decoration: BoxDecoration(
        color: message.isUser ? Colors.blueAccent : Colors.grey.shade400,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(10),
          bottomLeft: message.isUser ? const Radius.circular(10) : Radius.zero,
          topRight: const Radius.circular(10),
          bottomRight: message.isUser ? Radius.zero : const Radius.circular(10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.message,
            style: TextStyle(fontSize: 16, color: message.isUser ? Colors.white : Colors.black),
          ),
          Text(
            DateFormat('HH:mm').format(message.date),
            style: TextStyle(fontSize: 10, color: message.isUser ? Colors.white70 : Colors.black54),
          ),
        ],
      ),
    );
  }
}