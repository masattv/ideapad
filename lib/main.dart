// 必要なパッケージのインポート
import 'dart:io'; // ファイル操作やプラットフォーム情報を扱うためのパッケージ
import 'package:flutter/material.dart'; // Flutterの基本的なウィジェットやマテリアルデザインを提供
import 'package:flutter/services.dart'; // プラットフォームとの連携機能を提供
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 環境変数を管理するためのパッケージ
import 'package:idea_app/app.dart'; // アプリケーションのメインウィジェット
import 'package:sqflite/sqflite.dart'; // SQLiteデータベース操作用パッケージ
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // デスクトップ向けSQLite実装
import 'package:path/path.dart' as path_provider; // ファイルパス操作用パッケージ

// アプリケーションのエントリーポイント
void main() async {
  // Flutterのウィジェットバインディングを初期化（プラグインを使用する前に必要）
  WidgetsFlutterBinding.ensureInitialized();

  // .envファイルから環境変数を読み込み（APIキーなどの設定を外部ファイルで管理）
  await dotenv.load(fileName: '.env');

  // データベースファイルの名前と保存パスを設定
  final String dbName = 'ideapad.db';
  final String dbPath;

  // プラットフォームに応じたデータベース設定
  if (Platform.isWindows || Platform.isLinux) {
    // Windows/Linuxの場合、FFIを使用 （近藤Q windowsとlinuxのDB設定ファイルはここの2行だけででよいのでは？）
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // カレントディレクトリの「data」フォルダに保存 （近藤Q 以下に処理は不要に見える）
    // final Directory appDir = Directory('data');
    // if (!appDir.existsSync()) {
    //   appDir.createSync();
    // }
    // dbPath = path_provider.join(appDir.path, dbName);
  } else {
    // iOS/Android/macOS向けの設定（プラットフォーム標準のDBパスを使用）
    dbPath = path_provider.join(await getDatabasesPath(), dbName);
  }

  // データベースパスを環境変数に設定
  // dotenv.env['DB_PATH'] = dbPath;

  // アプリの画面方向を縦向きに固定
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // データベースの準備（近藤Q ここのDB準備は不要に見える）
  // await _prepareDatabasePath(dbPath);

  // アプリケーションを起動（app.dartで定義されたAppウィジェットをルートとして使用）
  runApp(const App());
}

// データベースの保存場所を準備するヘルパー関数
Future<void> _prepareDatabasePath(String dbPath) async {
  try {
    // データベース用ディレクトリを作成
    final dbDir = Directory(path_provider.dirname(dbPath));
    if (!dbDir.existsSync()) {
      await dbDir.create(recursive: true); // 必要な親ディレクトリも含めて作成
    }

    // データベースファイルの存在確認
    final exists = await databaseExists(dbPath);

    // デバッグ情報の出力
    if (!exists) {
      debugPrint('新しいデータベースを作成します: $dbPath');
    } else {
      debugPrint('既存のデータベースを使用します: $dbPath');
    }
  } catch (e) {
    debugPrint('データベースパスの準備に失敗しました: $e');
    // エラーが発生しても処理を継続（DatabaseServiceで再試行される）
  }
}

// デモアプリのルートウィジェット（Flutterプロジェクト作成時の自動生成コード）
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // アプリケーションのテーマ設定
        // seedColorから自動的に調和の取れた配色を生成
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true, // Material Design 3を有効化
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

// デモ用のホーム画面ウィジェット
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title; // アプリバーに表示するタイトル

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// MyHomePageの状態を管理するクラス
class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0; // カウンター値を保持する状態変数

  // カウンターをインクリメントするメソッド
  void _incrementCounter() {
    setState(() {
      // setStateを呼ぶことで、Flutterフレームワークに状態の変更を通知
      // これにより、buildメソッドが再実行され、UI が更新される
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // UIレイアウトを構築するメソッド
    return Scaffold(
      appBar: AppBar(
        // アプリケーションバーの背景色をテーマに基づいて設定
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          // 子ウィジェットを垂直方向に配置
          mainAxisAlignment: MainAxisAlignment.center, // 中央揃えに設定
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter', // カウンター値を表示
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium, // テーマに基づいたテキストスタイル
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter, // ボタンタップ時にカウンターを増加
        tooltip: 'Increment',
        child: const Icon(Icons.add), // プラスアイコンを表示
      ),
    );
  }
}
