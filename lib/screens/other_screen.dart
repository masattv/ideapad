import 'package:flutter/material.dart';
import 'package:idea_app/config/themes.dart';
import 'package:idea_app/services/database_service.dart';
import 'package:idea_app/services/theme_service.dart';
import 'package:idea_app/widgets/app_header.dart';
import 'package:idea_app/widgets/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OtherScreen extends StatefulWidget {
  const OtherScreen({Key? key}) : super(key: key);

  @override
  State<OtherScreen> createState() => _OtherScreenState();
}

class _OtherScreenState extends State<OtherScreen> {
  late Future<List<String>> _categoriesFuture;
  final String _appVersion = '1.0.0'; // 固定のバージョン情報
  final TextEditingController _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  void _loadCategories() {
    final databaseService = DatabaseService();
    _categoriesFuture = databaseService.getAllCategories();
  }

  // 新しいカテゴリを追加
  Future<void> _addCategory() async {
    final String category = _categoryController.text.trim();
    if (category.isEmpty) return;

    final databaseService = DatabaseService();
    await databaseService.addCategory(category);
    _categoryController.clear();
    setState(() {
      _loadCategories();
    });
  }

  // カテゴリを削除
  Future<void> _deleteCategory(String category) async {
    // 確認ダイアログを表示
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('カテゴリの削除'),
            content:
                Text('「$category」を削除してもよろしいですか？このカテゴリを使用しているアイデアは影響を受けません。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('削除'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    final databaseService = DatabaseService();
    await databaseService.deleteCategory(category);
    setState(() {
      _loadCategories();
    });
  }

  // テーマモード切替
  void _toggleThemeMode() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    themeService.toggleThemeMode();
  }

  // URLを開く
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URLを開けませんでした')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeService = Provider.of<ThemeService>(context);
    final bool isDarkMode = themeService.themeMode == ThemeMode.dark ||
        (themeService.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: Text('その他', style: theme.textTheme.titleLarge),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ヘッダー
          const AppHeader(title: 'その他'),

          // メインコンテンツ
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // カテゴリ管理セクション
                _buildSection(
                  title: 'カテゴリ管理',
                  icon: Icons.category,
                  content: _buildCategoryManagement(),
                ),

                // テーマ設定
                _buildListTile(
                  title: '表示テーマの切り替え',
                  icon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  onTap: _toggleThemeMode,
                  trailing: Text(
                    isDarkMode ? 'ダークモード' : 'ライトモード',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),

                const Divider(),

                // お問い合わせ
                _buildListTile(
                  title: 'お問い合わせ',
                  icon: Icons.email,
                  onTap: () => _launchURL('mailto:support@example.com'),
                ),

                // プライバシーポリシー
                _buildListTile(
                  title: 'プライバシーポリシー',
                  icon: Icons.privacy_tip,
                  onTap: () => _launchURL('https://example.com/privacy'),
                ),

                // このアプリについて
                _buildListTile(
                  title: 'このアプリについて',
                  icon: Icons.info,
                  onTap: () => _showAboutDialog(),
                ),

                // バージョン情報
                _buildListTile(
                  title: 'バージョン',
                  icon: Icons.new_releases,
                  onTap: () {},
                  trailing: Text(
                    _appVersion,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // セクションウィジェット
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            content,
          ],
        ),
      ),
    );
  }

  // リストタイルウィジェット
  Widget _buildListTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      title: Text(title),
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  // カテゴリ管理ウィジェット
  Widget _buildCategoryManagement() {
    return Column(
      children: [
        // 新規カテゴリ追加フォーム
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  hintText: '新しいカテゴリ名',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _addCategory(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addCategory,
              child: const Text('追加'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // カテゴリリスト
        FutureBuilder<List<String>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: LoadingIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('エラーが発生しました: ${snapshot.error}'),
              );
            }

            final categories = snapshot.data ?? [];
            if (categories.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('カテゴリがありません。新しいカテゴリを追加してください。'),
                ),
              );
            }

            return Column(
              children: categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Card(
                    child: ListTile(
                      title: Text(category),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteCategory(category),
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // アプリ情報ダイアログを表示
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'アイデアパッド',
        applicationVersion: 'バージョン $_appVersion',
        applicationIcon: Image.asset(
          'assets/images/app_icon.png',
          width: 48,
          height: 48,
        ),
        applicationLegalese: '© 2023 アイデアパッド開発チーム',
        children: [
          const SizedBox(height: 16),
          const Text(
            'アイデアパッドは、あなたの創造的なアイデアを管理し、AIの力で新しいインスピレーションを提供するアプリです。',
          ),
        ],
      ),
    );
  }
}
