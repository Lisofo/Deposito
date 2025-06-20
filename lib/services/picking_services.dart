import 'package:deposito/config/config_env.dart';
import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/models/usuario.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PickingServices {
  final _dio = Dio();
  late String apirUrl = ConfigEnv.APIURL;
  late int? statusCode;

  Future<int?> getStatusCode () async {
    return statusCode;
  }

  Future<void> resetStatusCode () async {
    statusCode = null;
  }

  Future getUsuarios(BuildContext context, String token) async {
    String link = '$apirUrl/api/v1/usuarios';
    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );
      statusCode = 1;
      final List<dynamic> usersList = resp.data;
      return usersList.map((obj) => Usuario.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          if (responseData != null) {
            if(e.response!.statusCode == 403){
              Carteles.showErrorDialog(context, 'Error: ${e.response!.data['message']}');
            }else if(e.response!.statusCode! >= 500) {
              Carteles.showErrorDialog(context, 'Error: No se pudo completar la solicitud');
            } else{
              final errors = responseData['errors'] as List<dynamic>;
              final errorMessages = errors.map((error) {
                return "Error: ${error['message']}";
              }).toList();
              Carteles.showErrorDialog(context, errorMessages.join('\n'));
            }
          } else {
            Carteles.showErrorDialog(context, 'Error: ${e.response!.data}');
          }
        } else {
          Carteles.showErrorDialog(context, 'Error: No se pudo completar la solicitud');
        } 
      }
    }
  }

  Future getOrdenesPicking(BuildContext context, int almacenIdOrigen, String token, {
    String? tipo,
    String? prioridad,
    DateTime? fechaDateDesde,
    DateTime? fechaDateHasta,
    String? estado,
    String? numeroDocumento,
    String? localidad,
    String? nombre,
    int? usuId,
    int? modUsuId,
  }) async {
    String link = '$apirUrl/api/v1/ordenpicking';
    Map<String, dynamic> queryParams = {};
    if (tipo != null && tipo.isNotEmpty) queryParams['tipo'] = tipo;
    if (prioridad != null && prioridad.isNotEmpty) queryParams['prioridad'] = prioridad;
    if (fechaDateDesde != null) queryParams['fechaDateDesde'] = DateFormat('yyyy-MM-dd').format(fechaDateDesde);
    if (fechaDateHasta != null) queryParams['fechaDateHasta'] = DateFormat('yyyy-MM-dd').format(fechaDateHasta);
    if (estado != null && estado.isNotEmpty) queryParams['estado'] = estado;
    if (numeroDocumento != null && numeroDocumento.isNotEmpty) queryParams['numeroDocumento'] = numeroDocumento;
    if (nombre != null && nombre.isNotEmpty) queryParams['nombre'] = nombre;
    if (almacenIdOrigen != 0) queryParams['almacenIdOrigen'] = almacenIdOrigen;
    if (localidad != null && localidad.isNotEmpty) queryParams['localidad'] = localidad;
    if(usuId != null && usuId != 0) queryParams['usuId'] = usuId;
    if(modUsuId != null && modUsuId != 0) queryParams['modUsuId'] = modUsuId;

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,
        ),
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      statusCode = 1;
      final List<dynamic> pickingList = resp.data;
      return pickingList.map((obj) => OrdenPicking.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          if (responseData != null) {
            if(e.response!.statusCode == 403){
              Carteles.showErrorDialog(context, 'Error: ${e.response!.data['message']}');
            }else if(e.response!.statusCode! >= 500) {
              Carteles.showErrorDialog(context, 'Error: No se pudo completar la solicitud');
            } else{
              final errors = responseData['errors'] as List<dynamic>;
              final errorMessages = errors.map((error) {
                return "Error: ${error['message']}";
              }).toList();
              Carteles.showErrorDialog(context, errorMessages.join('\n'));
            }
          } else {
            Carteles.showErrorDialog(context, 'Error: ${e.response!.data}');
          }
        } else {
          Carteles.showErrorDialog(context, 'Error: No se pudo completar la solicitud');
        } 
      }
    } 
  }

  Future getLineasOrder (BuildContext context, int pickId, int almacenId, String token) async {
    String link = '$apirUrl/api/v1/ordenpicking/$pickId?almacenId=$almacenId';
    
    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );
      statusCode = 1;
      final OrdenPicking orden = OrdenPicking.fromJson(resp.data);
      return orden;
    } catch (e) {
      statusCode = 0;
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          if (responseData != null) {
            if(e.response!.statusCode == 403){
              Carteles.showErrorDialog(context, 'Error: ${e.response!.data['message']}');
            }else if(e.response!.statusCode! >= 500) {
              Carteles.showErrorDialog(context, 'Error: No se pudo completar la solicitud');
            } else{
              final errors = responseData['errors'] as List<dynamic>;
              final errorMessages = errors.map((error) {
                return "Error: ${error['message']}";
              }).toList();
              Carteles.showErrorDialog(context, errorMessages.join('\n'));
            }
          } else {
            Carteles.showErrorDialog(context, 'Error: ${e.response!.data}');
          }
        } else {
          Carteles.showErrorDialog(context, 'Error: No se pudo completar la solicitud');
        } 
      }
    } 
  }

  Future putOrderPicking (BuildContext context, int pickId, String estado, String token) async {
    String link = '$apirUrl/api/v1/ordenpicking/$pickId';
    var data = {
      "estado": estado
    };
    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'PUT',
          headers: headers,
        ),
        data: data
      );
      statusCode = 1;
      final OrdenPicking orden = OrdenPicking.fromJson(resp.data);
      return orden;
    } catch (e) {
      statusCode = 0;
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          if (responseData != null) {
            if(e.response!.statusCode == 403){
              Carteles.showErrorDialog(context, 'Error: ${e.response!.data['message']}');
            }else if(e.response!.statusCode! >= 500) {
              Carteles.showErrorDialog(context, 'Error: No se pudo completar la solicitud');
            } else{
              final errors = responseData['errors'] as List<dynamic>;
              final errorMessages = errors.map((error) {
                return "Error: ${error['message']}";
              }).toList();
              Carteles.showErrorDialog(context, errorMessages.join('\n'));
            }
          } else {
            Carteles.showErrorDialog(context, 'Error: ${e.response!.data}');
          }
        } else {
          Carteles.showErrorDialog(context, 'Error: No se pudo completar la solicitud');
        } 
      }
    }
  }

  Future<Map<String, dynamic>> patchPicking(BuildContext context, int pickId, String codItem, int almacenUbicacionId, int conteo, int pickLineaId, String token) async {
    String link = '$apirUrl/api/v1/ordenpicking/$pickId/items';
    var data = {
      "codItem": codItem,
      "almacenUbicacionId": almacenUbicacionId,
      "conteo": conteo,
      "pickLineaId": pickLineaId
    };
    
    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'PATCH',
          headers: headers,
        ),
        data: data
      );
      
      statusCode = 1;
      
      // Devuelve el JSON completo para su procesamiento
      return resp.data; 
      
    } catch (e) {
      statusCode = 0;
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          if (responseData != null) {
            if(e.response!.statusCode == 403){
              Carteles.showErrorDialog(context, 'Error: ${e.response!.data['message']}');
            }else if(e.response!.statusCode! >= 500) {
              Carteles.showErrorDialog(context, 'Error: No se pudo completar la solicitud');
            } else{
              final errors = responseData['errors'] as List<dynamic>;
              final errorMessages = errors.map((error) {
                return "Error: ${error['message']}";
              }).toList();
              Carteles.showErrorDialog(context, errorMessages.join('\n'));
            }
          } else {
            Carteles.showErrorDialog(context, 'Error: ${e.response!.data}');
          }
        } else {
          Carteles.showErrorDialog(context, 'Error: No se pudo completar la solicitud');
        } 
      }
      rethrow; // Relanza la excepción para manejo adicional si es necesario
    }
  }
}