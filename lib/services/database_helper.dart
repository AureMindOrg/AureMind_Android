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
      version: 4, 
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE notes (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, encrypted_content TEXT, attachment_path TEXT, attachment_name TEXT, created_at TEXT)');
        await db.execute('CREATE TABLE tasks (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, due_date TEXT, created_at TEXT, is_completed INTEGER DEFAULT 0, reminder_minutes INTEGER DEFAULT 0)');
        await db.execute('CREATE TABLE events (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, description TEXT, event_date TEXT, created_at TEXT)');
        await db.execute('CREATE TABLE timetables (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, start_date TEXT, end_date TEXT, created_at TEXT)');
        await db.execute('CREATE TABLE timetable_entries (id INTEGER PRIMARY KEY AUTOINCREMENT, timetable_id INTEGER, day_of_week INTEGER, start_time TEXT, end_time TEXT, subject TEXT, FOREIGN KEY (timetable_id) REFERENCES timetables (id) ON DELETE CASCADE)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE tasks ADD COLUMN is_completed INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE tasks ADD COLUMN reminder_minutes INTEGER DEFAULT 0');
        }
        if (oldVersion < 3) {
          await db.execute('CREATE TABLE events (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, description TEXT, event_date TEXT, created_at TEXT)');
          await db.execute('CREATE TABLE timetables (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, end_date TEXT, created_at TEXT)');
          await db.execute('CREATE TABLE timetable_entries (id INTEGER PRIMARY KEY AUTOINCREMENT, timetable_id INTEGER, day_of_week INTEGER, start_time TEXT, end_time TEXT, subject TEXT, FOREIGN KEY (timetable_id) REFERENCES timetables (id) ON DELETE CASCADE)');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE timetables ADD COLUMN start_date TEXT');
        }
      },
    );
  }

  // --- NOTES METHODS ---
  static Future<int> saveNoteToLocalDevice({required String title, required String body, AttachmentResult? attachment}) async {
    final db = await database;
    String securedContent = EncryptionHelper.encryptText(body);
    return await db.insert('notes', {'title': title, 'encrypted_content': securedContent, 'attachment_path': attachment?.localPath ?? '', 'attachment_name': attachment?.originalName ?? '', 'created_at': DateTime.now().toIso8601String()});
  }
  
  // NEW: Update an existing note
  static Future<int> updateNote(int id, String title, String body) async {
    final db = await database;
    String securedContent = EncryptionHelper.encryptText(body);
    return await db.update('notes', {
      'title': title,
      'encrypted_content': securedContent,
    }, where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> fetchAllNotes() async {
    final db = await database;
    final maps = await db.query('notes', orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) {
      var note = Map<String, dynamic>.from(maps[i]);
      note['decrypted_content'] = EncryptionHelper.decryptText(note['encrypted_content']);
      return note;
    });
  }
  static Future<int> deleteNotes(List<int> ids) async {
    final db = await database;
    if (ids.isEmpty) return 0;
    return await db.delete('notes', where: 'id IN (${ids.join(',')})');
  }

  // --- TASKS METHODS ---
  static Future<int> saveTask(String title, DateTime dueDate, int reminderMinutes) async {
    final db = await database;
    return await db.insert('tasks', {'title': title, 'due_date': dueDate.toIso8601String(), 'created_at': DateTime.now().toIso8601String(), 'is_completed': 0, 'reminder_minutes': reminderMinutes});
  }
  static Future<List<Map<String, dynamic>>> fetchAllTasks() async {
    final db = await database;
    return await db.query('tasks', orderBy: 'due_date ASC');
  }
  static Future<int> updateTaskStatus(int id, int isCompleted) async {
    final db = await database;
    return await db.update('tasks', {'is_completed': isCompleted}, where: 'id = ?', whereArgs: [id]);
  }
  static Future<int> deleteTasks(List<int> ids) async {
    final db = await database;
    if (ids.isEmpty) return 0;
    return await db.delete('tasks', where: 'id IN (${ids.join(',')})');
  }

  // --- EVENTS METHODS ---
  static Future<int> saveEvent(String title, String description, DateTime eventDate) async {
    final db = await database;
    return await db.insert('events', {'title': title, 'description': description, 'event_date': eventDate.toIso8601String(), 'created_at': DateTime.now().toIso8601String()});
  }
  static Future<List<Map<String, dynamic>>> fetchAllEvents() async {
    final db = await database;
    return await db.query('events', orderBy: 'event_date ASC');
  }
  static Future<int> deleteEvents(List<int> ids) async {
    final db = await database;
    if (ids.isEmpty) return 0;
    return await db.delete('events', where: 'id IN (${ids.join(',')})');
  }

  // --- TIMETABLE METHODS ---
  static Future<int> saveTimetable(String title, DateTime startDate, DateTime endDate) async {
    final db = await database;
    return await db.insert('timetables', {'title': title, 'start_date': startDate.toIso8601String(), 'end_date': endDate.toIso8601String(), 'created_at': DateTime.now().toIso8601String()});
  }
  static Future<List<Map<String, dynamic>>> fetchTimetables() async {
    final db = await database;
    return await db.query('timetables', orderBy: 'start_date ASC');
  }
  static Future<int> deleteTimetables(List<int> ids) async {
    final db = await database;
    if (ids.isEmpty) return 0;
    return await db.delete('timetables', where: 'id IN (${ids.join(',')})');
  }
  static Future<int> saveTimetableEntry(int timetableId, int dayOfWeek, String subject, String startTime, String endTime) async {
    final db = await database;
    return await db.insert('timetable_entries', {'timetable_id': timetableId, 'day_of_week': dayOfWeek, 'subject': subject, 'start_time': startTime, 'end_time': endTime});
  }
  static Future<List<Map<String, dynamic>>> fetchTimetableEntries(int timetableId) async {
    final db = await database;
    return await db.query('timetable_entries', where: 'timetable_id = ?', whereArgs: [timetableId], orderBy: 'start_time ASC');
  }
  static Future<int> deleteTimetableEntry(int id) async {
    final db = await database;
    return await db.delete('timetable_entries', where: 'id = ?', whereArgs: [id]);
  }
}