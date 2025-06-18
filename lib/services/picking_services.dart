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

  Future getOrdenesPicking(BuildContext context, String token, {
    String? tipo,
    String? prioridad,
    String? codEntidad,
    DateTime? fechaDateDesde,
    DateTime? fechaDateHasta,
    DateTime? fechaDocumentoDesde,
    DateTime? fechaDocumentoHasta,
    String? estado,
    String? ruc,
    String? serie,
    String? numeroDocumento,
    String? almacenIdOrigen,
    String? almacenIdDestino,
    String? localidad,
    int? usuId,
    int? modUsuId,
  }) async {
    String link = '$apirUrl/api/v1/ordenpicking';
    Map<String, dynamic> queryParams = {};
    if (tipo != null && tipo.isNotEmpty) queryParams['tipo'] = tipo;
    if (prioridad != null && prioridad.isNotEmpty) queryParams['prioridad'] = prioridad;
    if (codEntidad != null && codEntidad.isNotEmpty) queryParams['codEntidad'] = codEntidad;
    if (fechaDateDesde != null) queryParams['fechaDateDesde'] = DateFormat('yyyy-MM-dd').format(fechaDateDesde);
    if (fechaDateHasta != null) queryParams['fechaDateHasta'] = DateFormat('yyyy-MM-dd').format(fechaDateHasta);
    if (fechaDocumentoDesde != null) queryParams['fechaDocumentoDesde'] = DateFormat('yyyy-MM-dd').format(fechaDocumentoDesde);
    if (fechaDocumentoHasta != null) queryParams['fechaDocumentoHasta'] = DateFormat('yyyy-MM-dd').format(fechaDocumentoHasta);
    if (estado != null && estado.isNotEmpty) queryParams['estado'] = estado;
    if (ruc != null && ruc.isNotEmpty) queryParams['ruc'] = ruc;
    if (serie != null && serie.isNotEmpty) queryParams['serie'] = serie;
    if (numeroDocumento != null && numeroDocumento.isNotEmpty) queryParams['numeroDocumento'] = numeroDocumento;
    if (almacenIdOrigen != null && almacenIdOrigen.isNotEmpty) queryParams['almacenIdOrigen'] = almacenIdOrigen;
    if (almacenIdDestino != null && almacenIdDestino.isNotEmpty) queryParams['almacenIdDestino'] = almacenIdDestino;
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

  Future patchPicking (BuildContext context, int pickId, String codItem, int almacenUbicacionId, int conteo, String token) async {
    String link = '$apirUrl/api/v1/ordenpicking/$pickId/items';
    var data = {
      "codItem": codItem,
      "almacenUbicacionId": almacenUbicacionId,
      "conteo": conteo
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
      final PickingLinea linea = PickingLinea.fromJson(resp.data);
      return linea;
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
}