import 'package:flutter/material.dart';

final colorList = <Color>[
  Colors.blue.shade900,
  const Color.fromARGB(255, 221, 0, 41),
];

class AppTheme{
  final int selectedColor;
  AppTheme({this.selectedColor = 0});
  ThemeData getTheme() => ThemeData(
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: colorList[selectedColor],
      onPrimary: Colors.white, 
      secondary: Colors.green, 
      onSecondary: Colors.white, 
      error: Colors.red, 
      onError: Colors.black, 
      surface: Colors.white, 
      onSurface: Colors.black,
    ),

    appBarTheme: const AppBarTheme(
      centerTitle: false,
    )
  );
}