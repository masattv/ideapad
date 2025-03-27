import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:idea_app/models/idea.dart';
import 'package:idea_app/models/idea_combination.dart';
import 'package:idea_app/models/ai_combination.dart';
import '../database_migrations/migration_001.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  // データベースの初期化
  Future<Database> _initDatabase() async {
    try {
      // プラットフォーム固有のデータベースディレクトリを取得
      final dbDir = await getDatabasesPath();
      final dbName = dotenv.env['DB_NAME'] ?? 'ideapad.db';
      final dbPath = join(dbDir, dbName);

      debugPrint('データベースを初期化: $dbPath');

      // データベースを開く（存在しない場合は作成）
      return await openDatabase(
        dbPath,
        version: 4,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      debugPrint('データベース初期化エラー: $e');
      rethrow; // エラーを再スロー
    }
  }

  // テーブル作成
  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      // ideasテーブル作成
      await txn.execute('''
        CREATE TABLE ideas(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          content TEXT NOT NULL,
          parent_id INTEGER,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          tags TEXT,
          is_deleted INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // ai_combinationsテーブル作成
      await txn.execute('''
        CREATE TABLE ai_combinations(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          idea_ids TEXT NOT NULL,
          combined_content TEXT NOT NULL,
          reasoning TEXT,
          created_at TEXT NOT NULL,
          is_favorite INTEGER NOT NULL DEFAULT 0,
          idea_a TEXT,
          idea_b TEXT
        )
      ''');

      // user_statsテーブル作成
      await txn.execute('''
        CREATE TABLE user_stats(
          id INTEGER PRIMARY KEY CHECK (id = 1),
          ai_usage_count INTEGER NOT NULL DEFAULT 0,
          ai_usage_bonus INTEGER NOT NULL DEFAULT 0,
          share_count INTEGER NOT NULL DEFAULT 0,
          last_reset_date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // categoriesテーブル作成
      await txn.execute('''
        CREATE TABLE categories(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          created_at TEXT NOT NULL
        )
      ''');

      // 初期データの挿入
      await _insertInitialData(txn);

      // インデックスを作成
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_ideas_is_deleted ON ideas (is_deleted)',
      );
    });

    debugPrint('データベースを作成しました（バージョン$version）');
  }

  // DBアップグレード
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('データベースをアップグレード: $oldVersion → $newVersion');

    await db.transaction((txn) async {
      // バージョン1から2へのアップグレード
      if (oldVersion < 2) {
        await _upgradeV1ToV2(txn);
      }

      // バージョン2から3へのアップグレード
      if (oldVersion < 3) {
        await _upgradeV2ToV3(txn);
      }

      // バージョン3から4へのアップグレード
      if (oldVersion < 4) {
        await _upgradeV3ToV4(txn);
      }
    });
  }

  Future<void> _upgradeV3ToV4(Transaction txn) async {
    debugPrint('V3 → V4: is_deletedカラムを追加');

    try {
      // is_deletedカラムを追加
      await txn.execute('''
        ALTER TABLE ideas 
        ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0
      ''');
    } catch (e) {
      debugPrint('is_deletedカラムは既に存在します: $e');
      // カラムが既に存在する場合は無視
    }

    try {
      // インデックスを作成（IF NOT EXISTSがあるので安全）
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_ideas_is_deleted ON ideas (is_deleted)',
      );
    } catch (e) {
      debugPrint('インデックス作成エラー: $e');
      rethrow;
    }
  }

  Future<void> _upgradeV1ToV2(Transaction txn) async {
    // user_statsテーブル追加
    await txn.execute('''
      CREATE TABLE IF NOT EXISTS user_stats(
        id INTEGER PRIMARY KEY CHECK (id = 1),
        ai_usage_count INTEGER NOT NULL DEFAULT 0,
        ai_usage_bonus INTEGER NOT NULL DEFAULT 0,
        share_count INTEGER NOT NULL DEFAULT 0,
        last_reset_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // user_statsテーブルに既存のデータがあるか確認
    final existingStats = await txn.query('user_stats', where: 'id = 1');
    if (existingStats.isEmpty) {
      // 初期ユーザー統計データ挿入
      final now = DateTime.now().toIso8601String();
      await txn.insert('user_stats', {
        'id': 1,
        'ai_usage_count': 0,
        'ai_usage_bonus': 0,
        'share_count': 0,
        'last_reset_date': now,
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  Future<void> _upgradeV2ToV3(Transaction txn) async {
    // categoriesテーブル追加
    await txn.execute('''
      CREATE TABLE IF NOT EXISTS categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');

    // 初期カテゴリを追加
    final now = DateTime.now().toIso8601String();
    final initialCategories = [
      'ビジネス',
      'テクノロジー',
      'アート',
      'ライフスタイル',
      '教育',
    ];

    for (final category in initialCategories) {
      await txn.insert('categories', {
        'name': category,
        'created_at': now,
      });
    }
  }

  // 初期データの挿入
  Future<void> _insertInitialData(Transaction txn) async {
    final now = DateTime.now().toIso8601String();

    // 初期カテゴリを追加
    final initialCategories = [
      'ビジネス',
      'テクノロジー',
      'アート',
      'ライフスタイル',
      '教育',
    ];

    for (final category in initialCategories) {
      await txn.insert('categories', {
        'name': category,
        'created_at': now,
      });
    }

    // user_statsテーブルに既存のデータがあるか確認
    final existingStats = await txn.query('user_stats', where: 'id = 1');
    if (existingStats.isEmpty) {
      // 初期ユーザー統計データ
      await txn.insert('user_stats', {
        'id': 1,
        'ai_usage_count': 0,
        'ai_usage_bonus': 0,
        'share_count': 0,
        'last_reset_date': now,
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  // アイデア関連の操作 ------------------------

  // アイデアの追加
  Future<int> insertIdea(Idea idea) async {
    final db = await database;
    final map = idea.toMap();
    debugPrint('アイデアを追加: $map');
    try {
      return await db.insert('ideas', map);
    } catch (e) {
      debugPrint('アイデア追加エラー: $e');
      rethrow;
    }
  }

  // アイデアの取得（全件、削除されていないもののみ）
  Future<List<Idea>> getAllIdeas() async {
    final db = await database;
    final results = await db.query(
      'ideas',
      orderBy: 'updated_at DESC',
    );

    return results.map((map) => Idea.fromMap(map)).toList();
  }

  // アイデアの取得（ID指定）
  Future<Idea?> getIdea(int id) async {
    final db = await database;
    final results = await db.query(
      'ideas',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return Idea.fromMap(results.first);
  }

  // 親アイデアに対する子アイデアの取得
  Future<List<Idea>> getChildIdeas(int parentId) async {
    final db = await database;
    final results = await db.query(
      'ideas',
      where: 'parent_id = ?',
      whereArgs: [parentId],
      orderBy: 'updated_at DESC',
    );

    return results.map((map) => Idea.fromMap(map)).toList();
  }

  // ルートアイデア（親がない）の取得
  Future<List<Idea>> getRootIdeas() async {
    final db = await database;
    final results = await db.query(
      'ideas',
      where: 'parent_id IS NULL',
      orderBy: 'updated_at DESC',
    );

    return results.map((map) => Idea.fromMap(map)).toList();
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
    final results = await db.query(
      'idea_combinations',
      orderBy: 'created_at DESC',
    );

    return results.map((map) => IdeaCombination.fromMap(map)).toList();
  }

  // お気に入りのアイデア組み合わせのみ取得
  Future<List<IdeaCombination>> getFavoriteIdeaCombinations() async {
    final db = await database;
    final results = await db.query(
      'idea_combinations',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );

    return results.map((map) => IdeaCombination.fromMap(map)).toList();
  }

  // アイデア組み合わせの取得（ID指定）
  Future<IdeaCombination?> getIdeaCombination(int id) async {
    final db = await database;
    final results = await db.query(
      'idea_combinations',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return IdeaCombination.fromMap(results.first);
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
    final results = await db.query(
      'ai_combinations',
      orderBy: 'created_at DESC',
    );

    return results.map((map) => AICombination.fromMap(map)).toList();
  }

  // お気に入りのAI組み合わせのみ取得
  Future<List<AICombination>> getFavoriteAICombinations() async {
    final db = await database;
    final results = await db.query(
      'ai_combinations',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );

    return results.map((map) => AICombination.fromMap(map)).toList();
  }

  // AI組み合わせの取得（ID指定）
  Future<AICombination?> getAICombination(int id) async {
    final db = await database;
    final results = await db.query(
      'ai_combinations',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return AICombination.fromMap(results.first);
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

  // カテゴリ関連の操作 ------------------------

  // 全てのカテゴリを取得
  Future<List<String>> getAllCategories() async {
    final db = await database;
    final results = await db.query(
      'categories',
      columns: ['name'],
      orderBy: 'name',
    );

    return results.map((map) => map['name'] as String).toList();
  }

  // カテゴリを追加
  Future<int> addCategory(String categoryName) async {
    final trimmedName = categoryName.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('カテゴリ名は空にできません');
    }

    // 重複チェック
    final db = await database;
    final existing = await db.query(
      'categories',
      where: 'name = ?',
      whereArgs: [trimmedName],
    );

    if (existing.isNotEmpty) {
      throw ArgumentError('カテゴリ「$trimmedName」は既に存在します');
    }

    // 新規カテゴリを追加
    return await db.insert('categories', {
      'name': trimmedName,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // カテゴリを削除
  Future<int> deleteCategory(String categoryName) async {
    final db = await database;
    return await db.delete(
      'categories',
      where: 'name = ?',
      whereArgs: [categoryName],
    );
  }

  // カテゴリ名を更新
  Future<int> updateCategory(String oldName, String newName) async {
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('カテゴリ名は空にできません');
    }

    // 重複チェック（自分自身を除く）
    final db = await database;
    final existing = await db.query(
      'categories',
      where: 'name = ? AND name != ?',
      whereArgs: [trimmedName, oldName],
    );

    if (existing.isNotEmpty) {
      throw ArgumentError('カテゴリ「$trimmedName」は既に存在します');
    }

    // カテゴリ名を更新
    return await db.update(
      'categories',
      {'name': trimmedName},
      where: 'name = ?',
      whereArgs: [oldName],
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
