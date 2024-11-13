import 'package:flutter/material.dart';
import 'package:deposito/models/almacen.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData = ThemeData.light();

  ThemeData get themeData => _themeData;

  void setThemeFromAlmacen(Almacen almacen) {
    _themeData = ThemeData(
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: Color.fromARGB(255, almacen.r, almacen.g, almacen.b),
        onPrimary: Colors.white,
        secondary: Color.fromARGB(140, almacen.r, almacen.g, almacen.b),
        onSecondary: Colors.white,
        error: Colors.red,
        onError: Colors.black,
        surface: Colors.white,
        onSurface: Colors.black,
      ),
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
    notifyListeners();
  }

  void resetTheme() {
    _themeData = ThemeData.light(); // Tema predeterminado
    notifyListeners();
  }
}
