# アイデアパッド アプリのルートパターン

## 1. ルート定義

アプリで使用されるすべてのルートは`AppRoutes`クラスで定義されています。

```dart
static const String home = '/';                // ホーム画面
static const String combinations = '/combinations';  // アイデア組み合わせ画面
static const String ideaEditor = '/idea/editor';     // アイデア編集画面
static const String onboarding = '/onboarding';      // オンボーディング画面
static const String other = '/other';               // その他の設定画面
```

## 2. 画面遷移のパターン

### 2.1 通常の画面遷移

標準的な画面遷移は以下のように行います。この場合、戻るボタンで前の画面に戻ることができます。

```dart
// 例: ホーム画面からアイデア組み合わせ画面へ
Navigator.of(context).pushNamed(AppRoutes.combinations);

// 例: ホーム画面からその他画面へ
Navigator.of(context).pushNamed(AppRoutes.other);
```

### 2.2 画面の置き換え

現在の画面を新しい画面に置き換え、戻るボタンを押すと前の画面ではなく、さらに前の画面に戻るようにします。

```dart
// 例: オンボーディング画面からホーム画面への遷移（古い実装）
Navigator.of(context).pushReplacementNamed(AppRoutes.home);
```

### 2.3 すべての画面をクリアして新しい画面に遷移

ナビゲーションスタックをすべてクリアして新しい画面に遷移します。これにより、戻るボタンを押しても前の画面に戻れなくなります。

```dart
// 例: オンボーディング完了後、ホーム画面への遷移（改善後の実装）
Navigator.of(context).pushNamedAndRemoveUntil(
  AppRoutes.home,
  (route) => false,  // すべての前の画面を削除
);
```

### 2.4 引数を伴う画面遷移

パラメータを伴って別の画面に遷移する場合は、`arguments`パラメータを使用します。

```dart
// 例: アイデア編集画面への遷移（既存アイデアの編集）
Navigator.of(context).pushNamed(
  AppRoutes.ideaEditor,
  arguments: {
    'idea': existingIdea,  // 既存のIdeaオブジェクト
    'parentId': parentId,  // 親アイデアのID（階層構造の場合）
  },
);

// 例: 新規アイデア作成のための遷移
Navigator.of(context).pushNamed(
  AppRoutes.ideaEditor,
  arguments: {
    'idea': null,        // 新規作成なのでnull
    'parentId': null,    // トップレベルのアイデアなのでnull
  },
);
```

## 3. 独自のトランジション（画面遷移アニメーション）

アプリではすべての画面遷移に右からスライドインするアニメーションが適用されています。これは`_buildRoute`メソッドで実装されています。

```dart
static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);  // 右から
      const end = Offset.zero;         // 中央へ
      const curve = Curves.easeInOut;  // イーズイン・アウトのアニメーション
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);
      return SlideTransition(position: offsetAnimation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 300),  // 300ミリ秒かけて遷移
  );
}
```

## 4. 初期ルートの決定

アプリ起動時の初期ルートは動的に決定されます：

```dart
// App.dartでの実装
home: FutureBuilder<bool>(
  future: _checkFirstLaunch(),  // 初回起動かどうかをチェック
  builder: (context, snapshot) {
    final bool isFirstLaunch = snapshot.data ?? true;
    
    if (isFirstLaunch) {
      // 初回起動時はオンボーディング画面を表示
      return const OnboardingScreen();
    } else {
      // 2回目以降の起動時は通常のホーム画面を表示
      return const HomeScreen();
    }
  },
),
```

## 5. オンボーディングからホームへの遷移（重要な修正点）

オンボーディング完了時には、すべてのナビゲーションスタックをクリアし、ホーム画面に遷移します：

```dart
// onboarding_screen.dartでの実装
Future<void> _completeOnboarding() async {
  // SharedPreferencesのインスタンスを取得
  final prefs = await SharedPreferences.getInstance();
  // オンボーディング完了フラグを保存
  await prefs.setBool('onboarding_completed', true);

  // Widgetがまだマウントされているか確認
  if (!mounted) return;
  
  // 全画面をクリアしてホーム画面に遷移
  Navigator.of(context).pushNamedAndRemoveUntil(
    AppRoutes.home,
    (route) => false,  // すべての前の画面を削除
  );
}
```

## 6. 注意点

- `home`プロパティと`routes`プロパティを同時に使用すると、「/」ルートの重複定義となりエラーが発生します。これを避けるため、`onGenerateRoute`のみを使用します。
- 画面遷移時には常に現在のコンテキスト（mounted状態）を確認してください。
- パラメータを渡す際は型の一貫性に注意し、null安全性を考慮しましょう。 