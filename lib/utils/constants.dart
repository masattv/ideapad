import 'package:flutter/material.dart';

// アプリ全体の定数
class AppConstants {
  // アプリ名
  static const String appName = 'アイデアパッド';
  
  // 画面タイトル
  static const String homeScreenTitle = 'アイデアを記録';
  static const String combinationScreenTitle = 'アイデアの組み合わせ';
  
  // メッセージ
  static const String emptyIdeasMessage = 'まだアイデアがありません。\n新しいアイデアを追加してみましょう！';
  static const String emptyCombinationsMessage = 'アイデアを2つ以上登録すると、\n組み合わせ提案が表示されます。';
  static const String ideaInputHint = '新しいアイデアを入力...';
  static const String ideaAddButtonLabel = '追加';
  static const String errorOccurred = 'エラーが発生しました';
  static const String ideaAddedSuccess = 'アイデアを追加しました';
  static const String ideaUpdatedSuccess = 'アイデアを更新しました';
  static const String ideaDeletedSuccess = 'アイデアを削除しました';
  static const String combinationCreatedSuccess = '組み合わせを生成しました';
  static const String combinationSavedSuccess = '組み合わせを保存しました';
  static const String noMoreIdeas = 'アイデアを更に追加してください';
  
  // ボタンラベル
  static const String generateCombinationsLabel = '新しい組み合わせを生成';
  static const String backToHomeLabel = 'アイデア一覧に戻る';
  static const String editLabel = '編集';
  static const String deleteLabel = '削除';
  static const String cancelLabel = 'キャンセル';
  static const String saveLabel = '保存';
  
  // アイコン
  static const IconData addIcon = Icons.add;
  static const IconData editIcon = Icons.edit;
  static const IconData deleteIcon = Icons.delete;
  static const IconData favoriteIcon = Icons.favorite;
  static const IconData favoriteBorderIcon = Icons.favorite_border;
  static const IconData combinationIcon = Icons.auto_awesome;
  static const IconData refreshIcon = Icons.refresh;
  static const IconData backIcon = Icons.arrow_back;
  
  // アニメーション
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
  
  // UI要素
  static const double cardElevation = 2.0;
  static const double cardBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  // 組み合わせ生成
  static const int defaultCombinationCount = 5;
}

// エラーメッセージ
class ErrorMessages {
  static const String databaseError = 'データベース操作中にエラーが発生しました';
  static const String emptyContentError = 'アイデアを入力してください';
  static const String ideaNotFoundError = '指定されたアイデアが見つかりません';
  static const String combinationError = '組み合わせの生成に失敗しました';
}

// キー（ウィジェットの識別子など）
class AppKeys {
  static const Key ideaListKey = Key('idea_list');
  static const Key ideaFormKey = Key('idea_form');
  static const Key combinationListKey = Key('combination_list');
} 