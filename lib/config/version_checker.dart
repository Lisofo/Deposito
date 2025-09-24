import 'package:deposito/config/config_env.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';

class VersionChecker {
  static final Dio _dio = Dio();
  
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
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentVersionParts = _parseVersion(currentVersion);
      
      final String apiUrl = ConfigEnv.APIURL;
      final String url = '$apiUrl/api/config/version-check';
      final response = await _dio.request(
        url,
        options: Options(
          method: 'GET',
          responseType: ResponseType.json,
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final latestVersion = data['latestVersion'] as String;
        final latestVersionParts = _parseVersion(latestVersion);
        
        if (upToDate(currentVersionParts, latestVersionParts) || mayorQueLaActual(currentVersionParts, latestVersionParts)) {
          return '/login';
        } else {
          return '/';
        }
      } else {
        print('Error en la respuesta: ${response.statusCode}');
        return '/'; // Fallback en caso de error
      }
      
    } on DioException catch (e) {
      // Manejo específico de errores de Dio
      if (e.response != null) {
        print('Error del servidor: ${e.response?.statusCode}');
      } else {
        print('Error de conexión: ${e.message}');
      }
      return '/'; // Fallback en caso de error
    } catch (e) {
      print('Error al verificar la versión: $e');
      return '/'; // Fallback en caso de error
    }
  }
}