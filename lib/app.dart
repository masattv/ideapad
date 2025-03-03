import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:idea_app/config/routes.dart';
import 'package:idea_app/config/themes.dart';
import 'package:idea_app/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:idea_app/services/database_service.dart';
import 'package:idea_app/services/open_ai_client.dart';
import 'package:idea_app/services/ai_idea_combination_service.dart';

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
        ProxyProvider2<DatabaseService, OpenAIClient, AIIdeaCombinationService>(
          update: (_, databaseService, openAIClient, __) =>
              AIIdeaCombinationService(openAIClient, databaseService),
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
        home: const HomeScreen(),
      ),
    );
  }
}
