import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// アプリのテーマモードを管理するサービス
class ThemeService extends ChangeNotifier {
  // テーマモードを保存するキー
  static const String _themePreferenceKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  // 現在のテーマモードを取得
  ThemeMode get themeMode => _themeMode;

  // コンストラクタ - 初期化時に保存されたテーマモードを読み込む
  ThemeService() {
    _loadThemeMode();
  }

  // 保存されたテーマモードを読み込む
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedTheme = prefs.getString(_themePreferenceKey);

    if (savedTheme != null) {
      _themeMode = _themeModeFromString(savedTheme);
      notifyListeners();
    }
  }

  // テーマモードを変更する
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;

    // 変更をSharedPreferencesに保存
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, _themeModeToString(mode));

    // リスナーに変更を通知
    notifyListeners();
  }

  // テーマモードを切り替える（ライト→ダーク→システム→ライト...）
  Future<void> toggleThemeMode() async {
    ThemeMode newMode;

    switch (_themeMode) {
      case ThemeMode.light:
        newMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        newMode = ThemeMode.system;
        break;
      case ThemeMode.system:
        newMode = ThemeMode.light;
        break;
    }

    await setThemeMode(newMode);
  }

  // 文字列からThemeModeに変換
  ThemeMode _themeModeFromString(String themeModeString) {
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  // ThemeModeから文字列に変換
  String _themeModeToString(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
