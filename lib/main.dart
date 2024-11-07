import 'package:deposito/config/router/routes.dart';
import 'package:deposito/config/theme/app_theme.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  runApp(ChangeNotifierProvider(
    create: (_) => ProductProvider(),
    child: const MyApp(),
  ));
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appTheme = AppTheme(selectedColor: 0);
    return MaterialApp.router(
      theme: appTheme.getTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // English
        Locale('es', 'UY'), // Spanish
      ],
      // initialRoute: '/',
      // routes: getApplicationRoutes(),
      // onGenerateRoute: (RouteSettings settings) {
      //   return MaterialPageRoute(builder: (context) => Login());
      // },
    );
  }
}