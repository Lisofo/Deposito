import 'package:deposito/config/config_env.dart';
import 'package:deposito/models/client.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ClientServices {
  final _dio = Dio();
  late String apirUrl = ConfigEnv.APIURL;
  late int? statusCode;

  Future getClientes (BuildContext context, String nombre, String ruc, String codCliente, String almacen, String token) async {
    String link =  '$apirUrl/api/v1/clientes?almacenId=$almacen';
    bool yaTieneFiltro = true;
    if (nombre != '') {
      link += '&nombre=$nombre';
      yaTieneFiltro = true;
    }
    if (codCliente != '') {
      yaTieneFiltro ? link += '&' : link += '?';
      link += 'codCliente=$codCliente';
      yaTieneFiltro = true;
    }
   

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
      final List<dynamic> clientList = resp.data;
      return clientList.map((obj) => Client.fromJson(obj)).toList();
    } catch (e) {
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