import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:deposito/config/router/router.dart';

class ListaPedidos extends StatefulWidget {
  const ListaPedidos({super.key});

  @override
  State<ListaPedidos> createState() => _ListaPedidosState();
}

DateTime fecha = DateTime.now();

String fechaHoy = '${fecha.year}-${fecha.month}-${fecha.day}';
String fechaManana = '${fecha.year}-${fecha.month}-${fecha.day + 1}';
List<String> fechas = [fechaHoy, fechaManana, 'Anteriores'];

class _ListaPedidosState extends State<ListaPedidos> {
  List listPickings = [
    'Picking 1',
    'Picking 2',
    'Picking 3',
  ];

  String token = '';
  //List<Orden> ordenes = [];
  late int tecnicoId = 0;
  int groupValue = 0;
  List trabajodres = [];
  // 1. Agrega una clave global para el RefreshIndicator
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  // List<Orden> get ordenesFiltradas {
  //   if (groupValue == 0) {
  //     return ordenes.where((orden) => orden.estado == 'PENDIENTE').toList();
  //   } else if (groupValue == 1) {
  //     return ordenes.where((orden) => orden.estado == 'EN PROCESO').toList();
  //   } else if (groupValue == 2) {
  //     return ordenes.where((orden) => orden.estado == 'FINALIZADA').toList();
  //   }
  //   return [];
  // }

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  // 2. Método para manejar la actualización de datos
  Future<void> _refreshData() async {
    await cargarDatos();
  }

  cargarDatos() async {
    // token = context.read<OrdenProvider>().token;
    // tecnicoId = context.read<OrdenProvider>().tecnicoId;
    // ordenes = await ordenServices.getOrden(tecnicoId.toString(), opcionActual, opcionActual, token);

    // Provider.of<OrdenProvider>(context, listen: false).setOrdenes(ordenes);

    setState(() {});
  }
  
  String opcionActual = fechas[0];
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton.filledTonal(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(colors.primary)
            ),
            onPressed: () async {
              appRouter.go('/almacen/menu');
            },
            icon: const Icon(Icons.arrow_back,),
          ),
          backgroundColor: colors.primary,
          title: const Text(
            'Lista de Pedidos',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: IconThemeData(color: colors.onPrimary),
          
        ),
        backgroundColor: Colors.grey.shade200,
        body: Column(
          children: [
            CupertinoSegmentedControl<int>(
              padding: const EdgeInsets.all(10),
              groupValue: groupValue,
              borderColor: Colors.black,
              selectedColor: colors.primary,
              unselectedColor: Colors.white,
              children: {
                0: buildSegment('Pendiente'),
                1: buildSegment('En Proceso'),
                2: buildSegment('Finalizado'),
              },
              onValueChanged: (newValue) {
                setState(() {
                  groupValue = newValue;
                });
              },
            ),
            Expanded(
              child: RefreshIndicator(
                key: _refreshIndicatorKey,
                onRefresh: _refreshData,
                child: ListView.builder(
                  itemCount: listPickings.length,
                  itemBuilder: (context, i) {
                    return Card(
                      surfaceTintColor: Colors.white,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                        side: const BorderSide(
                          color: Colors.black,
                          width: 1,
                        ),
                      ),
                      elevation: 20,
                      child: InkWell(
                        onTap: () {
                          // final orden = ordenesFiltradas[i];
                          // context.read<OrdenProvider>().setOrden(orden);

                          appRouter.push('/pickingInterno');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    '1111',//ordenesFiltradas[i].ordenTrabajoId.toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    DateFormat('EEEE d, MMMM yyyy', 'es').format(DateTime.now()/*ordenesFiltradas[i].fechaOrdenTrabajo*/),
                                  ),
                                  const Expanded(child: Text('')),
                                  const Text('Descripcion')//ordenesFiltradas[i].tipoOrden.descripcion),
                                ],
                              ),
                              const Text('Codigo cliente - nombre'),//'${ordenesFiltradas[i].cliente.codCliente} - ${ordenesFiltradas[i].cliente.nombre}',),
                              const Text('Metodo de entrega'/*ordenesFiltradas[i].cliente.direccion*/),
                              const Text('Prioridad'),//ordenesFiltradas[i].cliente.telefono1),
                              const Text('Notas'/*ordenesFiltradas[i].cliente.notas*/),
                              //for (var j = 0; j < ordenesFiltradas[i].servicio.length; j++) ...[
                                const Text('Servicios'),//ordenesFiltradas[i].servicio[j].descripcion,)
                                const Text('Cantidad de productos: 100')//ordenesFiltradas[i].servicio[j].descripcion,)
                              //],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSegment(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15),
      ),
    );
  }
}
