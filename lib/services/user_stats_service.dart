import 'package:sqflite/sqflite.dart';
import '../models/user_stats.dart';

/// ユーザー統計情報を管理するサービス
class UserStatsService {
  final Database _database;

  // テーブル名
  static const String _tableName = 'user_stats';

  // シングルトンインスタンス
  static UserStatsService? _instance;

  // 現在のユーザー統計情報（メモリキャッシュ）
  UserStats? _currentUserStats;

  /// UserStatsServiceのインスタンスを取得
  static Future<UserStatsService> getInstance(Database database) async {
    _instance ??= UserStatsService._internal(database);

    // テーブルの存在確認と作成
    await _instance!._ensureTableExists();

    return _instance!;
  }

  // コンストラクタ
  UserStatsService._internal(this._database);

  /// データベースにテーブルが存在することを確認
  Future<void> _ensureTableExists() async {
    await _database.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id INTEGER PRIMARY KEY,
        ai_usage_count INTEGER DEFAULT 0,
        ai_usage_bonus INTEGER DEFAULT 0,
        share_count INTEGER DEFAULT 0,
        last_reset_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  /// 現在のユーザー統計を取得（なければ新規作成）
  Future<UserStats> getUserStats() async {
    // キャッシュがあればそれを返す
    if (_currentUserStats != null) {
      // 月次リセットが必要かチェック
      if (_currentUserStats!.shouldResetMonthlyUsage) {
        _currentUserStats = _currentUserStats!.resetMonthlyUsage();
        await _saveUserStats(_currentUserStats!);
      }
      return _currentUserStats!;
    }

    final List<Map<String, dynamic>> maps = await _database.query(
      _tableName,
      limit: 1,
    );

    if (maps.isNotEmpty) {
      _currentUserStats = UserStats.fromMap(maps.first);

      // 月次リセットが必要かチェック
      if (_currentUserStats!.shouldResetMonthlyUsage) {
        _currentUserStats = _currentUserStats!.resetMonthlyUsage();
        await _saveUserStats(_currentUserStats!);
      }

      return _currentUserStats!;
    }

    // データがなければ新規作成して保存
    final newStats = UserStats();
    await _saveUserStats(newStats);
    _currentUserStats = newStats;
    return newStats;
  }

  /// ユーザー統計情報を保存
  Future<void> _saveUserStats(UserStats stats) async {
    final List<Map<String, dynamic>> maps = await _database.query(
      _tableName,
      limit: 1,
    );

    if (maps.isEmpty) {
      // 新規作成
      await _database.insert(_tableName, stats.toMap());
    } else {
      // 更新
      await _database.update(
        _tableName,
        stats.toMap(),
        where: 'id = ?',
        whereArgs: [maps.first['id']],
      );
    }
  }

  /// AI使用回数を増加
  Future<UserStats> incrementAIUsage() async {
    final stats = await getUserStats();

    // 使用可能回数がない場合はそのまま返す
    if (!stats.canUseAI) {
      return stats;
    }

    final updated = stats.incrementUsage();
    _currentUserStats = updated;
    await _saveUserStats(updated);
    return updated;
  }

  /// SNSシェアボーナスを追加
  Future<UserStats> addShareBonus() async {
    final stats = await getUserStats();
    final updated = stats.addShareBonus();
    _currentUserStats = updated;
    await _saveUserStats(updated);
    return updated;
  }
}
