# データベースマイグレーションガイド

## 問題：初期ルートとデータベースマイグレーションの不整合

### 発生した問題
1. 初期ルートが`onboarding`に設定されているにもかかわらず、`onboarding_screen.dart`の69行目で`home`に遷移させても、すぐに`onboarding`に戻ってしまう問題が発生
2. データベース操作時に以下のエラーが発生：
```
DatabaseException(table ideas has no column named is_deleted (code 1 SQLITE_ERROR))
```

### 原因
1. データベースのスキーマと実際のテーブル構造に不一致があった：
   - `_onCreate`メソッドで作成される`ideas`テーブルに`is_deleted`カラムが定義されていない
   - しかし、`Idea`モデルと`softDeleteIdea`メソッドでは`is_deleted`カラムを使用しようとしていた

2. テーブル定義：
```sql
-- 現在のテーブル定義
CREATE TABLE ideas(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  content TEXT NOT NULL,
  parent_id INTEGER,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  tags TEXT
)
```

### 解決策
1. データベースのバージョンを4に更新
2. `is_deleted`カラムを追加するマイグレーションを実装

```dart
Future<Database> _initDatabase() async {
  return await openDatabase(
    dbPath,
    version: 4, // バージョンを4に更新
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
  );
}

Future<void> _upgradeV3ToV4(Transaction txn) async {
  debugPrint('V3 → V4: is_deletedカラムを追加');
  
  // is_deletedカラムを追加
  await txn.execute('''
    ALTER TABLE ideas 
    ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0
  ''');

  // インデックスを作成
  await txn.execute(
    'CREATE INDEX IF NOT EXISTS idx_ideas_is_deleted ON ideas (is_deleted)',
  );
}
```

### マイグレーション実行手順
1. アプリを完全に停止
2. データベースファイルを削除（新規作成されます）
3. アプリを再起動

### ベストプラクティス
1. データベースの変更は必ずバージョン管理する
2. マイグレーションは下位バージョンとの互換性を保つ
3. テーブル定義の変更は必ずマイグレーションスクリプトとして記録
4. 各マイグレーションは独立した関数として実装し、管理を容易にする
5. マイグレーション実行前後でデータの整合性を確認

### 注意点
1. 本番環境でのマイグレーション実行時は、ユーザーデータのバックアップを取得
2. マイグレーション失敗時のロールバック処理を実装
3. 大規模なデータを扱う場合は、バッチ処理でマイグレーションを実行

### 関連するファイル
- `database_service.dart`: データベースサービスの実装
- `idea.dart`: アイデアモデルの定義
- `onboarding_screen.dart`: オンボーディング画面の実装

### 参考リンク
- [SQLite Documentation](https://www.sqlite.org/docs.html)
- [sqflite package](https://pub.dev/packages/sqflite)
- [Flutter Database Guide](https://flutter.dev/docs/cookbook/persistence/sqlite) 