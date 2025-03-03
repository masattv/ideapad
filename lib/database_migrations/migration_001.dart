import 'package:sqflite/sqflite.dart';

class Migration001 {
  static Future<void> migrate(Database db) async {
    // アイデアテーブルの作成
    await db.execute('''
    CREATE TABLE IF NOT EXISTS ideas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      content TEXT NOT NULL,
      parent_id INTEGER NULL,
      tags TEXT DEFAULT '[]',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      is_deleted INTEGER DEFAULT 0,
      FOREIGN KEY (parent_id) REFERENCES ideas (id) ON DELETE SET NULL
    )
    ''');

    // AI組み合わせテーブルの作成
    await db.execute('''
    CREATE TABLE IF NOT EXISTS ai_combinations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      idea_ids TEXT NOT NULL,
      combined_content TEXT NOT NULL,
      reasoning TEXT NULL,
      created_at TEXT NOT NULL,
      is_favorite INTEGER DEFAULT 0,
      idea_a TEXT NULL,
      idea_b TEXT NULL
    )
    ''');

    // インデックスの作成
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ideas_parent_id ON ideas (parent_id)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ideas_is_deleted ON ideas (is_deleted)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ai_combinations_is_favorite ON ai_combinations (is_favorite)',
    );
  }
}
