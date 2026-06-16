import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'encryption_helper.dart';
import 'attachment_helper.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDb();
    return _database!;
  }

  static Future<Database> initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'auremind_local.db');

    return await openDatabase(
      path,
      version: 2, // Incremented version for the schema update
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            encrypted_content TEXT,
            attachment_path TEXT,
            attachment_name TEXT,
            created_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            due_date TEXT,
            created_at TEXT,
            is_completed INTEGER DEFAULT 0,
            reminder_minutes INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE tasks ADD COLUMN is_completed INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE tasks ADD COLUMN reminder_minutes INTEGER DEFAULT 0');
        }
      },
    );
  }

  static Future<int> saveNoteToLocalDevice({required String title, required String body, AttachmentResult? attachment}) async {
    final db = await database;
    String securedContent = EncryptionHelper.encryptText(body);
    Map<String, dynamic> noteRow = {
      'title': title,
      'encrypted_content': securedContent,
      'attachment_path': attachment?.localPath ?? '',
      'attachment_name': attachment?.originalName ?? '',
      'created_at': DateTime.now().toIso8601String(),
    };
    return await db.insert('notes', noteRow);
  }

  static Future<List<Map<String, dynamic>>> fetchAllNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notes', orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) {
      var note = Map<String, dynamic>.from(maps[i]);
      note['decrypted_content'] = EncryptionHelper.decryptText(note['encrypted_content']);
      return note;
    });
  }

  static Future<int> saveTask(String title, DateTime dueDate, int reminderMinutes) async {
    final db = await database;
    Map<String, dynamic> taskRow = {
      'title': title,
      'due_date': dueDate.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'is_completed': 0,
      'reminder_minutes': reminderMinutes,
    };
    return await db.insert('tasks', taskRow);
  }

  static Future<List<Map<String, dynamic>>> fetchAllTasks() async {
    final db = await database;
    return await db.query('tasks', orderBy: 'due_date ASC');
  }

  static Future<int> updateTaskStatus(int id, int isCompleted) async {
    final db = await database;
    return await db.update('tasks', {'is_completed': isCompleted}, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteNotes(List<int> ids) async {
    final db = await database;
    if (ids.isEmpty) return 0;
    return await db.delete('notes', where: 'id IN (${ids.join(',')})');
  }

  static Future<int> deleteTasks(List<int> ids) async {
    final db = await database;
    if (ids.isEmpty) return 0;
    return await db.delete('tasks', where: 'id IN (${ids.join(',')})');
  }
}