import 'package:deposito/config/router/router.dart';
import 'package:deposito/config/theme/app_theme.dart';
import 'package:deposito/config/version_checker.dart';
import 'package:deposito/provider/menu_provider.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/provider/theme_provider.dart';
import 'package:deposito/provider/ubicacion_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/config_env.dart';

const String flavor = String.fromEnvironment('FLAVOR');
const bool isProd = bool.fromEnvironment('IS_PROD', defaultValue: false);
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ConfigEnv.loadFromAssets(flavor, isProd);

  final prefs = await SharedPreferences.getInstance();
  final bool camDisponible = prefs.getBool('camDisponible') ?? false;
  
  String initialLocation = '/login';
  
  if (!kIsWeb) {
    initialLocation = await VersionChecker.checkVersion();
  }
  
  appRouter = await AppRouter.createAppRouter(initialLocation);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()..setCamara(camDisponible)),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UbicacionProvider()),
      ],
      child: const MyApp(),
    )
  );
  
  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp],
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return Scrollbar(
      controller: details.controller,
      thumbVisibility: true, // Hacer visible siempre
      trackVisibility: true, // Mostrar también el track
      thickness: 6, // Grosor de la barra
      radius: const Radius.circular(10), // Bordes redondeados
      interactive: true, // Permite interactuar directamente con la barra
      child: child,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appTheme = AppTheme(selectedColor: 0);
    return MaterialApp.router(
      theme: appTheme.getTheme().copyWith(
        scrollbarTheme: ScrollbarThemeData(
          thumbVisibility: WidgetStateProperty.all(true),
          trackVisibility: WidgetStateProperty.all(true),
          thickness: WidgetStateProperty.all(6),
          radius: const Radius.circular(10),
          minThumbLength: 50,
          interactive: true,
        ),
      ),
      scrollBehavior: MyCustomScrollBehavior(), // Añade esta línea
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('es', 'UY'),
      ],
    );
  }
}