// ignore_for_file: unused_element

import 'package:deposito/config/router/pages.dart';
import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/services/picking_services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  bool seleccionado = false;
  bool continuar = false;
  bool? modoAutomatico;

  @override
  void initState() {
    super.initState();
    cargarData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cargarData();
  }

  Future<void> cargarData() async {
    final provider = context.read<ProductProvider>();
    
    // Resetear modo cuando cambia la orden
    if (orderProvider.pickId != provider.ordenPicking.pickId) {
      modoAutomatico = null;
    }

    orderProvider = provider.ordenPicking;
    token = provider.token;
    almacen = provider.almacen;
    order = await PickingServices().getLineasOrder(context, orderProvider.pickId, almacen.almacenId, token);
    if(order.pickId != 0) {
      orderProvider.estado = order.estado;
    }
    
    continuar = order.estado == 'EN PROCESO';
    
    setState(() {});
  }

  Future<void> _mostrarDialogoConfirmacionModo(bool esAutomatico) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar modo de trabajo'),
          content: Text(
            esAutomatico 
              ? '¿Desea trabajar en modo AUTOMÁTICO? El sistema guiará el proceso.'
              : '¿Desea trabajar en modo MANUAL? Seleccionará los productos a pickear.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (esAutomatico) {
        await _activarModoAutomatico();
      } else {
        await _activarModoManual();
      }
    }
  }

  Future<void> _activarModoManual() async {
    final provider = context.read<ProductProvider>();
    
    if (order.estado == 'PENDIENTE') {
      orderProvider = await PickingServices().putOrderPicking(
        context, 
        order.pickId, 
        'en proceso',
        1, 
        token
      );
      order.estado = orderProvider.estado;
    } else {
      await PickingServices().iniciarTrabajo(context, order.pickId, 1, token);
    }
    
    setState(() {
      continuar = true;
      modoAutomatico = false;
    });
    
    provider.setOrdenPickingInterna(order);
    provider.setLineasPicking(order.lineas ?? []);
    provider.setModoSeleccionUbicacion(false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Modo MANUAL activado'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _activarModoAutomatico() async {
    final provider = context.read<ProductProvider>();
    
    if (order.estado == 'PENDIENTE') {
      orderProvider = await PickingServices().putOrderPicking(
        context, 
        order.pickId, 
        'en proceso', 
        2,
        token
      );
      order.estado = orderProvider.estado;
    } else {
      await PickingServices().iniciarTrabajo(context, order.pickId, 2, token);
    }
    
    setState(() {
      continuar = true;
      modoAutomatico = true;
    });
    
    provider.setOrdenPickingInterna(order);
    provider.setLineasPicking(order.lineas ?? []);
    provider.setModoSeleccionUbicacion(true);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Modo AUTOMÁTICO activado'),
        duration: Duration(seconds: 2),
      ),
    );
    
    final linea = order.lineas!.firstWhere(
      (l) => l.cantidadPickeada < l.cantidadPedida && l.ubicaciones.any((u) => u.existenciaActual > 0),
      orElse: () => order.lineas!.firstWhere(
        (l) => l.cantidadPickeada < l.cantidadPedida,
        orElse: () => order.lineas!.first
      )
    );
    
    final index = order.lineas!.indexOf(linea);
    provider.setCurrentLineIndex(index);
    
    final ubicacion = linea.ubicaciones.firstWhere(
      (u) => u.existenciaActual > 0,
      orElse: () => linea.ubicaciones.first
    );
    
    provider.setUbicacionSeleccionada(ubicacion);
    if (orderProvider.tipo == 'TE' || orderProvider.tipo == "C") {
      appRouter.push('/pickingCompra');
    } else {
      appRouter.push('/pickingProductos');
    }
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              var menu = context.read<ProductProvider>().menu;
              Navigator.of(context).popUntil((route) => route.settings.name == menu);
              final router = GoRouter.of(context);
              router.pushReplacement(menu);
            },
          ),
          actions: [
            IconButton(onPressed: () => appRouter.push('/qrPage'), icon: const Icon(Icons.qr_code)),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _expanded(colors),
              _buildCommentSection(orderProvider, colors),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(context, orderProvider, colors),
      ),
    );
  }

  Widget _expanded(ColorScheme colors) {
    final provider = context.read<ProductProvider>();
    
    return Expanded(
      child: RefreshIndicator(
        onRefresh: () async {
          await cargarData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: CircularProgressIndicator(
                                  value: order.porcentajeCompletado / 100,
                                  strokeWidth: 5,
                                  backgroundColor: Colors.grey[400],
                                  color: order.porcentajeCompletado == 100.0 ? Colors.green : colors.secondary,
                                ),
                              ),
                              Text(
                                '${order.porcentajeCompletado.toStringAsFixed(order.porcentajeCompletado % 1 == 0 ? 0 : 0)}%',
                                style: const TextStyle(
                                  fontSize: 12, 
                                  fontWeight: FontWeight.bold
                                ),
                              )
                            ],
                          ),
                          Text(
                            '${orderProvider.numeroDocumento} - ${orderProvider.serie}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Chip(
                                label: Text(
                                  orderProvider.estado,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: _getStatusColor(orderProvider.estado),
                              ),
                              Text(orderProvider.prioridad),
                              Text('PickId: ${orderProvider.pickId}'),
                              Text('Líneas: ${order.cantLineas ?? 0}'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Cliente/Proveedor: ${orderProvider.nombre}'),
                      const SizedBox(height: 8),
                      Text('Fecha: ${_formatDate(orderProvider.fechaDate)}'),
                      const SizedBox(height: 8),
                      Text('Tipo: ${orderProvider.descTipo}'),
                      const SizedBox(height: 8,),
                      Text(orderProvider.transaccion),
                      const SizedBox(height: 8,),
                      Text("Fecha última mod.: ${_formatDate(order.fechaModificadoPor)}"),
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
                  for (var i = 0; i < order.lineas!.length; i++)...[
                    if (!(order.lineas![i].tipoLineaAdicional == "C" && order.lineas![i].lineaIdOriginal == 0))
                      Card(
                        color: (order.estado == 'CERRADO' || (modoAutomatico == true || provider.modoSeleccionUbicacion == true)) ? Colors.grey.shade300 : Colors.white,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.inventory),
                          title: Text(order.lineas![i].descripcion),
                          subtitle: Text('Código: ${order.lineas![i].codItem}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${order.lineas![i].cantidadPickeada} / ${order.lineas![i].cantidadPedida} unid.'),
                              const SizedBox(width: 8),
                              if(order.lineas![i].cantidadPickeada == order.lineas![i].cantidadPedida)
                                const Icon(Icons.check_circle, color: Colors.green),
                            ]
                          ),
                          onTap: (order.estado == 'CERRADO' || (modoAutomatico == true || provider.modoSeleccionUbicacion == true)) ? null : () {
                            if(seleccionado == false) {
                              setState(() {
                                seleccionado = true;
                              });
                              _seleccionarLinea(order.lineas![i], i);
                              setState(() {
                                seleccionado = false;
                              });
                            }
                          },
                        ),
                      ),
                  ]
                ],
              ),            
            ],
          ),
        ),
      ),
    );
  }

  void _seleccionarLinea(PickingLinea linea, int index) {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    
    provider.setCurrentLineIndex(index);
    provider.setOrdenPickingInterna(order);
    provider.setLineasPicking(order.lineas ?? []);
    provider.setModoSeleccionUbicacion(false);
    if (orderProvider.tipo == 'TE' || orderProvider.tipo == 'C') {
      appRouter.push('/pickingCompra');
    } else {
      appRouter.push('/pickingProductos');
    }
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if(order.estado == 'CERRADO') ...[
              ElevatedButton.icon(
                onPressed: () async {
                  await PickingServices().imprimirResumen(context, order, token);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: Icon(Icons.receipt_long, color: colors.onPrimary,),
                label: const Text(
                  'Imprimir resumen',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await PickingServices().imprimirEtiquetaDeCarga(context, order, token);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Icon(Icons.inventory_2, color: colors.onPrimary,)
              ),
            ] else ...[
              if(order.tipo == 'C' || order.tipo == 'TE') ...[
                ElevatedButton(
                  onPressed: order.estado == 'CERRADO' ? null : () => _iniciarDirectamente(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text(
                    'Iniciar',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: order.estado == 'CERRADO' ? null : () => _mostrarDialogoConfirmacionModo(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text(
                    'Manual',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: order.estado == 'CERRADO' ? null : () => _mostrarDialogoConfirmacionModo(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text(
                    'Automático',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
              
              ElevatedButton(
                onPressed: (order.estado == 'CERRADO' || order.estado == 'PENDIENTE') ? null : () => _mostrarDialogoConfirmacion('finalizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (order.estado == 'CERRADO' || order.estado == 'PENDIENTE') ? Colors.grey : colors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text(
                  'Finalizar',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ]
            
          ],
        ),
      ),
    );
  }

  Future<void> _iniciarDirectamente() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar inicio'),
          content: const Text('¿Desea iniciar el proceso de picking?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final provider = context.read<ProductProvider>();
      
      // Cambiar estado de la orden si está pendiente
      if (order.estado == 'PENDIENTE') {
        orderProvider = await PickingServices().putOrderPicking(
          context, 
          order.pickId, 
          'en proceso',
          1, 
          token
        );
        order.estado = orderProvider.estado;
      }
      
      // Actualizar estado en el provider
      setState(() {
        continuar = true;
        modoAutomatico = false;
      });
      
      provider.setOrdenPickingInterna(order);
      provider.setLineasPicking(order.lineas ?? []);
      provider.setModoSeleccionUbicacion(false);
      
      // Redirigir directamente a pickingCompra
      appRouter.push('/pickingCompra');
    }
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
                if (accion == 'finalizar') {
                  final provider = Provider.of<ProductProvider>(context, listen: false);
                  provider.setOrdenPickingInterna(order);
                  provider.setLineasPicking(order.lineas ?? []);
                  Navigator.of(context).pop();
                  appRouter.push('/resumenPicking');
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
                  orderProvider = await PickingServices().putOrderPicking(context, order.pickId, 'pendiente', 1, token);
                  order.estado = orderProvider.estado;
                  Navigator.of(context).pop();
                  setState(() {
                    continuar = false;
                    modoAutomatico = null;
                  });
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
      case 'CERRADO':
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