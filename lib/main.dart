import 'package:deposito/config/router/router.dart';
import 'package:deposito/config/theme/app_theme.dart';
import 'package:deposito/config/version_checker.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/provider/theme_provider.dart';
import 'package:deposito/provider/ubicacion_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Importa esto para kIsWeb
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool camDisponible = prefs.getBool('cambioVista') ?? false;
  
  // Inicializa initialLocation con un valor por defecto
  String initialLocation = '/login';
  
  // Solo verifica la versión si no es web (es decir, es APK/mobile)
  if (!kIsWeb) {
    initialLocation = await VersionChecker.checkVersion();
  }
  
  appRouter = await AppRouter.createAppRouter(initialLocation);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_)=> ProductProvider()..setCamara(camDisponible),),
        ChangeNotifierProvider(create: (_) => ThemeProvider(),),
        ChangeNotifierProvider(create: (_) => UbicacionProvider(),),
      ],
      child: const MyApp(),
    )
  );
  
  // También podrías hacer que esto solo se aplique en mobile
  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp],
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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