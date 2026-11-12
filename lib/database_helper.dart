import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// ─── Модель привычки ───
class Habit {
  final int? id;
  final String name;
  final String description;

  Habit({this.id, required this.name, this.description = ''});

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
      };

  factory Habit.fromMap(Map<String, dynamic> map) => Habit(
        id: map['id'] as int?,
        name: map['name'] as String,
        description: map['description'] as String? ?? '',
      );
}

/// Форматирует дату в строку `ГГГГ-ММ-ДД` (ключ для отметок выполнения).
String formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

// ─── Помощник для работы с БД ───
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('habits.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Таблица привычек
    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT ''
      )
    ''');

    // Таблица отметок выполнения
    await db.execute('''
      CREATE TABLE completions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');
  }

  // ─── CRUD для привычек ───
  Future<int> createHabit(Habit habit) async {
    final db = await database;
    return await db.insert('habits', habit.toMap());
  }

  Future<List<Habit>> getAllHabits() async {
    final db = await database;
    final maps = await db.query('habits', orderBy: 'id ASC');
    return maps.map((map) => Habit.fromMap(map)).toList();
  }

  Future<int> updateHabit(Habit habit) async {
    final db = await database;
    return await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<int> deleteHabit(int id) async {
    final db = await database;
    await db.delete('completions', where: 'habit_id = ?', whereArgs: [id]);
    return await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Отметки выполнения ───
  Future<void> toggleCompletion(int habitId, String date) async {
    final db = await database;
    final existing = await db.query(
      'completions',
      where: 'habit_id = ? AND date = ?',
      whereArgs: [habitId, date],
    );

    if (existing.isNotEmpty) {
      await db.delete(
        'completions',
        where: 'habit_id = ? AND date = ?',
        whereArgs: [habitId, date],
      );
    } else {
      await db.insert('completions', {'habit_id': habitId, 'date': date});
    }
  }

  Future<bool> isCompleted(int habitId, String date) async {
    final db = await database;
    final result = await db.query(
      'completions',
      where: 'habit_id = ? AND date = ?',
      whereArgs: [habitId, date],
    );
    return result.isNotEmpty;
  }

  // Статистика за 7 дней: {дата: количество выполнений}
  Future<Map<String, int>> getWeeklyStats() async {
    final db = await database;
    final now = DateTime.now();
    final result = <String, int>{};

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = formatDate(date);
      final count = await db.rawQuery(
        'SELECT COUNT(*) as count FROM completions WHERE date = ?',
        [dateStr],
      );
      result[dateStr] = (count.first['count'] as int?) ?? 0;
    }
    return result;
  }
}