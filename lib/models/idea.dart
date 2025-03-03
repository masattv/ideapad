import 'dart:convert';

class Idea {
  final int? id;
  final String content;
  final int? parentId;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  // JSONエンコード用のタグゲッター
  String get tagsJson => jsonEncode(tags);

  Idea({
    this.id,
    required this.content,
    this.parentId,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
  })  : this.tags = tags ?? [],
        this.createdAt = createdAt ?? DateTime.now(),
        this.updatedAt = updatedAt ?? DateTime.now();

  // 新しいインスタンスを作成するためのファクトリーメソッド
  factory Idea.create({
    required String content,
    int? parentId,
    List<String>? tags,
  }) {
    final now = DateTime.now();
    return Idea(
      content: content,
      parentId: parentId,
      tags: tags ?? [],
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    );
  }

  // 既存のアイデアを更新するためのメソッド
  Idea copyWith({
    int? id,
    String? content,
    int? parentId,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Idea(
      id: id ?? this.id,
      content: content ?? this.content,
      parentId: parentId ?? this.parentId,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(), // 更新時は常に更新日時を更新
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // JSONからのデシリアライズ
  factory Idea.fromMap(Map<String, dynamic> map) {
    List<String> parseTags(dynamic tagsData) {
      if (tagsData == null) return [];
      if (tagsData is String) {
        try {
          final List<dynamic> parsed = jsonDecode(tagsData);
          return parsed.map((tag) => tag.toString()).toList();
        } catch (e) {
          return [];
        }
      }
      return [];
    }

    return Idea(
      id: map['id'],
      content: map['content'],
      parentId: map['parent_id'],
      tags: parseTags(map['tags']),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
      isDeleted: map['is_deleted'] == 1,
    );
  }

  // JSONへのシリアライズ
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'content': content,
      'parent_id': parentId,
      'tags': jsonEncode(tags),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  @override
  String toString() {
    return 'Idea(id: $id, content: $content, parentId: $parentId, tags: $tags, created: $createdAt, updated: $updatedAt, isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Idea &&
        other.id == id &&
        other.content == content &&
        other.parentId == parentId &&
        listEquals(other.tags, tags) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isDeleted == isDeleted;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        content.hashCode ^
        parentId.hashCode ^
        tags.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        isDeleted.hashCode;
  }
}

// List<String>の比較ヘルパー
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
