import 'package:flutter/material.dart';

const String flavor = String.fromEnvironment('FLAVOR');

final colorList = <Color>[
  const Color.fromARGB(255, 33, 79, 119), // Familcar - azul
  const Color.fromARGB(255, 201, 15, 15), // Alsur - rojo
  const Color.fromARGB(255, 0, 150, 136), // TrackIt - verde (ejemplo)
];

final secondaryColorList = <Color>[
  const Color.fromARGB(255, 66, 133, 244), // Familcar - azul secundario
  const Color.fromARGB(255, 244, 67, 54),  // Alsur - rojo secundario
  const Color.fromARGB(255, 0, 200, 83),   // TrackIt - verde secundario
];

class AppTheme {
  final int selectedColor;
  final Color primaryColor;
  final Color secondaryColor;

  // Método para obtener el índice del color basado en el flavor
  static int _getSelectedColorIndex() {
    switch (flavor.toLowerCase()) {
      case 'familcar':
        return 0;
      case 'alsur':
        return 1;
      case 'trackit':
        return 2;
      default:
        return 0;
    }
  }

  // Constructor que inicializa los colores basados en el flavor
  AppTheme({int? selectedColor, Color? primaryColor, Color? secondaryColor})
      : selectedColor = selectedColor ?? _getSelectedColorIndex(),
        primaryColor = primaryColor ?? colorList[_getSelectedColorIndex()],
        secondaryColor = secondaryColor ?? secondaryColorList[_getSelectedColorIndex()];

  ThemeData getTheme() => ThemeData(
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: primaryColor, // Usamos la nueva variable primaryColor
      onPrimary: Colors.white, 
      secondary: secondaryColor,
      onSecondary: Colors.white, 
      error: Colors.red, 
      onError: Colors.black, 
      surface: Colors.white, 
      onSurface: Colors.black,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: primaryColor, // Usamos primaryColor en lugar de colorList[selectedColor]
    ),
  );

  // Método opcional para crear un tema con colores personalizados
  AppTheme copyWith({
    int? selectedColor,
    Color? primaryColor,
    Color? secondaryColor,
  }) {
    return AppTheme(
      selectedColor: selectedColor ?? this.selectedColor,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
    );
  }
}