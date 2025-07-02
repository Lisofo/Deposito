import 'package:deposito/config/config_env.dart';
import 'package:deposito/models/entrega.dart';
import 'package:deposito/models/forma_envio.dart';
import 'package:deposito/models/modo_envio.dart';
import 'package:deposito/models/tipo_bulto.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class EntregaServices {
  final _dio = Dio();
  late String apirUrl = ConfigEnv.APIURL;
  late int? statusCode;

  Future<int?> getStatusCode () async {
    return statusCode;
  }

  Future<void> resetStatusCode () async {
    statusCode = null;
  }

  Future postEntrega(BuildContext context, List<int> pickIds, String token) async {
    String link = '$apirUrl/api/v1/entrega';
    var data = {
      "pickIds": pickIds
    };

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data
      );
      statusCode = 1;
      final Entrega entrega = Entrega.fromJson(resp.data);
      return entrega;
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
    }
  }

  Future formaEnvio(BuildContext context, String token) async {
    String link = '$apirUrl/api/v1/entrega/formasEnvio';

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
      final List<dynamic> formasEnvioList = resp.data;
      return formasEnvioList.map((obj) => FormaEnvio.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
    }
  }

  Future modoEnvio(BuildContext context, String token) async {
    String link = '$apirUrl/api/v1/entrega/modosEnvio';

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
      final List<dynamic> modosEnvioList = resp.data;
      return modosEnvioList.map((obj) => ModoEnvio.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
    }
  }

  Future tipoBulto(BuildContext context, String token) async {
    String link = '$apirUrl/api/v1/entrega/tiposBulto';

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
      final List<dynamic> tiposBultoList = resp.data;
      return tiposBultoList.map((obj) => TipoBulto.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
    }
  }

  void errorManagment(Object e, BuildContext context) {
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