import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:idea_app/app.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path_provider;

void main() async {
  // Flutterバインディングを初期化
  WidgetsFlutterBinding.ensureInitialized();

  // 環境変数の読み込み
  await dotenv.load(fileName: '.env');

  // データベースの保存場所をアプリケーション内の固定パスに設定
  final String dbName = 'ideapad.db';
  final String dbPath;

  // SQLite FFIの初期化（プラットフォーム依存部分）
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
    // iOS/Android/macOSの場合、sqfliteのデフォルトパスを使用
    dbPath = path_provider.join(await getDatabasesPath(), dbName);
  }

  // データベースパスを環境変数に設定
  // dotenv.env['DB_PATH'] = dbPath;

  // 画面の向きを縦向きに固定
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // データベースの準備（近藤Q ここのDB準備は不要に見える）
  // await _prepareDatabasePath(dbPath);

  // アプリケーションを実行
  runApp(const App());
}

// データベースパスの準備
Future<void> _prepareDatabasePath(String dbPath) async {
  try {
    // データベースディレクトリを作成
    final dbDir = Directory(path_provider.dirname(dbPath));
    if (!dbDir.existsSync()) {
      await dbDir.create(recursive: true);
    }

    // データベースが存在するかチェック
    final exists = await databaseExists(dbPath);

    if (!exists) {
      debugPrint('新しいデータベースを作成します: $dbPath');
    } else {
      debugPrint('既存のデータベースを使用します: $dbPath');
    }
  } catch (e) {
    debugPrint('データベースパスの準備に失敗しました: $e');
    // エラーが発生しても続行（アプリ起動時にデータベースサービスが再試行する）
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
