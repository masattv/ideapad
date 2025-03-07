import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:idea_app/config/routes.dart';
import 'package:idea_app/config/themes.dart';
import 'package:idea_app/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:idea_app/services/database_service.dart';
import 'package:idea_app/services/open_ai_client.dart';
import 'package:idea_app/services/ai_idea_combination_service.dart';
import 'package:idea_app/services/user_stats_service.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DatabaseService>(
          create: (_) => DatabaseService(),
        ),
        Provider<OpenAIClient>(
          create: (_) => OpenAIClient.fromEnv(),
        ),
        ProxyProvider<DatabaseService, Future<UserStatsService>>(
          update: (_, databaseService, __) async {
            // データベースが初期化された後にUserStatsServiceを作成
            final db = await databaseService.database;
            return UserStatsService.getInstance(db);
          },
          dispose: (_, future) async {
            // 何もしない（シングルトンのため）
          },
        ),
        ProxyProvider3<DatabaseService, OpenAIClient, Future<UserStatsService>,
            Future<AIIdeaCombinationService>>(
          update:
              (_, databaseService, openAIClient, userStatsFuture, __) async {
            final userStatsService = await userStatsFuture;
            return AIIdeaCombinationService(
              openAIClient,
              databaseService,
              userStatsService,
            );
          },
          dispose: (_, future) async {
            // 何もしない
          },
        ),
      ],
      child: MaterialApp(
        title: 'アイデアパッド',
        theme: AppThemes.lightTheme(),
        darkTheme: AppThemes.darkTheme(),
        themeMode: ThemeMode.system, // システム設定に従う
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRoutes.generateRoute,
        home: FutureBuilder<void>(
          // アプリが起動する前にサービスが初期化されるのを待つ
          future: _initializeServices(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return const HomeScreen();
            }
            // ローディング表示
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
        ),
      ),
    );
  }

  // サービスを初期化するためのヘルパーメソッド
  Future<void> _initializeServices(BuildContext context) async {
    // DatabaseServiceを初期化
    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);
    await databaseService.database;

    // UserStatsServiceを初期化
    await Provider.of<Future<UserStatsService>>(context, listen: false);

    // AIIdeaCombinationServiceを初期化
    await Provider.of<Future<AIIdeaCombinationService>>(context, listen: false);
  }
}
