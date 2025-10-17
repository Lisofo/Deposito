import 'package:deposito/config/config_env.dart';
import 'package:deposito/models/entrega.dart';
import 'package:deposito/models/forma_envio.dart';
import 'package:deposito/models/modo_envio.dart';
import 'package:deposito/models/retiro.dart';
import 'package:deposito/models/tipo_bulto.dart';
import 'package:deposito/models/bulto.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EntregaServices {
  final _dio = Dio();
  late String apirUrl = ConfigEnv.APIURL;
  late int? statusCode;

  Future<int?> getStatusCode() async {
    return statusCode;
  }

  Future<void> resetStatusCode() async {
    statusCode = null;
  }

  Future<Entrega> postEntrega(BuildContext context, List<int> pickIds, int almacenId, String token) async {
    String link = '$apirUrl/api/v1/entrega';
    var data = {
      "pickIds": pickIds,
      "almacenId": almacenId,
    };

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );
      statusCode = 1;
      final Entrega entrega = Entrega.fromJson(resp.data);
      return entrega;
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
      return Entrega.empty();
    }
  }

  Future<List<FormaEnvio>> formaEnvio(BuildContext context, String token) async {
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
      return [];
    }
  }

  Future<List<ModoEnvio>> modoEnvio(BuildContext context, String token) async {
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
      return [];
    }
  }

  Future<List<TipoBulto>> tipoBulto(BuildContext context, String token) async {
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
      return [];
    }
  }

  Future<List<Entrega>> getEntregas(BuildContext context, String token, {int? usuId, String? estado, DateTime? fechaDateDesde, DateTime? fechaDateHasta}) async {
    String link = '$apirUrl/api/v1/entrega';
    Map<String, dynamic> queryParams = {};
    if (estado != null && estado.isNotEmpty) queryParams['estado'] = estado;
    if (usuId != null && usuId != 0) queryParams['usuId'] = usuId;
    if (fechaDateDesde != null) queryParams['fechaDateDesde'] = DateFormat('yyyy-MM-dd').format(fechaDateDesde);
    if (fechaDateHasta != null) queryParams['fechaDateHasta'] = DateFormat('yyyy-MM-dd').format(fechaDateHasta);

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,
        ),
        queryParameters: queryParams
      );
      statusCode = 1;
      final List<dynamic> entregasList = resp.data;
      return entregasList.map((obj) => Entrega.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
      return [];
    }
  }

  Future<Entrega> getEntregaPorId (BuildContext context, String token, {int? entregaId}) async {
    String link = '$apirUrl/api/v1/entrega/$entregaId';

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
      
      return Entrega.fromJson(resp.data);
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
      return Entrega.empty();
    }
  }

  Future<Entrega> patchEntregaEstado(BuildContext context, int entregaId, String estado, String token) async {
    String link = '$apirUrl/api/v1/entrega/$entregaId';
    var data = {
      "estado": estado,
    };

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'PATCH',
          headers: headers,
        ),
        data: data,
      );
      statusCode = 1;
      return Entrega.fromJson(resp.data);
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
      return Entrega.empty();
    }
  }

  Future<Entrega> cerrarEntrega(BuildContext context, int entregaId, String token) async {
    String link = '$apirUrl/api/v1/entrega/$entregaId/cerrar';

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
      return Entrega.fromJson(resp.data);
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
      return Entrega.empty();
    }
  }

  Future<bool> verificarEntrega(BuildContext context, int entregaId, int bultoId, bool verificacionParcial, String token) async {
    String link = '$apirUrl/api/v1/entrega/$entregaId/verificar/$bultoId';
    var data = {
      'verificacionParcial' : verificacionParcial
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
      statusCode = resp.statusCode;
      return true;
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
      return false;
    }
  }

  Future<List<Bulto>> getBultosEntrega(BuildContext context, int entregaId, String token) async {
    String link = '$apirUrl/api/v1/entrega/$entregaId/bultos';

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
      final List<dynamic> bultosList = resp.data;
      return bultosList.map((obj) => Bulto.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
      return [];
    }
  }

  Future<Bulto> postBultoEntrega(BuildContext context, int entregaId, int tipoBultoId, String token) async {
    String link = '$apirUrl/api/v1/entrega/$entregaId/bultos';
    var data = {
      "tipoBultoId": tipoBultoId,
    };

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );
      statusCode = 1;
      return Bulto.fromJson(resp.data);
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
      return Bulto.empty();
    }
  }

  Future<Bulto> patchBultoEstado(BuildContext context, int entregaId, int bultoId, String estado, String token) async {
    String link = '$apirUrl/api/v1/entrega/$entregaId/bultos/$bultoId';
    var data = {
      "estado": estado,
    };

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'PATCH',
          headers: headers,
        ),
        data: data,
      );
      statusCode = 1;
      return Bulto.fromJson(resp.data);
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
      return Bulto.empty();
    }
  }

  Future<Bulto> putBultoEntrega(
    BuildContext context,
    int entregaId,
    int bultoId,
    int clienteId,
    String? nombreCliente,
    int modoEnvioId,
    int agenciaTrId,
    int agenciaUFId,
    String direccion,
    String localidad,
    String departamento,
    String telefono,
    String comentarioEnvio,
    String comentario,
    int tipoBultoId,
    bool incluyeFactura,
    int? nroBulto,
    int? totalBultos,
    String token,
  ) async {
    String link = '$apirUrl/api/v1/entrega/$entregaId/bultos/$bultoId';
    var data = {
      "clienteId": clienteId,
      "nombreCliente": nombreCliente,
      "modoEnvioId": modoEnvioId,
      "agenciaTrId": agenciaTrId,
      "agenciaUFId": agenciaUFId,
      "direccion": direccion,
      "localidad": localidad,
      "departamento": departamento,
      "telefono": telefono,
      "comentarioEnvio": comentarioEnvio,
      "comentario": comentario,
      "tipoBultoId": tipoBultoId,
      "incluyeFactura": incluyeFactura,
      "nroBulto": nroBulto,
      "totalBultos": totalBultos,
    };

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'PUT',
          headers: headers,
        ),
        data: data,
      );
      statusCode = 1;
      return Bulto.fromJson(resp.data);
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
      return Bulto.empty();
    }
  }

  Future<List<BultoItem>> getItemsBulto(BuildContext context, int entregaId, int bultoId, String token) async {
    String link = '$apirUrl/api/v1/entrega/$entregaId/bultos/$bultoId/items';

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
      final List<dynamic> itemsList = resp.data;
      return itemsList.map((obj) => BultoItem.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
      return [];
    }
  }

  Future<void> patchItemBulto(
    BuildContext context,
    int entregaId,
    int bultoId,
    int pickLineaId,
    int conteo,
    String token,
  ) async {
    String link = '$apirUrl/api/v1/entrega/$entregaId/bultos/$bultoId/items';
    var data = {
      "pickLineaId": pickLineaId,
      "conteo": conteo,
    };

    try {
      var headers = {'Authorization': token};
      await _dio.request(
        link,
        options: Options(
          method: 'PATCH',
          headers: headers,
        ),
        data: data,
      );
      statusCode = 1;
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
    }
  }

  Future<List<Bulto>> getBultos(BuildContext context, String token, 
    {
      int? usuId, 
      String? estado, 
      bool? retirado,
      // Nuevos parámetros de filtro
      int? bultoId,
      int? entregaId,
      int? clienteId,
      String? nombreCliente,
      String? fechaDateDesde,
      String? fechaDateHasta,
      String? fechaBultoDesde,
      String? fechaBultoHasta,
      int? almacenId,
      int? modoEnvioId,
      int? agenciaTrId,
      String? comentarioEnvio,
      String? direccion,
      String? localidad,
      String? telefono,
      int? agenciaUFId,
      int? tipoBultoId,
      String? comentario,
      int? retiroId,
      int? armadoPorUsuId,
      int? nroBulto,
      int? totalBultos,
      int? despachoId,
      int? devolucionId,
      bool? incluyeFactura,
      int? offset,
      int? limit,
      String? sort,
    }
  ) async {
    String link = '$apirUrl/api/v1/bultos';
    Map<String, dynamic> queryParams = {};
    
    // Parámetros originales
    if (estado != null && estado.isNotEmpty) queryParams['estado'] = estado;
    if (usuId != null && usuId != 0) queryParams['usuId'] = usuId;
    if (retirado == false) queryParams['retirado'] = retirado;

    // Nuevos parámetros de filtro
    if (bultoId != null) queryParams['bultoId'] = bultoId;
    if (entregaId != null) queryParams['entregaId'] = entregaId;
    if (clienteId != null) queryParams['clienteId'] = clienteId;
    if (nombreCliente != null && nombreCliente.isNotEmpty) queryParams['nombreCliente'] = nombreCliente;
    if (fechaDateDesde != null) queryParams['fechaDateDesde'] = fechaDateDesde;
    if (fechaDateHasta != null) queryParams['fechaDateHasta'] = fechaDateHasta;
    if (fechaBultoDesde != null) queryParams['fechaBultoDesde'] = fechaBultoDesde;
    if (fechaBultoHasta != null) queryParams['fechaBultoHasta'] = fechaBultoHasta;
    if (almacenId != null) queryParams['almacenId'] = almacenId;
    if (modoEnvioId != null) queryParams['modoEnvioId'] = modoEnvioId;
    if (agenciaTrId != null) queryParams['agenciaTrId'] = agenciaTrId;
    if (comentarioEnvio != null && comentarioEnvio.isNotEmpty) queryParams['comentarioEnvio'] = comentarioEnvio;
    if (direccion != null && direccion.isNotEmpty) queryParams['direccion'] = direccion;
    if (localidad != null && localidad.isNotEmpty) queryParams['localidad'] = localidad;
    if (telefono != null && telefono.isNotEmpty) queryParams['telefono'] = telefono;
    if (agenciaUFId != null) queryParams['agenciaUFId'] = agenciaUFId;
    if (tipoBultoId != null) queryParams['tipoBultoId'] = tipoBultoId;
    if (comentario != null && comentario.isNotEmpty) queryParams['comentario'] = comentario;
    if (retiroId != null) queryParams['retiroId'] = retiroId;
    if (armadoPorUsuId != null) queryParams['armadoPorUsuId'] = armadoPorUsuId;
    if (nroBulto != null) queryParams['nroBulto'] = nroBulto;
    if (totalBultos != null) queryParams['totalBultos'] = totalBultos;
    if (despachoId != null) queryParams['despachoId'] = despachoId;
    if (devolucionId != null) queryParams['devolucionId'] = devolucionId;
    if (incluyeFactura != null) queryParams['incluyeFactura'] = incluyeFactura;
    if (offset != null) queryParams['offset'] = offset;
    if (limit != null) queryParams['limit'] = limit;
    if (sort != null && sort.isNotEmpty) queryParams['sort'] = sort;

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
      final List<dynamic> bultoList = resp.data;
      return bultoList.map((obj) => Bulto.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
      return [];
    }
  }

  Future<Retiro> getRetiroBulto(BuildContext context, int bultoId, String token) async {
    String link = '$apirUrl/api/v1/bultos/$bultoId/retiro';

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
      return Retiro.fromJson(resp.data);
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
      return Retiro.empty();
    }
  }

  Future<Retiro> postRetiroBulto(
    BuildContext context,
    List<int> bultoIds,
    int agenciaTrId,
    String retiradoPor,
    String comentario,
    String token,
  ) async {
    String link = '$apirUrl/api/v1/bultos/retiro';
    var data = {
      "bultoIds": bultoIds,
      "agenciaTrId": agenciaTrId,
      "retiradoPor": retiradoPor,
      "comentario": comentario,
    };

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );
      statusCode = 1;
      return Retiro.fromJson(resp.data);
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
      return Retiro.empty();
    }
  }

  Future<void> postDevolucionBulto(
    BuildContext context,
    List<int> bultoId,
    String devueltoPor,
    String comentario,
    String token,
  ) async {
    String link = '$apirUrl/api/v1/bultos/devolucion';
    var data = {
      "bultoIds": bultoId,
      "devueltoPor": devueltoPor,
      "comentario": comentario,
    };

    try {
      var headers = {'Authorization': token};
      await _dio.request(
        link,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );
      statusCode = 1;
      return;
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
    }
  }

  Future<void> postImprimirRetiro(
    BuildContext context,
    int retiroId,
    int almacenId,
    String token,
  ) async {
    String link = '$apirUrl/api/v1/bultos/retiro/$retiroId/imprimirRetiro';
    var data = {
      "almacenId" : almacenId
    };

    try {
      var headers = {'Authorization': token};
      await _dio.request(
        link,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data
      );
      statusCode = 1;
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
    }
  }

  Future<void> imprimirEtiqueta(
    BuildContext context,
    int bultoId,
    int almacenId,
    String token,
  ) async {
    String link = '$apirUrl/api/v1/bultos/$bultoId/imprimirEtiqueta';
    var data = {
      "almacenId" : almacenId
    };

    try {
      var headers = {'Authorization': token};
      await _dio.request(
        link,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data
      );
      statusCode = 1;
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
    }
  }
  
  Future<void> imprimirDetalle(
    BuildContext context,
    int bultoId,
    int almacenId,
    String token,
  ) async {
    String link = '$apirUrl/api/v1/bultos/$bultoId/imprimirDetalles';
    var data = {
      "almacenId" : almacenId
    };

    try {
      var headers = {'Authorization': token};
      await _dio.request(
        link,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data
      );
      statusCode = 1;
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
    }
  }

  Future<List<Retiro>> getRetiros(BuildContext context, String token) async {
    String link = '$apirUrl/api/v1/bultos/retiro';

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

      final List<dynamic> retirosList = resp.data;
      return retirosList.map((obj) => Retiro.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      errorManagment(e, context);
      return [];
    }
  }

  void errorManagment(Object e, BuildContext context) {
    if (e is DioException) {
      if (e.response != null) {
        final responseData = e.response!.data;
        if (responseData != null) {
          if (e.response!.statusCode == 403) {
            Carteles.showErrorDialog(context, 'Error: ${e.response!.data['message']}');
          }else if (e.response!.statusCode! >= 500) {
            Carteles.showErrorDialog(context, 'Error: No se pudo completar la solicitud');
          } else {
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