import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:idea_app/models/idea.dart';
import 'package:idea_app/models/idea_combination.dart';
import 'package:idea_app/models/ai_combination.dart';
import '../database_migrations/migration_001.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  // シングルトンパターン
  factory DatabaseService() => _instance;

  DatabaseService._internal();

  // データベースの取得
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // データベースの初期化 (近藤Q このあたりでDBファイルの設定をしていて個々の設定を使ってるからmainでのDB準備は重複しているように見える)
  Future<Database> _initDatabase() async {
    String path = await getDatabasesPath();
    String dbPath = join(path, 'ideapad.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async { // 近藤Q Migration001.migrate(db)でtableをCreateしてるが下記の_onCreate（）はいつ使うのか？
        await Migration001.migrate(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        // 将来のマイグレーションに備えて
        if (oldVersion < 1) {
          await Migration001.migrate(db);
        }
      },
    );
  }

  // テーブル作成
  Future<void> _onCreate(Database db, int version) async {
    // アイデアテーブル
    await db.execute('''
      CREATE TABLE ideas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        tags TEXT,
        parent_id INTEGER,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // アイデア組み合わせテーブル
    await db.execute('''
      CREATE TABLE idea_combinations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idea_ids TEXT NOT NULL,
        combined_content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // AI組み合わせテーブル
    await db.execute('''
      CREATE TABLE ai_combinations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idea_ids TEXT NOT NULL,
        combined_content TEXT NOT NULL,
        reasoning TEXT,
        created_at TEXT NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // DBアップグレード
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion == 1 && newVersion == 2) {
      // ideas テーブルの変更
      await db.execute('ALTER TABLE ideas ADD COLUMN parent_id INTEGER');
      await db.execute(
          'ALTER TABLE ideas ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0');

      // ai_combinations テーブルの作成
      await db.execute('''
        CREATE TABLE ai_combinations(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          idea_ids TEXT NOT NULL,
          combined_content TEXT NOT NULL,
          reasoning TEXT,
          created_at TEXT NOT NULL,
          is_favorite INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
  }

  // アイデア関連の操作 ------------------------

  // アイデアの追加
  Future<int> insertIdea(Idea idea) async {
    final db = await database;
    return await db.insert('ideas', idea.toMap());
  }

  // アイデアの取得（全件、削除されていないもののみ）
  Future<List<Idea>> getAllIdeas() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ideas',
      where: 'is_deleted = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Idea.fromMap(maps[i]));
  }

  // アイデアの取得（ID指定）
  Future<Idea?> getIdea(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ideas',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Idea.fromMap(maps.first);
    }
    return null;
  }

  // 親アイデアに対する子アイデアの取得
  Future<List<Idea>> getChildIdeas(int parentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ideas',
      where: 'parent_id = ? AND is_deleted = ?',
      whereArgs: [parentId, 0],
      orderBy: 'created_at ASC',
    );
    return List.generate(maps.length, (i) => Idea.fromMap(maps[i]));
  }

  // ルートアイデア（親がない）の取得
  Future<List<Idea>> getRootIdeas() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ideas',
      where: 'parent_id IS NULL AND is_deleted = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Idea.fromMap(maps[i]));
  }

  // アイデアの更新
  Future<int> updateIdea(Idea idea) async {
    final db = await database;
    return await db.update(
      'ideas',
      idea.toMap(),
      where: 'id = ?',
      whereArgs: [idea.id],
    );
  }

  // アイデアの論理削除
  Future<int> softDeleteIdea(int id) async {
    final db = await database;
    return await db.update(
      'ideas',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // アイデアの削除
  Future<int> deleteIdea(int id) async {
    final db = await database;
    return await db.delete(
      'ideas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // アイデア組み合わせ関連の操作 ------------------------

  // アイデア組み合わせの追加
  Future<int> insertIdeaCombination(IdeaCombination combination) async {
    final db = await database;
    return await db.insert('idea_combinations', combination.toMap());
  }

  // アイデア組み合わせの取得（全件）
  Future<List<IdeaCombination>> getAllIdeaCombinations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'idea_combinations',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => IdeaCombination.fromMap(maps[i]));
  }

  // お気に入りのアイデア組み合わせのみ取得
  Future<List<IdeaCombination>> getFavoriteIdeaCombinations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'idea_combinations',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => IdeaCombination.fromMap(maps[i]));
  }

  // アイデア組み合わせの取得（ID指定）
  Future<IdeaCombination?> getIdeaCombination(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'idea_combinations',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return IdeaCombination.fromMap(maps.first);
    }
    return null;
  }

  // アイデア組み合わせの更新
  Future<int> updateIdeaCombination(IdeaCombination combination) async {
    final db = await database;
    return await db.update(
      'idea_combinations',
      combination.toMap(),
      where: 'id = ?',
      whereArgs: [combination.id],
    );
  }

  // アイデア組み合わせの削除
  Future<int> deleteIdeaCombination(int id) async {
    final db = await database;
    return await db.delete(
      'idea_combinations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // AI組み合わせ関連の操作 ------------------------

  // AI組み合わせの追加
  Future<int> insertAICombination(AICombination combination) async {
    final db = await database;
    return await db.insert('ai_combinations', combination.toMap());
  }

  // AI組み合わせの取得（全件）
  Future<List<AICombination>> getAllAICombinations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ai_combinations',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => AICombination.fromMap(maps[i]));
  }

  // お気に入りのAI組み合わせのみ取得
  Future<List<AICombination>> getFavoriteAICombinations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ai_combinations',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => AICombination.fromMap(maps[i]));
  }

  // AI組み合わせの取得（ID指定）
  Future<AICombination?> getAICombination(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ai_combinations',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return AICombination.fromMap(maps.first);
    }
    return null;
  }

  // AI組み合わせの更新
  Future<int> updateAICombination(AICombination combination) async {
    final db = await database;
    return await db.update(
      'ai_combinations',
      combination.toMap(),
      where: 'id = ?',
      whereArgs: [combination.id],
    );
  }

  // AI組み合わせの削除
  Future<int> deleteAICombination(int id) async {
    final db = await database;
    return await db.delete(
      'ai_combinations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // データベースの閉じる
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
