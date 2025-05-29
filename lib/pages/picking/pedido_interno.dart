import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/picking_services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PedidoInterno extends StatefulWidget {
  const PedidoInterno({super.key});

  @override
  State<PedidoInterno> createState() => _PedidoInternoState();
}

class _PedidoInternoState extends State<PedidoInterno> {
  late OrdenPicking orderProvider = OrdenPicking.empty();
  late OrdenPicking order = OrdenPicking.empty();
  bool ejecutando = false;
  String token = '';
  late Almacen almacen = Almacen.empty();


  @override
  void initState() {
    super.initState();
    cargarData();
  }

  void cargarData() async {
    orderProvider = context.read<ProductProvider>().ordenPicking;
    token = context.read<ProductProvider>().token;
    almacen = context.read<ProductProvider>().almacen;
    order = await PickingServices().getLineasOrder(context, orderProvider.pickId, almacen.almacenId, token);
    print(order);
    setState(() {});
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
          title: Text(
            'Orden ${order.numeroDocumento}',
            style: const TextStyle(color: Colors.white),
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
                const SizedBox(height: 20),
                const Text(
                  'Cliente/Proveedor: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  order.nombre,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Fecha del Pedido: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  DateFormat('EEEE d, MMMM yyyy', 'es').format(order.fechaDate),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Estado: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    Text(
                      order.estado,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.estado),
                        shape: BoxShape.circle,
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tipo de Orden: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  order.tipo == 'inbound' ? 'Entrada' : 'Salida',
                  style: const TextStyle(fontSize: 16)
                ),
                const SizedBox(height: 10),
                if (order.prioridad != '') ...[
                  const Text(
                    'Prioridad: ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    order.prioridad,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                ],
                const Text(
                  'Productos: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (order.lineas!.isEmpty)
                  const Text(
                    'No hay productos en esta orden',
                    style: TextStyle(fontSize: 16),
                  )
                else
                  ...order.lineas!.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.inventory),
                        title: Text(item.descripcion),
                        subtitle: Text('Código: ${item.codItem}'),
                        trailing: Text('${item.cantidadPedida} uds'),
                      ),
                    ),
                  )),
                const SizedBox(height: 10),
                const Text(
                  'Comentario: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colors.primary,
                      width: 2
                    ),
                    borderRadius: BorderRadius.circular(5)
                  ),
                  child: TextFormField(
                    enabled: false,
                    minLines: 1,
                    maxLines: 100,
                    initialValue: order.comentario == '' ? 'No hay comentario' : order.comentario,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      fillColor: Colors.white,
                      filled: true
                    ),
                  ),
                ),
                const SizedBox(height: 15),
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
              ElevatedButton(
                onPressed: () => _mostrarDialogoConfirmacion(order.estado == 'PENDIENTE' ? 'iniciar' : 'continuar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  order.estado == 'PENDIENTE' ? 'Iniciar' : 'Continuar',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              ElevatedButton(
                onPressed: () => _mostrarDialogoConfirmacion('finalizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text(
                  'Finalizar',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              IconButton(
                onPressed: () async {
                  await volverAPendiente();
                },
                icon: Icon(
                  Icons.backspace,
                  color: colors.primary
                )
              ),
            ],
          ),
        ),
      ),
    );
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
              onPressed: () async {
                if (accion == 'iniciar') {
                  orderProvider = await PickingServices().putOrderPicking(context, order.pickId, 'en proceso', token);
                  order.estado = orderProvider.estado;
                  Provider.of<ProductProvider>(context, listen: false).setOrdenPickingInterna(order);
                  Navigator.of(context).pop();
                  appRouter.push('/pickingProductos');
                } else if(accion == 'finalizar') {
                  orderProvider = await PickingServices().putOrderPicking(context, order.pickId, 'cerrado', token);
                  order.estado = orderProvider.estado;
                  Provider.of<ProductProvider>(context, listen: false).setOrdenPickingInterna(OrdenPicking.empty());
                  Navigator.of(context).pop();
                } else if(accion == 'continuar') {
                  Provider.of<ProductProvider>(context, listen: false).setOrdenPickingInterna(order);
                  Navigator.of(context).pop();
                  appRouter.push('/pickingProductos');
                }
                setState(() {});
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> volverAPendiente() async {
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
                  orderProvider = await PickingServices().putOrderPicking(context, order.pickId, 'pendiente', token);
                  order.estado = orderProvider.estado;
                  Navigator.of(context).pop();
                  setState(() {});
                  ejecutando = false;
                }
                setState(() {});
              },
              child: const Text('Confirmar')
            )
          ],
        );
      }
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'nueva':
        return Colors.blue;
      case 'en progreso':
        return Colors.orange;
      case 'pendiente':
        return Colors.yellow[700]!;
      case 'completada':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}