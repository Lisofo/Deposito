// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'package:deposito/config/config.dart';
import 'package:deposito/config/router/router.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';



class VersionCheckPage extends StatefulWidget {
  
  static const String name = 'versionChecker';
  const VersionCheckPage({super.key});

  @override
  State<VersionCheckPage> createState() => _VersionCheckPageState();

  static List<int> _parseVersion(String version) {
    final parts = version.split('-');
    final parts2 = parts[0].split('.');
    return parts2.map((part2) => int.parse(part2)).toList();
  }
  static bool isCompatibleVersion(List<int> currentVersion, List<int> minVersion) {
    for (int i = 0; i < currentVersion.length; i++) {
      if (currentVersion[i] > minVersion[i]) {
        return true;
      } else if (currentVersion[i] < minVersion[i]) {
        return false;
      }
    }
    return true;
  }
  static bool isBetweenVersions(List<int> currentVersion, List<int> minVersion, List<int> latestVersion) {
    // Check if the current version is greater than or equal to the minimum version
    bool isGreaterThanOrEqualToMinVersion = true;
    for (int i = 0; i < currentVersion.length; i++) {
      if (currentVersion[i] < minVersion[i]) {
        isGreaterThanOrEqualToMinVersion = false;
        break;
      } 
    }
    // Check if the current version is less than the latest version
    bool isLessThanLatestVersion = true;
    for (int i = 0; i < currentVersion.length; i++) {
      if (currentVersion[i] > latestVersion[i]) {
        isLessThanLatestVersion = false;
        break;
      } 
    }
    // Return true if the current version is between the minimum and latest versions
    return isGreaterThanOrEqualToMinVersion && isLessThanLatestVersion;
  }
}

class _VersionCheckPageState extends State<VersionCheckPage> {
  bool cargando = false;
  int? responseStatus;
  String? responseBody;
  late PackageInfo packageInfo;
  late String currentVersion = '';
  late String minVersion = '';
  late String latestVersion = '';
  late String downloadUrl = '';
  late List<int> currentVersionParts = [];
  late List<int> minVersionParts= [];
  late List<int> latestVersionParts = [];
  String apiUrl = Config.APIURL;
  
  @override
  void initState() {
    super.initState();
    cargarDatos();
    
    setState(() {
      
    });
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text('Actualizacion Disponible', style: TextStyle(fontSize: 25),)),
      ),
      body: SafeArea(
        child: Center(
          child: !cargando ? Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Su version Actual es : $currentVersion'),
              if (VersionCheckPage.isBetweenVersions(currentVersionParts, minVersionParts, latestVersionParts))...[
                SizedBox(height: MediaQuery.of(context).size.height * 0.1,),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.1,
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Text('Tu versión ($currentVersion) es compatible, pero se detecto un version mas reciente ($latestVersion) desea actualizar?', textAlign: TextAlign.center,),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                    child: const Text('Cancelar'),
                    onPressed: () {
                      appRouter.push('/login');
                    },
                  ),
                  TextButton(
                    child: const Text('Actualizar'),
                    onPressed: () {
                      cargando = true;
                      setState(() {
                      });
                      print('Download URL: $downloadUrl');
                      _downloadAndInstallUpdate(context, downloadUrl);
                    },
                  ),
                  ],
                )
              ]else ... [
                SizedBox(height: MediaQuery.of(context).size.height * 0.1,),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.1,
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Text('Tu versión ($currentVersion) no es compatible. Se requiere actualizar a la ultima version ($latestVersion).', textAlign: TextAlign.center)
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      child: const Text('Cancelar'),
                      onPressed: () {
                        SystemNavigator.pop();
                      },
                    ),
                    TextButton(
                      child: const Text('Actualizar'),
                      onPressed: () {
                        cargando = true;
                        setState(() {
                        });
                        print('Download URL: $downloadUrl');
                        _downloadAndInstallUpdate(context, downloadUrl);
                      },
                    ),
                  ],
                )
              ],
            ],
          ) : const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(child: Text('Descargando Actualización, espere por favor...')),
              SizedBox(height: 10,),
              Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
    
  }
   



   
  cargarDatos() async{
    await checkVersion(context);
    setState(() {
    });
  }

  Future<void> checkVersion(BuildContext context) async {
    try {
      packageInfo = await PackageInfo.fromPlatform();
      currentVersion = packageInfo.version;
      currentVersionParts = VersionCheckPage._parseVersion(currentVersion);
      final response = await http.get(Uri.parse('$apiUrl/api/config/version-check'));
      print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        minVersion = data['minVersion'];
        minVersionParts = VersionCheckPage._parseVersion(minVersion);
        latestVersion = data['latestVersion'];
        latestVersionParts = VersionCheckPage._parseVersion(latestVersion);
        downloadUrl = data['downloadUrl'];
      }
    } catch (e) {
      print('Error al verificar la versión: $e');
    }
  }


  Future<void> _downloadAndInstallUpdate(BuildContext context, String downloadUrl) async {
    try {
      bool canInstall = await _canInstallApk();
      // Create a temporary directory for the downloaded file
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/app-update.apk';
      // Download the APK file
      final dio = Dio();
      await dio.download(downloadUrl, filePath);
      // Install the APK
      if (canInstall){
        await _installApk(filePath);
        cargando = false;
        setState(() {});
      }else {
        print('No hay permisos para instlar la apk');
      }
      
    } catch (e) {
      print('Error downloading and installing update: $e');
      // Show an error dialog to the user
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('No se pudo descargar o instalar la actualización: $e'),
            actions: <Widget>[
              TextButton(
                child: const Text('Aceptar'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
  }

  Future<bool> _canInstallApk() async {
    final result = await Permission.requestInstallPackages.request();
    return result.isGranted;
  }

  Future<void> _installApk(String filePath) async {
    final result = await OpenFile.open(filePath);
    if (result.type == ResultType.done) {
      print("Installation started successfully.");
    } else {
      print("Failed to open the file: ${result.message}");
    }
  }
}  