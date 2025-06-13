import 'package:deposito/config/config_env.dart';
import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

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

  Future getOrdenesPicking (BuildContext context, String tipo, String token) async {
    var ruta = tipo.split('-');
    var rutaSplitted = ruta[1];

    String link = '$apirUrl/api/v1/ordenpicking?tipo=$rutaSplitted';

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,
        )
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