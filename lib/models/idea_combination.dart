import 'dart:convert';

class IdeaCombination {
  final int? id;
  final List<int> ideaIds;
  final String combinedContent;
  final DateTime createdAt;
  final bool isFavorite;

  IdeaCombination({
    this.id,
    required this.ideaIds,
    required this.combinedContent,
    required this.createdAt,
    this.isFavorite = false,
  });

  // コピーを作成するファクトリメソッド
  IdeaCombination copyWith({
    int? id,
    List<int>? ideaIds,
    String? combinedContent,
    DateTime? createdAt,
    bool? isFavorite,
  }) {
    return IdeaCombination(
      id: id ?? this.id,
      ideaIds: ideaIds ?? this.ideaIds,
      combinedContent: combinedContent ?? this.combinedContent,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  // Mapに変換するメソッド (データベース保存用)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idea_ids': jsonEncode(ideaIds),
      'combined_content': combinedContent,
      'created_at': createdAt.toIso8601String(),
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  // MapからIdeaCombinationを作成するファクトリメソッド (データベース読み込み用)
  factory IdeaCombination.fromMap(Map<String, dynamic> map) {
    return IdeaCombination(
      id: map['id'] as int?,
      ideaIds: List<int>.from(
        jsonDecode(map['idea_ids'] as String) as List,
      ),
      combinedContent: map['combined_content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      isFavorite: (map['is_favorite'] as int) == 1,
    );
  }

  // JSONに変換
  String toJson() => jsonEncode(toMap());

  // JSONからIdeaCombinationを作成
  factory IdeaCombination.fromJson(String source) => IdeaCombination.fromMap(
    jsonDecode(source) as Map<String, dynamic>,
  );

  @override
  String toString() {
    return 'IdeaCombination(id: $id, ideaIds: $ideaIds, combinedContent: $combinedContent, createdAt: $createdAt, isFavorite: $isFavorite)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IdeaCombination &&
        other.id == id &&
        other.ideaIds.toString() == ideaIds.toString() &&
        other.combinedContent == combinedContent &&
        other.createdAt == createdAt &&
        other.isFavorite == isFavorite;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        ideaIds.hashCode ^
        combinedContent.hashCode ^
        createdAt.hashCode ^
        isFavorite.hashCode;
  }
} 