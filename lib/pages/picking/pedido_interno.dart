// ignore_for_file: unused_element

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
  bool valorSwitch = true;
  bool seleccionado = false;

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
    
    // Inicializar el modo en el provider
    context.read<ProductProvider>().setModoSeleccionUbicacion(valorSwitch);
    
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
            'Orden ${orderProvider.numeroDocumento}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _expanded(),
              _buildCommentSection(orderProvider, colors),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(context, orderProvider, colors),
      ),
    );
  }

  Widget _expanded() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${orderProvider.numeroDocumento} - ${orderProvider.serie}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Chip(
                          label: Text(
                            orderProvider.estado,
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: _getStatusColor(orderProvider.estado),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Cliente/Proveedor: ${orderProvider.nombre}'),
                    const SizedBox(height: 8),
                    Text('Fecha: ${_formatDate(orderProvider.fechaDate)}'),
                    const SizedBox(height: 8),
                    Text('Tipo: ${(orderProvider.tipo == 'C' || orderProvider.tipo == 'TE') ? 'Entrada' : 'Salida'}'),
                    const SizedBox(height: 8),
                    if (orderProvider.prioridad != '')
                      Text('Prioridad: ${orderProvider.prioridad}'),
                    const SizedBox(height: 8,),
                    Text(orderProvider.transaccion)
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Productos a ${(orderProvider.tipo == 'C' || orderProvider.tipo == 'TE') ? 'recibir' : 'preparar'}:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                for (final item in order.lineas!)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.inventory),
                      title: Text(item.descripcion),
                      subtitle: Text('Código: ${item.codItem}'),
                      trailing: Text('${item.cantidadPedida} unid'),
                      onTap: valorSwitch ? null : () {
                        if(seleccionado == false) {
                          setState(() {
                            seleccionado = true;
                          });
                          _seleccionarLineaManual(item);
                          setState(() {
                            seleccionado = false;
                          });
                        }
                      } ,
                    ),
                  ),
              ],
            ),
            
          ],
        ),
      ),
    );
  }

  void _seleccionarLineaManual(PickingLinea linea) {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    provider.setCurrentLineIndex(order.lineas!.indexOf(linea));
    provider.setOrdenPickingInterna(order);
    provider.setLineasPicking(order.lineas ?? []);
    
    appRouter.push('/pickingProductos');
  }

  Widget _buildCommentSection(OrdenPicking order, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comentario:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
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
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, OrdenPicking order, ColorScheme colors) {
    return BottomAppBar(
      notchMargin: 10,
      elevation: 0,
      shape: const CircularNotchedRectangle(),
      color: Colors.grey.shade200,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: order.estado == 'CERRADO' ? null : () => _mostrarDialogoConfirmacion(order.estado == 'PENDIENTE' ? 'iniciar' : 'continuar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: order.estado == 'CERRADO' ? Colors.grey : colors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                order.estado == 'PENDIENTE' ? 'Iniciar' : 'Continuar',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: (order.estado == 'CERRADO' || order.estado == 'PENDIENTE') ? null : () => _mostrarDialogoConfirmacion('finalizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: (order.estado == 'CERRADO' || order.estado == 'PENDIENTE') ? Colors.grey : colors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Finalizar',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            IconButton(
              onPressed: (order.estado == 'CERRADO' || order.estado == 'PENDIENTE') ? null : () async => await volverAPendiente(),
              icon: Icon(
                Icons.backspace,
                color: (order.estado == 'CERRADO' || order.estado == 'PENDIENTE') ? Colors.grey : colors.primary
              )
            ),
            if(order.tipo != 'C' && order.tipo != 'TE') ...[
              Icon(Icons.handyman, color: !valorSwitch ? colors.secondary : colors.onSurface,),
              Switch(
                value: valorSwitch,
                onChanged: (value) {
                  valorSwitch = value;
                  context.read<ProductProvider>().setModoSeleccionUbicacion(value);
                  setState(() {});
                },
              ),
              Icon(Icons.smart_toy_outlined, color: valorSwitch ? colors.secondary : colors.onSurface,)
            ]
          ],
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
                  Provider.of<ProductProvider>(context, listen: false).setLineasPicking(order.lineas ?? []);
                  Navigator.of(context).pop();
                  if(order.tipo == 'C' || order.tipo == 'TE') {
                    appRouter.push('/pickingCompra');
                  } else {
                    appRouter.push('/pickingProductos');
                  }
                } else if(accion == 'finalizar') {
                  // Guardamos los datos en el provider
                  final provider = Provider.of<ProductProvider>(context, listen: false);
                  provider.setOrdenPickingInterna(order);
                  provider.setLineasPicking(order.lineas ?? []);
                  Navigator.of(context).pop();
                  // Navegamos sin parámetros
                  appRouter.push('/resumenPicking');
                } else if(accion == 'continuar') {
                  Provider.of<ProductProvider>(context, listen: false).setOrdenPickingInterna(order);
                  Provider.of<ProductProvider>(context, listen: false).setLineasPicking(order.lineas ?? []);
                  Navigator.of(context).pop();
                  if(order.tipo == 'C' || order.tipo == 'TE') {
                    appRouter.push('/pickingCompra');
                  } else {
                    appRouter.push('/pickingProductos');
                  }
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
    switch (status.toUpperCase()) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'EN PROCESO':
        return Colors.blue;
      case 'COMPLETADO':
        return Colors.green;
      case 'CANCELADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}