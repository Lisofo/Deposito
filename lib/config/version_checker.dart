import 'dart:convert';
import 'package:deposito/config/config_env.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;

class VersionChecker {
  static List<int> _parseVersion(String version) {
    final parts = version.split('-');
    final parts2 = parts[0].split('.');
    return parts2.map((part2) => int.parse(part2)).toList();
  }

  static bool upToDate(List<int> currentVersion, List<int> latestVersion) {
    bool isEqualToLatestVersion = true;
    for (int i = 0; i < currentVersion.length; i++) {
      if (currentVersion[i] < latestVersion[i] || currentVersion[i] > latestVersion[i]) {
        isEqualToLatestVersion = false;
      }
    }
    return isEqualToLatestVersion;
  }

  static bool mayorQueLaActual(List<int> currentVersion, List<int> latestVersion) {
    bool isMayorToLatestVersion = false;
    
    if(currentVersion[0] > latestVersion[0]){
      isMayorToLatestVersion = true;
    } else if ((currentVersion[0] == latestVersion[0]) && currentVersion[1] > latestVersion[1]) {
      isMayorToLatestVersion = true;
    } else if ((currentVersion[0] == latestVersion[0]) && (currentVersion[1] == latestVersion[1]) && currentVersion[2] > latestVersion[2]) {
      isMayorToLatestVersion = true;
    }
    
    return isMayorToLatestVersion;
  }

  static Future<String> checkVersion() async {
    late PackageInfo packageInfo;
    late String currentVersion = '';
    late String latestVersion = '';
    late List<int> currentVersionParts = [];
    late List<int> latestVersionParts = [];
    String apiUrl = ConfigEnv.APIURL;

    try {
      packageInfo = await PackageInfo.fromPlatform();
      currentVersion = packageInfo.version;
      currentVersionParts = _parseVersion(currentVersion);
      final response = await http.get(Uri.parse('$apiUrl/api/config/version-check'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        latestVersion = data['latestVersion'];
        latestVersionParts = _parseVersion(latestVersion);
        
      }
      print('funciono try');
    } catch (e) {
      print('Error al verificar la versión: $e');
    }
    if(upToDate(currentVersionParts, latestVersionParts) || mayorQueLaActual(currentVersionParts, latestVersionParts)) {
      return '/login';
    } else {
      return '/';
    }
    
  }
}