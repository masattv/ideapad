import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemes {
  // カラー定義
  static const Color _primaryLight = Color(0xFF3B82F6); // ブルー
  static const Color _primaryDark = Color(0xFF3B82F6); // 同じブルー

  static const Color _secondaryLight = Color(0xFF10B981); // グリーン
  static const Color _secondaryDark = Color(0xFF10B981); // 同じグリーン

  static const Color _backgroundLight = Color(0xFFF8FAFC); // 明るいグレー
  static const Color _backgroundDark = Color(0xFF0F172A); // ダークネイビー

  static const Color _surfaceLight = Color(0xFFFFFFFF); // 白
  static const Color _surfaceDark = Color(0xFF1E293B); // ダークグレー

  static const Color _onPrimaryLight = Color(0xFFFFFFFF); // 白
  static const Color _onPrimaryDark = Color(0xFFFFFFFF); // 白

  static const Color _onSecondaryLight = Color(0xFFFFFFFF); // 白
  static const Color _onSecondaryDark = Color(0xFFFFFFFF); // 白

  static const Color _onBackgroundLight = Color(0xFF334155); // グレー
  static const Color _onBackgroundDark = Color(0xFFF8FAFC); // 明るいグレー

  static const Color _onSurfaceLight = Color(0xFF334155); // グレー
  static const Color _onSurfaceDark = Color(0xFFF8FAFC); // 明るいグレー

  static const Color _errorLight = Color(0xFFEF4444); // 赤
  static const Color _errorDark = Color(0xFFEF4444); // 赤

  static const Color _cardColorLight = Color(0xFFFFFFFF); // 白
  static const Color _cardColorDark = Color(0xFF1E293B); // ダークグレー

  static const Color _dividerColorLight = Color(0xFFE2E8F0); // 明るいグレー
  static const Color _dividerColorDark = Color(0xFF334155); // グレー

  // 追加カラー
  static const Color accentBlueLight = Color(0xFF38BDF8); // 明るいブルー
  static const Color accentBlueDark = Color(0xFF38BDF8); // 明るいブルー

  static const Color accentPinkLight = Color(0xFFF472B6); // ピンク
  static const Color accentPinkDark = Color(0xFFF472B6); // ピンク

  static const Color accentGreenLight = Color(0xFF34D399); // 明るいグリーン
  static const Color accentGreenDark = Color(0xFF34D399); // 明るいグリーン

  static const Color subtleLight = Color(0xFFCBD5E1); // 薄いグレー
  static const Color subtleDark = Color(0xFF4B5563); // グレー

  static const Color frostLight = Color(0xBFFFFFFF); // 半透明白
  static const Color frostDark = Color(0xBF1E293B); // 半透明ダークグレー

  // テキストテーマ
  static TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      // アプリバーのタイトル、画面のメインタイトルなど
      headlineLarge: GoogleFonts.montserrat(
        textStyle: base.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 28,
          letterSpacing: 0.25,
        ),
      ),

      // セクションタイトルなど
      headlineMedium: GoogleFonts.montserrat(
        textStyle: base.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 24,
          letterSpacing: 0,
        ),
      ),

      // ダイアログタイトル、小見出しなど
      headlineSmall: GoogleFonts.montserrat(
        textStyle: base.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          letterSpacing: 0,
        ),
      ),

      // カードタイトル、強調テキストなど
      titleLarge: GoogleFonts.montserrat(
        textStyle: base.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          letterSpacing: 0.15,
        ),
      ),

      // リストアイテムのタイトルなど
      titleMedium: GoogleFonts.montserrat(
        textStyle: base.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          letterSpacing: 0.15,
        ),
      ),

      // ボタンテキスト、小さいタイトルなど
      titleSmall: GoogleFonts.montserrat(
        textStyle: base.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          letterSpacing: 0.1,
        ),
      ),

      // 本文テキスト
      bodyLarge: GoogleFonts.notoSans(
        textStyle: base.bodyLarge?.copyWith(
          fontWeight: FontWeight.normal,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
      ),

      // アイデア内容テキスト、通常の本文
      bodyMedium: GoogleFonts.notoSans(
        textStyle: base.bodyMedium?.copyWith(
          fontWeight: FontWeight.normal,
          fontSize: 14,
          letterSpacing: 0.25,
        ),
      ),

      // ヘルプテキスト、キャプションなど
      bodySmall: GoogleFonts.notoSans(
        textStyle: base.bodySmall?.copyWith(
          fontWeight: FontWeight.normal,
          fontSize: 12,
          letterSpacing: 0.4,
        ),
      ),

      // ラベルテキスト
      labelLarge: GoogleFonts.montserrat(
        textStyle: base.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          letterSpacing: 1.25,
        ),
      ),

      // ミニラベル
      labelMedium: GoogleFonts.montserrat(
        textStyle: base.labelMedium?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 12,
          letterSpacing: 1.0,
        ),
      ),

      // 非常に小さいラベル
      labelSmall: GoogleFonts.montserrat(
        textStyle: base.labelSmall?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 10,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  // ライトテーマ
  static ThemeData lightTheme() {
    final ColorScheme colorScheme = ColorScheme(
      primary: _primaryLight,
      primaryContainer: _primaryLight.withOpacity(0.8),
      secondary: _secondaryLight,
      secondaryContainer: _secondaryLight.withOpacity(0.8),
      surface: _surfaceLight,
      background: _backgroundLight,
      error: _errorLight,
      onPrimary: _onPrimaryLight,
      onSecondary: _onSecondaryLight,
      onSurface: _onSurfaceLight,
      onBackground: _onBackgroundLight,
      onError: Colors.white,
      brightness: Brightness.light,
    );

    final ThemeData base = ThemeData.light();

    return base.copyWith(
      colorScheme: colorScheme,
      primaryColor: _primaryLight,
      scaffoldBackgroundColor: _backgroundLight,
      cardColor: _cardColorLight,
      dividerColor: _dividerColorLight,
      textTheme: _buildTextTheme(base.textTheme),
      primaryTextTheme: _buildTextTheme(base.primaryTextTheme),

      // AppBarテーマ
      appBarTheme: AppBarTheme(
        color: _backgroundLight,
        elevation: 0,
        centerTitle: true,
        foregroundColor: _onBackgroundLight,
        titleTextStyle: _buildTextTheme(base.textTheme).headlineSmall,
      ),

      // カードテーマ
      cardTheme: CardTheme(
        color: _cardColorLight,
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _dividerColorLight,
            width: 1,
          ),
        ),
      ),

      // ボタンテーマ
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: _onPrimaryLight,
          backgroundColor: _primaryLight,
          elevation: 0,
          textStyle: _buildTextTheme(base.textTheme).labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // テキストフィールドテーマ
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _dividerColorLight,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _dividerColorLight,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _primaryLight,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _errorLight,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _errorLight,
            width: 2,
          ),
        ),
      ),

      // FABテーマ
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryLight,
        foregroundColor: _onPrimaryLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // ダークテーマ
  static ThemeData darkTheme() {
    final ColorScheme colorScheme = ColorScheme(
      primary: _primaryDark,
      primaryContainer: _primaryDark.withOpacity(0.8),
      secondary: _secondaryDark,
      secondaryContainer: _secondaryDark.withOpacity(0.8),
      surface: _surfaceDark,
      background: _backgroundDark,
      error: _errorDark,
      onPrimary: _onPrimaryDark,
      onSecondary: _onSecondaryDark,
      onSurface: _onSurfaceDark,
      onBackground: _onBackgroundDark,
      onError: Colors.white,
      brightness: Brightness.dark,
    );

    final ThemeData base = ThemeData.dark();

    return base.copyWith(
      colorScheme: colorScheme,
      primaryColor: _primaryDark,
      scaffoldBackgroundColor: _backgroundDark,
      cardColor: _cardColorDark,
      dividerColor: _dividerColorDark,
      textTheme: _buildTextTheme(base.textTheme),
      primaryTextTheme: _buildTextTheme(base.primaryTextTheme),

      // AppBarテーマ
      appBarTheme: AppBarTheme(
        color: _backgroundDark,
        elevation: 0,
        centerTitle: true,
        foregroundColor: _onBackgroundDark,
        titleTextStyle: _buildTextTheme(base.textTheme).headlineSmall,
      ),

      // カードテーマ
      cardTheme: CardTheme(
        color: _cardColorDark,
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _dividerColorDark.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),

      // ボタンテーマ
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: _onPrimaryDark,
          backgroundColor: _primaryDark,
          elevation: 0,
          textStyle: _buildTextTheme(base.textTheme).labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // テキストフィールドテーマ
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceDark,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _dividerColorDark,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _dividerColorDark,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _primaryDark,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _errorDark,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _errorDark,
            width: 2,
          ),
        ),
      ),

      // FABテーマ
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryDark,
        foregroundColor: _onPrimaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
