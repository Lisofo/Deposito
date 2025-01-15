import 'package:deposito/config/router/router.dart';
import 'package:deposito/config/theme/app_theme.dart';
import 'package:deposito/config/version_checker.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/provider/theme_provider.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

Future<void> main() async {

  final initialLocation = await VersionChecker.checkVersion();
  appRouter = await AppRouter.createAppRouter(initialLocation);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_)=> ProductProvider(),),
        ChangeNotifierProvider(create: (_) => ThemeProvider(),),
      ],
      child: const MyApp(),
    )
    
  );
  // SystemChrome.setPreferredOrientations(
  //   [DeviceOrientation.portraitUp, DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
  // );
  // SystemChrome.setEnabledSystemUIMode(
  //   SystemUiMode.immersiveSticky,
  // );
} 


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // final themeProvider = Provider.of<ThemeProvider>(context);
    final appTheme = AppTheme(selectedColor: 0);
    return MaterialApp.router(
      theme: appTheme.getTheme(),
      routerConfig: appRouter,
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
    );
  }
}