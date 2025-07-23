// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:convert';

import 'package:flutter/services.dart';

class ConfigEnv {
  static late String APIURL;
  static late String MODO;

  static const int NYPCONFOTO = 277;
  static const int NYPSINFOTO = 278;
  static const int UFOCONFOTO = 279;
  static const int UFOSINFOTO = 280;

  static Future<void> loadFromAssets(String flavor, bool isProd) async {
    final path = isProd
        ? 'assets/config/$flavor/config_prod.json'
        : 'assets/config/$flavor/config.json';

    final jsonStr = await rootBundle.loadString(path);
    final jsonMap = json.decode(jsonStr);

    APIURL = jsonMap['APIURL'] ?? '';
    MODO = jsonMap['MODO'] ?? '';
  }
}
