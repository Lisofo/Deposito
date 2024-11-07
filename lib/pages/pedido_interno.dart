// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:deposito/config/router/routes.dart';
import 'package:deposito/widgets/custom_button.dart';
import 'package:intl/intl.dart';

class PedidoInterno extends StatefulWidget {
  const PedidoInterno({super.key});

  @override
  State<PedidoInterno> createState() => _PedidoInternoState();
}

class _PedidoInternoState extends State<PedidoInterno> {
  // late Orden orden;
  late int marcaId = 0;
  late final String _currentPosition = '';
  // late Ubicacion ubicacion = Ubicacion.empty();
  bool ejecutando = false;
  String token = '';

  @override
  void initState() {
    super.initState();
    // orden = context.read<OrdenProvider>().orden;
    // marcaId = context.read<OrdenProvider>().marcaId;
    // token = context.read<OrdenProvider>().token;
  }

  void _mostrarDialogoConfirmacion(String accion) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          surfaceTintColor: Colors.white,
          title: const Text('Confirmación'),
          content: Text('¿Estás seguro que deseas $accion el picking?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (accion == 'iniciar') {
                    //cambiarEstado('EN PROCESO');
                    Navigator.of(context).pop();
                    router.go('/pickingOrders/pickingInterno/picking');
                  } else {
                    //cambiarEstado('FINALIZADA');
                    Navigator.of(context).pop();
                  }
                });
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: colors.primary,
          title: const Text(
            'Pedido 1111', /*${orden.ordenTrabajoId},*/
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(5)),
                  height: 30,
                  child: const Center(
                    child: Text(
                      'Detalle',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Text(
                  'Nombre del cliente: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Text(
                  'Nombre cliente',
                  // orden.cliente.nombre,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'Codigo del cliente: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Text(
                  'Cod cliente',
                  //orden.cliente.codCliente,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'Fecha del Pedido: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  DateFormat('EEEE d, MMMM yyyy', 'es').format(DateTime.now()/*orden.fechaOrdenTrabajo*/),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Row(
                  children: [
                    Text(
                      'Direccion de entrega: ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    // IconButton(onPressed: (){
                    //   _launchMaps(orden.cliente.coordenadas);
                    // }, icon: Icon(Icons.person_pin, color: colors.primary))
                  ],
                ),
                const Text(
                  //orden.cliente.direccion,
                  'Direccion',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'Prioridad: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Text(
                  'prioridad',
                  // orden.cliente.telefono1,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Row(
                  children: [
                    Text(
                      'Estado: ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      //orden.estado,
                      'estado',
                      style: TextStyle(fontSize: 16),
                    )
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                const Row(
                  children: [
                    Text(
                      'Tipo de Orden: ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      //orden.tipoOrden.descripcion,
                      'tipo orden',
                      style: TextStyle(fontSize: 16))
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'Productos: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                // for (var i = 0; i < orden.servicio.length; i++) ...[
                  const Text(
                    'cantidad de productos',
                    // orden.servicio[i].descripcion,
                    style: TextStyle(fontSize: 16),
                  ),
                // ],
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'Notas del cliente: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: colors.primary,
                          width: 2),
                      borderRadius: BorderRadius.circular(5)),
                  child: TextFormField(
                    enabled: false,
                    minLines: 1,
                    maxLines: 100,
                    initialValue: 'Notas del cliente',//orden.cliente.notas,
                    decoration: const InputDecoration(
                        border: InputBorder.none,
                        fillColor: Colors.white,
                        filled: true),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'Instrucciones: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: colors.primary,
                          width: 2),
                      borderRadius: BorderRadius.circular(5)),
                  child: TextFormField(
                    enabled: false,
                    minLines: 1,
                    maxLines: 100,
                    initialValue: 'Instrucciones del cliente',//orden.instrucciones,
                    decoration: const InputDecoration(
                        border: InputBorder.none,
                        fillColor: Colors.white,
                        filled: true),
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          notchMargin: 10,
          elevation: 0,
          shape: const CircularNotchedRectangle(),
          color: Colors.grey.shade200,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CustomButton(
                clip: Clip.antiAlias,
                onPressed: () => _mostrarDialogoConfirmacion('iniciar'),
                text: 'Iniciar',   
                tamano: 16,
                // disabled: !(marcaId != 0 && orden.estado == 'PENDIENTE'),
              ),
              CustomButton(
                clip: Clip.antiAlias,
                onPressed: () => _mostrarDialogoConfirmacion('finalizar'),
                text: 'Finalizar',
                tamano: 16,
                //disabled: !(marcaId != 0 && orden.estado == 'EN PROCESO'),
              ),
              IconButton(
                onPressed: () async {
                  await volverAPendiente();
                },
                icon: Icon(Icons.backspace,
                  color: colors.primary)
                ),
            ],
          ),
        ),
      ),
    );
  }

 
  // cambiarEstado(String estado) async {
  //   if (!ejecutando) {
  //     ejecutando = true;

  //     await obtenerUbicacion();
  //     int ubicacionId = ubicacion.ubicacionId;
  //     int uId = context.read<OrdenProvider>().uId;

  //     String token = context.read<OrdenProvider>().token;

  //     await OrdenServices().patchOrden(context, orden, estado, ubicacionId, token);
  //     if (estado == 'EN PROCESO') {
  //       await RevisionServices().postRevision(uId, orden, token);
  //     }
  //     setState(() {});

  //     print('hola entrada');
  //     ejecutando = false;
  //   }
  // }

  // obtenerUbicacion() async {
  //   await getLocation();
  //   int uId = context.read<OrdenProvider>().uId;
  //   ubicacion.fecha = DateTime.now();
  //   ubicacion.usuarioId = uId;
  //   ubicacion.ubicacion = _currentPosition;

  //   String token = context.read<OrdenProvider>().token;

  //   await UbicacionServices().postUbicacion(context, ubicacion, token);
  // }

  // Future<void> getLocation() async {
  //   try {
  //     Position position = await Geolocator.getCurrentPosition(
  //         desiredAccuracy: LocationAccuracy.high);
  //     setState(() {
  //       _currentPosition = '${position.latitude}, ${position.longitude}';
  //       print('${position.latitude}, ${position.longitude}');
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _currentPosition = 'Error al obtener la ubicación: $e';
  //     });
  //   }
  // }

  Future<void> volverAPendiente(/*Orden orden*/) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          surfaceTintColor: Colors.white,
          title: const Text('ADVERTENCIA'),
          content: const Text(
            'Desea pasar a PENDIENTE el pedido?',
            style: TextStyle(fontSize: 20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar')
            ),
            TextButton(
              onPressed: () async {
                if (!ejecutando) {
                  ejecutando = true;
                  //await obtenerUbicacion();
                  // int ubicacionId = ubicacion.ubicacionId;
                  //await OrdenServices().patchOrden(context, orden, 'PENDIENTE', ubicacionId, token);
                  Navigator.of(context).pop();
                  setState(() {});
                  ejecutando = false;
                }
                // await OrdenServices.showDialogs(context, 'Estado cambiado a Pendiente', true, true);
                setState(() {});
              },
              child: const Text('Confirmar')
            )
          ],
        );
      }
    );
  }

  //  _launchMaps(String coordenadas) async {
  //   // Coordenadas a abrir en el mapa
  //   var coords = coordenadas.split(',');
  //   String latitude = coords[0]; // Latitud de ejemplo
  //   String longitude = coords[1]; // Longitud de ejemplo

  //   // URI con las coordenadas
  //   final Uri toLaunch = Uri(
  //       scheme: 'https',
  //       host: 'www.google.com',
  //       path: 'maps/search/',
  //       query: 'api=1&query=$latitude,$longitude');

  //   if (await launchUrl(toLaunch)) {
  //   } else {
  //     throw 'No se pudo abrir la url';
  //   }
  // }

}
