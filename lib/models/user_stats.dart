import 'dart:convert';

/// ユーザー統計情報を管理するモデル
class UserStats {
  /// 月ごとのAI使用回数
  final int aiUsageCount;

  /// AI使用回数の追加ポイント（SNSシェアなどで獲得）
  final int aiUsageBonus;

  /// SNSシェア回数
  final int shareCount;

  /// 最後にリセットされた日時
  final DateTime lastResetDate;

  /// 作成日時
  final DateTime createdAt;

  /// 更新日時
  final DateTime updatedAt;

  /// 1ヶ月あたりの基本AI使用回数制限
  static const int monthlyUsageLimit = 10;

  /// SNSシェアで獲得できるボーナス回数
  static const int shareBonus = 100;

  UserStats({
    this.aiUsageCount = 0,
    this.aiUsageBonus = 0,
    this.shareCount = 0,
    DateTime? lastResetDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : lastResetDate = lastResetDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 残りのAI使用可能回数を取得
  int get remainingUsage {
    // 基本制限 + ボーナス - 使用回数
    final remaining = monthlyUsageLimit + aiUsageBonus - aiUsageCount;
    return remaining < 0 ? 0 : remaining;
  }

  /// AIを使用できるかどうかチェック
  bool get canUseAI => remainingUsage > 0;

  /// 新しい月になったかチェック
  bool get shouldResetMonthlyUsage {
    final now = DateTime.now();
    return now.year > lastResetDate.year ||
        (now.year == lastResetDate.year && now.month > lastResetDate.month);
  }

  /// AIを1回使用した後の新しいUserStats
  UserStats incrementUsage() {
    return copyWith(
      aiUsageCount: aiUsageCount + 1,
      updatedAt: DateTime.now(),
    );
  }

  /// SNSシェア後の新しいUserStats
  UserStats addShareBonus() {
    return copyWith(
      aiUsageBonus: aiUsageBonus + shareBonus,
      shareCount: shareCount + 1,
      updatedAt: DateTime.now(),
    );
  }

  /// 月次リセット処理
  UserStats resetMonthlyUsage() {
    if (shouldResetMonthlyUsage) {
      return copyWith(
        aiUsageCount: 0,
        lastResetDate: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    return this;
  }

  /// コピーを作成するファクトリメソッド
  UserStats copyWith({
    int? aiUsageCount,
    int? aiUsageBonus,
    int? shareCount,
    DateTime? lastResetDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserStats(
      aiUsageCount: aiUsageCount ?? this.aiUsageCount,
      aiUsageBonus: aiUsageBonus ?? this.aiUsageBonus,
      shareCount: shareCount ?? this.shareCount,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Mapに変換するメソッド (データベース保存用)
  Map<String, dynamic> toMap() {
    return {
      'ai_usage_count': aiUsageCount,
      'ai_usage_bonus': aiUsageBonus,
      'share_count': shareCount,
      'last_reset_date': lastResetDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// MapからUserStatsを作成するファクトリメソッド (データベース読み込み用)
  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      aiUsageCount: map['ai_usage_count'] as int,
      aiUsageBonus: map['ai_usage_bonus'] as int,
      shareCount: map['share_count'] as int,
      lastResetDate: DateTime.parse(map['last_reset_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// JSONに変換
  String toJson() => jsonEncode(toMap());

  /// JSONからUserStatsを作成
  factory UserStats.fromJson(String source) => UserStats.fromMap(
        jsonDecode(source) as Map<String, dynamic>,
      );

  @override
  String toString() {
    return 'UserStats(aiUsageCount: $aiUsageCount, aiUsageBonus: $aiUsageBonus, shareCount: $shareCount, lastResetDate: $lastResetDate, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
