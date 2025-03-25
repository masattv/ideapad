// 必要なパッケージをインポート
import 'package:flutter/material.dart'; // Flutterの基本的なウィジェットを使用するためのパッケージ
import 'package:shared_preferences/shared_preferences.dart'; // データの永続化を行うためのパッケージ
import 'package:idea_app/config/themes.dart'; // アプリのテーマ設定を管理するファイル
import 'package:idea_app/config/routes.dart'; // アプリの画面遷移を管理するファイル
import 'package:flutter_animate/flutter_animate.dart'; // アニメーション効果を追加するためのパッケージ

// オンボーディング画面のStatefulWidget
// オンボーディング：アプリの使い方を説明する初回起動時の案内画面
class OnboardingScreen extends StatefulWidget {
  // コンストラクタ - キーを受け取る
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  // Stateクラスを作成
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

// オンボーディング画面のState管理クラス
class _OnboardingScreenState extends State<OnboardingScreen> {
  // PageViewを制御するためのコントローラー
  final PageController _pageController = PageController();
  // 現在表示しているページ番号を管理する変数
  int _currentPage = 0;

  // オンボーディングページの内容を定義するリスト
  final List<OnboardingPage> _pages = [
    // 1ページ目：アイデア管理の説明
    OnboardingPage(
      title: 'アイデアをカンタン管理',
      description: 'ひらめいたアイデアをすぐに記録。\nいつでも簡単に思い出せます。',
      icon: Icons.lightbulb_outline,
    ),
    // 2ページ目：AI機能の説明
    OnboardingPage(
      title: 'AIによるアイデア発展',
      description: 'AIがあなたのアイデアを組み合わせたり、\n実現案を提案してくれます。',
      icon: Icons.auto_awesome,
    ),
    // 3ページ目：アプリ開始の案内
    OnboardingPage(
      title: 'さあ、始めましょう',
      description: 'あなたの創造力をサポートする\n最高のアイデアパートナーです。',
      icon: Icons.rocket_launch,
    ),
  ];

  @override
  // Widgetが破棄される時の処理
  void dispose() {
    // PageControllerを破棄してメモリリークを防ぐ
    _pageController.dispose();
    super.dispose();
  }

  // オンボーディングの完了を記録し、ホーム画面に遷移する関数
  Future<void> _completeOnboarding() async {
    // SharedPreferencesのインスタンスを取得
    final prefs = await SharedPreferences.getInstance();
    // オンボーディング完了フラグを保存
    await prefs.setBool('onboarding_completed', true);

    // Widgetがまだマウントされているか確認
    if (!mounted) return;

    // ホーム画面に遷移（戻るボタンでオンボーディングに戻れないように）
    // pushReplacementNamedはバグがあるため、より確実なpushAndRemoveUntilを使用
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false, // すべての前の画面を削除
    );
  }

  @override
  // 画面のUIを構築
  Widget build(BuildContext context) {
    return Scaffold(
      // SafeAreaで端末の切り欠きなどを避けてコンテンツを表示
      body: SafeArea(
        child: Column(
          children: [
            // 画面右上のスキップボタン
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: const Text('スキップ'),
                  style: TextButton.styleFrom(
                    // テーマカラーを使用
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),

            // ページ切り替えができるメインコンテンツ領域
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                // ページが切り替わった時の処理
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                // 各ページのコンテンツを構築
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // 現在のページを示すドットインジケーター
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => _buildDotIndicator(index == _currentPage),
                ),
              ),
            ),

            // 最後のページでのみ表示される「使ってみる」ボタン
            Padding(
              padding:
                  const EdgeInsets.only(bottom: 48.0, left: 24.0, right: 24.0),
              child: AnimatedOpacity(
                // 最後のページでのみ表示
                opacity: _currentPage == _pages.length - 1 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: ElevatedButton(
                  // 最後のページでのみ有効化
                  onPressed: _currentPage == _pages.length - 1
                      ? _completeOnboarding
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '使ってみる',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  // フェードインアニメーションを追加
                ).animate().fadeIn(duration: 500.ms),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 各ページのコンテンツを構築するヘルパーメソッド
  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // アイコンを表示（スケールアニメーション付き）
          Icon(
            page.icon,
            size: 120,
            color: Theme.of(context).colorScheme.primary,
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

          const SizedBox(height: 40),

          // タイトルを表示（フェードイン＆スライドアニメーション付き）
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          // 説明文を表示（フェードイン＆スライドアニメーション付き）
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onBackground
                      .withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 200.ms)
              .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  // ドットインジケーターを構築するヘルパーメソッド
  Widget _buildDotIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      // アクティブなページのドットを長くする
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        // アクティブなページのドットを濃い色にする
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }
}

// オンボーディングページの情報を保持するデータクラス
class OnboardingPage {
  final String title; // ページのタイトル
  final String description; // ページの説明文
  final IconData icon; // ページのアイコン

  // コンストラクタ - 必須パラメータを設定
  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
  });
}
