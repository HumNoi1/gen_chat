import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chats.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE chats(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chatId INTEGER NOT NULL,
        isUser INTEGER NOT NULL,
        message TEXT NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (chatId) REFERENCES chats (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> saveChat(String title, List<Message> messages) async {
    final db = await database;
    final chatId = await db.insert('chats', {'title': title, 'date': DateTime.now().toIso8601String()});

    for (var message in messages) {
      await db.insert('messages', {
        'chatId': chatId,
        'isUser': message.isUser ? 1 : 0,
        'message': message.message,
        'date': message.date.toIso8601String(),
      });
    }

    return chatId;
  }

  Future<List<Map<String, dynamic>>> getSavedChats() async {
    final db = await database;
    return db.query('chats', orderBy: 'date DESC');
  }

  Future<List<Message>> getChatMessages(int chatId) async {
    final db = await database;
    final results = await db.query('messages', where: 'chatId = ?', whereArgs: [chatId], orderBy: 'date ASC');
    return results.map((map) => Message(
      isUser: map['isUser'] == 1,
      message: map['message'] as String,
      date: DateTime.parse(map['date'] as String),
    )).toList();
  }

  // เพิ่มเมธอดใหม่เพื่อตรวจสอบการบันทึก
  Future<bool> checkIfChatExists(int chatId) async {
    final db = await database;
    final result = await db.query(
      'chats',
      where: 'id = ?',
      whereArgs: [chatId],
      limit: 1,
    );
    return result.isNotEmpty;
  }
}

class Message {
  final bool isUser;
  final String message;
  final DateTime date;

  Message({required this.isUser, required this.message, required this.date});
}