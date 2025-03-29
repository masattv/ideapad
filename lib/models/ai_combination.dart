import 'dart:convert';
import 'idea.dart';

class AICombination {
  final int? id;
  final List<int> ideaIds;
  final String combinedContent;
  final String? reasoning; // AI推論プロセス
  final DateTime createdAt;
  final bool isFavorite;

  // オリジナルアイデアの参照
  final Idea? _ideaA;
  final Idea? _ideaB;

  // ゲッター
  Idea? get ideaA => _ideaA;
  Idea? get ideaB => _ideaB;
  String get generatedIdea => combinedContent;

  // AICombinationクラスのコンストラクタ
  // パラメータ:
  // - id: 組み合わせの一意のID (オプション)
  // - ideaIds: 組み合わせに使用されたアイデアのIDリスト (必須)
  // - combinedContent: AIによって生成された組み合わせ内容 (必須)
  // - reasoning: AIの推論プロセスの説明 (オプション)
  // - createdAt: 作成日時 (オプション、指定がない場合は現在時刻)
  // - isFavorite: お気に入り状態 (デフォルトはfalse)
  // - ideaA: 1つ目の元となるアイデア (オプション)
  // - ideaB: 2つ目の元となるアイデア (オプション)
  AICombination({
    this.id,
    required this.ideaIds,
    required this.combinedContent,
    this.reasoning,
    DateTime? createdAt,
    this.isFavorite = false,
    Idea? ideaA,
    Idea? ideaB,
  })  : createdAt = createdAt ?? DateTime.now(), // createdAtが指定されていない場合は現在時刻を設定
        _ideaA = ideaA, // プライベートフィールドに元のアイデアを保存
        _ideaB = ideaB; // プライベートフィールドに元のアイデアを保存

  // 既存の組み合わせを更新するためのメソッド
  AICombination copyWith({
    int? id,
    List<int>? ideaIds,
    String? combinedContent,
    String? reasoning,
    DateTime? createdAt,
    bool? isFavorite,
    Idea? ideaA,
    Idea? ideaB,
  }) {
    return AICombination(
      id: id ?? this.id,
      ideaIds: ideaIds ?? this.ideaIds,
      combinedContent: combinedContent ?? this.combinedContent,
      reasoning: reasoning ?? this.reasoning,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      ideaA: ideaA ?? _ideaA,
      ideaB: ideaB ?? _ideaB,
    );
  }

  // JSONからのデシリアライズ
  factory AICombination.fromMap(Map<String, dynamic> map) {
    List<int> parseIdeaIds(dynamic ideaIdsData) {
      if (ideaIdsData == null) return [];
      if (ideaIdsData is String) {
        try {
          final List<dynamic> parsed = jsonDecode(ideaIdsData);
          return parsed.map((id) => id as int).toList();
        } catch (e) {
          return [];
        }
      }
      return [];
    }

    // ideaA と ideaB のJSONパース
    Idea? parseIdea(String? ideaJson) {
      if (ideaJson == null || ideaJson.isEmpty) return null;
      try {
        return Idea.fromMap(jsonDecode(ideaJson));
      } catch (e) {
        return null;
      }
    }

    return AICombination(
      id: map['id'],
      ideaIds: parseIdeaIds(map['idea_ids']),
      combinedContent: map['combined_content'],
      reasoning: map['reasoning'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      isFavorite: map['is_favorite'] == 1,
      ideaA: parseIdea(map['idea_a']),
      ideaB: parseIdea(map['idea_b']),
    );
  }

  // JSONへのシリアライズ
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'idea_ids': jsonEncode(ideaIds),
      'combined_content': combinedContent,
      'reasoning': reasoning,
      'created_at': createdAt.toIso8601String(),
      'is_favorite': isFavorite ? 1 : 0,
      'idea_a': _ideaA != null ? jsonEncode(_ideaA.toMap()) : null,
      'idea_b': _ideaB != null ? jsonEncode(_ideaB.toMap()) : null,
    };
  }

  // JSONに変換
  String toJson() => jsonEncode(toMap());

  @override
  String toString() {
    return 'AICombination(id: $id, ideaIds: $ideaIds, combinedContent: $combinedContent, reasoning: $reasoning, created: $createdAt, isFavorite: $isFavorite)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AICombination &&
        other.id == id &&
        listEquals(other.ideaIds, ideaIds) &&
        other.combinedContent == combinedContent &&
        other.reasoning == reasoning &&
        other.createdAt == createdAt &&
        other.isFavorite == isFavorite;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        ideaIds.hashCode ^
        combinedContent.hashCode ^
        reasoning.hashCode ^
        createdAt.hashCode ^
        isFavorite.hashCode;
  }
}

// List<int>の比較ヘルパー
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = a.length - 1; i >= 0; i--) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
