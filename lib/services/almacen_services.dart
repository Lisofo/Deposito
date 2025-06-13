import 'package:deposito/config/config_env.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/conteo.dart';
import 'package:deposito/models/item_consulta.dart';
import 'package:deposito/models/items_x_ubicacion.dart';
import 'package:deposito/models/resumen_general.dart';
import 'package:deposito/models/ubicacion_almacen.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class AlmacenServices {
  final _dio = Dio();
  late String apirUrl = ConfigEnv.APIURL;
  late int? statusCode;

  Future<int?> getStatusCode () async {
    return statusCode;
  }

  Future<void> resetStatusCode () async {
    statusCode = null;
  }

  Future getAlmacenes(BuildContext context, String token) async {
    String link =  '$apirUrl/api/v1/almacenes';

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
      final List<dynamic> almacenesList = resp.data;
      return almacenesList.map((obj) => Almacen.fromJson(obj)).toList();
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

  Future getUbicacionDeAlmacen(BuildContext context, int almacenId, token) async {
    String link = '$apirUrl/api/v1/almacenes/$almacenId/ubicaciones';

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
      final List<dynamic> ubicacionAlmacenesList = resp.data;
      return ubicacionAlmacenesList.map((obj) => UbicacionAlmacen.fromJson(obj)).toList();
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

  Future getItemXUbicacion(BuildContext context, int almacenId, int almacenUbicacionId, token) async {
    String link = '$apirUrl/api/v1/almacenes/$almacenId/ubicaciones/$almacenUbicacionId/items';

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
      final List<dynamic> itemList = resp.data;
      return itemList.map((obj) => ItemConsulta.fromJson(obj)).toList();
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

  Future getItemPorUbicacionDeAlmacen(BuildContext context, int almacenId, String codItem, String token) async {
    String link = '$apirUrl/api/v1/items/ubicaciones?almacenId=$almacenId&codItem=$codItem';

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
      final List<dynamic> itemXUbicacionAlmacenesList = resp.data;
      return itemXUbicacionAlmacenesList.map((obj) => ItemsPorUbicacion.fromJson(obj)).toList();
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

  Future postUbicacionItemEnAlmacen(BuildContext context, String codItem, String codUbicacion, int almacenId, int min, int max, String token) async {
    String link = '$apirUrl/api/v1/items/$codItem/ubicaciones';

    var data = ({
      "codUbicacion": codUbicacion,
      "almacenId": almacenId,
      "existenciaMaxima": max,
      "existenciaMinima": min,
    });

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
      if(resp.statusCode == 200){
        return resp.data;
      }
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

  Future putUbicacionItemEnAlmacen(BuildContext context, String codItem, int almacenUbicacionId, int min, int max, String token) async {
    String link = '$apirUrl/api/v1/items/$codItem/ubicaciones/$almacenUbicacionId';

    var data = ({
      "existenciaMaxima": max,
      "existenciaMinima": min,
    });

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
      if(resp.statusCode == 200){
        return resp.data;
      }
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

  Future deleteUbicacionItemEnAlmacen(BuildContext context, String codItem, int almacenUbicacionId, String token) async {
    String link = '$apirUrl/api/v1/items/$codItem/ubicaciones/$almacenUbicacionId';

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'DELETE',
          headers: headers,
        ),
      );
      statusCode = 1;
      if(resp.statusCode == 204){
        return;
      }
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

  Future patchUbicacionItemEnAlmacen(BuildContext context, String codItem, int almacenId, int almacenUbicacionId, bool conConteo, int conteo, String token) async {
    String link = '$apirUrl/api/v1/inventario/$almacenId';

    var data1 = ({
      "codItem": codItem,
      "almacenUbicacionId": almacenUbicacionId,
    });

    var data2 = ({
      "codItem": codItem,
      "almacenUbicacionId": almacenUbicacionId,
      "conteo": conteo
    });

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'PATCH',
          headers: headers,
        ),
        data: conConteo ? data2 : data1
      );
      statusCode = 1;
      if(resp.statusCode == 200){
        return resp.data;
      }
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

  Future getConteoUbicacion(BuildContext context, int almacenId, int almacenUbicacionId, String token) async {
    String link = almacenUbicacionId != 0 ? '$apirUrl/api/v1/inventario/$almacenId?almacenUbicacionId=$almacenUbicacionId' : '$apirUrl/api/v1/inventario/$almacenId';

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
      final List<dynamic> conteoList = resp.data;
      return conteoList.map((obj) => Conteo.fromJson(obj)).toList();
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

  Future getInventarioGeneral(BuildContext context, int almacenId, int usuarioId, String token) async {
    String link = '$apirUrl/api/v1/inventario/$almacenId/general?usuarioId=$usuarioId';

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
      final List<dynamic> conteoList = resp.data;
      return conteoList.map((obj) => Conteo.fromJson(obj)).toList();
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

  Future postInventarioGeneral(BuildContext context, int almacenId, int usuarioId, String token) async {
    String link = '$apirUrl/api/v1/inventario/$almacenId/general?usuarioId=$usuarioId';
    print(link);
    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
      );
      statusCode = 1;
      if(resp.statusCode == 201){
        return resp.data;
      }
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

  Future deleteConteo(BuildContext context, int almacenId, int almacenUbicacionId, int itemId, String token) async {
    String link = '$apirUrl/api/v1/inventario/$almacenId';

    if(almacenUbicacionId != 0) {
      link += '?almacenUbicacionId=$almacenUbicacionId';
      if(itemId != 0) {
        link += '&itemId=$itemId';
      }
    } 

    print(link);

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'DELETE',
          headers: headers,
        ),
      );
      statusCode = 1;
      if(resp.statusCode == 204){
        return resp.data;
      }
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

  Future postTransferencia(BuildContext context, String codItem, int almacenId, int almacenIdOrigen, int almacenIdDestino, int cantidad, String token) async {
    String link = '$apirUrl/api/v1/movimientos/$almacenId/ubicaciones';

    var data = ({
      "codItem": codItem,
      "almacenUbicacionIdOrigen": almacenIdOrigen,
      "almacenUbicacionIdDestino": almacenIdDestino,
      "cantidad": cantidad 
    });

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
      if(resp.statusCode == 200){
        return resp.data;
      }
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

  Future confirmarConteo(BuildContext context, int almacenId, String token) async {
    String link = '$apirUrl/api/v1/inventario/$almacenId';

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
      );
      statusCode = 1;
      if(resp.statusCode == 200){
        return resp.data;
      }
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

  Future getResumen(BuildContext context, int almacenId, String token) async {
    String link = '$apirUrl/api/v1/inventario/$almacenId/resumen';

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
      final List<dynamic> resumenList = resp.data;
      return resumenList.map((obj) => ResumenGeneral.fromJson(obj)).toList();
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

  Future deleteInventarioUsuario(BuildContext context, int almacenId, int usuarioId, String token) async {
    String link = '$apirUrl/api/v1/inventario/$almacenId/general?usuarioId=$usuarioId';

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'DELETE',
          headers: headers,
        ),
      );
      statusCode = 1;
      if(resp.statusCode == 204){
        return;
      }
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