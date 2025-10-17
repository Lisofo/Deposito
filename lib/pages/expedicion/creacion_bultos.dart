// import 'package:deposito/models/bulto.dart';
// import 'package:deposito/models/entrega.dart';
// import 'package:deposito/models/forma_envio.dart';
// import 'package:deposito/models/modo_envio.dart';
// import 'package:deposito/models/tipo_bulto.dart';
// import 'package:deposito/provider/product_provider.dart';
// import 'package:deposito/services/entrega_services.dart';
// import 'package:deposito/services/product_services.dart';
// import 'package:deposito/widgets/carteles.dart';
// import 'package:deposito/widgets/custom_form_field.dart';
// import 'package:deposito/widgets/icon_string.dart';
// import 'package:dropdown_search/dropdown_search.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:deposito/models/orden_picking.dart';
// import 'package:deposito/services/picking_services.dart';

// class CreacionBultosPage extends StatefulWidget {
//   const CreacionBultosPage({super.key});

//   @override
//   CreacionBultosPageState createState() => CreacionBultosPageState();
// }

// class CreacionBultosPageState extends State<CreacionBultosPage> {
  
//   OrdenPicking? _ordenSeleccionada;
//   Bulto? _bultoActual;
//   Bulto? _bultoVirtual;
//   final TextEditingController _codigoController = TextEditingController();
//   final TextEditingController _comentarioController = TextEditingController();
//   final PickingServices _pickingServices = PickingServices();
//   bool _isLoadingLineas = false;
//   late String token;
//   FocusNode focoDeScanner = FocusNode();
//   Entrega entrega = Entrega.empty();
//   bool _vistaMonitor = false;
//   bool mostrarCerrados = false;

//   // Datos para envíos
//   late List<FormaEnvio> empresasEnvio = [];
//   late List<FormaEnvio> transportistas = [];
//   late List<FormaEnvio> formasEnvio = [];
//   late List<TipoBulto> tipoBultos = [];
//   late List<ModoEnvio> modoEnvios = [];
//   late List<OrdenPicking> _ordenes = [];
//   final List<Bulto> _bultos = [];
//   final List<Bulto> _bultosCerrados = [];
//   List<PickingLinea> _lineasOrdenSeleccionada = [];

//   @override
//   void initState() {
//     super.initState();
//     _cargarDatosIniciales();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) {
//         focoDeScanner.requestFocus();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _codigoController.dispose();
//     _comentarioController.dispose();
//     focoDeScanner.dispose();
//     super.dispose();
//   }

//   Future<void> _cargarDatosIniciales() async {
//     final productProvider = Provider.of<ProductProvider>(context, listen: false);
//     token = productProvider.token;
//     entrega = productProvider.entrega;
//     _vistaMonitor = productProvider.vistaMonitor;
//     _ordenes = productProvider.ordenesExpedicion;
    
//     if (_ordenes.isNotEmpty) {
//       _ordenSeleccionada = _ordenes[0];
//     }

//     // Load initial data
//     formasEnvio = await EntregaServices().formaEnvio(context, token);
//     tipoBultos = await EntregaServices().tipoBulto(context, token);
//     modoEnvios = await EntregaServices().modoEnvio(context, token);
    
//     // Cargar líneas de la orden
//     if (_ordenSeleccionada != null && (_ordenSeleccionada!.lineas == null || _ordenSeleccionada!.lineas!.isEmpty)) {
//       await _cargarLineasOrden(_ordenSeleccionada!);
//     } else if (_ordenSeleccionada != null) {
//       _lineasOrdenSeleccionada = _ordenSeleccionada!.lineas!;
//     }

//     // Cargar bultos existentes (incluyendo el virtual)
//     if (entrega.entregaId != 0) {
//       final bultosExistentes = await EntregaServices().getBultosEntrega(
//         context, 
//         entrega.entregaId, 
//         token
//       );
      
//       for (var bulto in bultosExistentes) {
//         final tipoBulto = tipoBultos.firstWhere(
//           (t) => t.tipoBultoId == bulto.tipoBultoId,
//           orElse: () => TipoBulto.empty()
//         );
        
//         await _cargarItemsBulto(bulto);
        
//         if (tipoBulto.codTipoBulto == "VIRTUAL") {
//           _bultoVirtual = bulto;
//         } else if (bulto.estado == 'CERRADO') {
//           _bultosCerrados.add(bulto);
//         } else if (bulto.estado == 'PENDIENTE') {
//           _bultos.add(bulto);
//         }
//       }

//       setState(() {
//         if (_bultos.isNotEmpty) {
//           _bultoActual = _bultos.first;
//         }
//       });
//     }

//     for (var forma in formasEnvio) {
//       if(forma.tr == true) {
//         transportistas.add(forma);
//         transportistas.sort((a, b) => a.descripcion!.compareTo(b.descripcion.toString()));
//       } 
//       if (forma.envio == true) {
//         empresasEnvio.add(forma);
//         empresasEnvio.sort((a, b) => a.descripcion!.compareTo(b.descripcion.toString()));
//       }
//     }
//   }

//   Future<void> _cargarLineasOrden(OrdenPicking orden) async {
//     if (orden.lineas != null && orden.lineas!.isNotEmpty) {
//       setState(() {
//         _lineasOrdenSeleccionada = orden.lineas!;
//       });
//       return;
//     }

//     setState(() => _isLoadingLineas = true);
//     try {
//       final token = Provider.of<ProductProvider>(context, listen: false).token;
//       final almacenId = Provider.of<ProductProvider>(context, listen: false).almacen.almacenId;
      
//       final ordenCompleta = await _pickingServices.getLineasOrder(
//         context, 
//         orden.pickId, 
//         almacenId, 
//         token
//       ) as OrdenPicking?;

//       if (ordenCompleta != null) {
//         setState(() {
//           _lineasOrdenSeleccionada = ordenCompleta.lineas ?? [];
//           final index = _ordenes.indexWhere((o) => o.pickId == orden.pickId);
//           if (index != -1) {
//             _ordenes[index] = ordenCompleta;
//           }
//         });
//       }
//     } finally {
//       setState(() => _isLoadingLineas = false);
//       if (mounted) {
//         focoDeScanner.requestFocus();
//       }
//     }
//   }

//   (int verificada, int maxima) _getCantidadVerificadaYMaxima(String codigoRaiz, int pickLineaId) {
//     try {
//       final linea = _lineasOrdenSeleccionada.firstWhere(
//         (linea) => linea.pickLineaId == pickLineaId,
//       );
      
//       // Sumar cantidades de todos los bultos (activos, cerrados y virtual)
//       int cantidadVirtual = _bultoVirtual != null 
//         ? _bultoVirtual!.contenido
//             .where((item) => item.pickLineaId == pickLineaId)
//             .fold(0, (sum, item) => sum + item.cantidad)
//         : 0;
      
//       final verificada = [..._bultos, ..._bultosCerrados].fold(cantidadVirtual, (total, bulto) {
//         return total + bulto.contenido
//           .where((item) => item.pickLineaId == pickLineaId)
//           .fold(0, (sum, item) => sum + item.cantidad);
//       });
      
//       // Si la modalidad es PAPEL, usar cantidadPedida como máximo
//       if (_ordenSeleccionada?.modalidad == 'PAPEL') {
//         return (verificada, linea.cantidadPedida);
//       } else {
//         // Para WMS, usar cantidadPickeada como máximo
//         return (verificada, linea.cantidadPickeada);
//       }
//     } catch (e) {
//       return (0, 0);
//     }
//   }

//   bool _validarCompletitudProductos() {
//     for (final linea in _lineasOrdenSeleccionada) {
//       // Para PAPEL, verificar todas las líneas basado en cantidadPedida
//       // Para WMS, solo verificar líneas con cantidadPickeada > 0
//       if (_ordenSeleccionada?.modalidad == 'WMS' && linea.cantidadPickeada == 0) continue;
      
//       final (cantidadVerificada, maxima) = _getCantidadVerificadaYMaxima(linea.codItem, linea.pickLineaId);
//       if (cantidadVerificada < maxima) {
//         return true;
//       }
//     }
//     return true;
//   }

//   Future<void> procesarEscaneoUbicacion(String value) async {
//     if (value.isEmpty || _bultoActual == null || _vistaMonitor) return;
    
//     try {
//       final provider = Provider.of<ProductProvider>(context, listen: false);  
//       final productos = await ProductServices().getProductByName(
//         context, 
//         '', 
//         '2', 
//         provider.almacen.almacenId.toString(), 
//         value, 
//         '0', 
//         provider.token
//       );
      
//       if (productos.isEmpty) {
//         Carteles.showDialogs(context, 'Producto no encontrado', false, false, false);
//         return;
//       }

//       final producto = productos[0];
//       final linea = _lineasOrdenSeleccionada.firstWhere(
//         (linea) => linea.codItem == producto.raiz,
//         orElse: () => PickingLinea.empty(),
//       );
      
//       if (linea.codItem == '') {
//         Carteles.showDialogs(context, 'Producto no encontrado en la orden', false, false, false);
//         return;
//       }
      
//       // Obtener la cantidad máxima según la modalidad
//       final maxima = _ordenSeleccionada?.modalidad == 'PAPEL' 
//           ? linea.cantidadPedida 
//           : linea.cantidadPickeada;
      
//       final (cantidadVerificadaTotal, _) = _getCantidadVerificadaYMaxima(linea.codItem, linea.pickLineaId);
      
//       // Siempre validar que no se supere la cantidad máxima
//       if (cantidadVerificadaTotal >= maxima) {
//         Carteles.showDialogs(
//           context, 
//           'Ya se verificó la cantidad máxima para este producto en todos los bultos', 
//           false, 
//           false, 
//           false
//         );
//         return;
//       }
      
//       final index = _bultoActual!.contenido.indexWhere(
//         (item) => item.pickLineaId == linea.pickLineaId
//       );
      
//       if (index != -1) {
//         // Validar que no se supere la cantidad máxima al agregar
//         final nuevaCantidadTotal = cantidadVerificadaTotal + 1;
//         if (nuevaCantidadTotal > maxima) {
//           Carteles.showDialogs(
//             context, 
//             'No puede superar la cantidad máxima ($nuevaCantidadTotal/$maxima)', 
//             false, 
//             false, 
//             false
//           );
//           return;
//         }
        
//         if (_bultoActual!.bultoId != 0) {
//           await EntregaServices().patchItemBulto(
//             context,
//             entrega.entregaId,
//             _bultoActual!.bultoId,
//             _bultoActual!.contenido[index].pickLineaId,
//             _bultoActual!.contenido[index].cantidad + 1,
//             token,
//           );
//         }
        
//         setState(() {
//           _bultoActual!.contenido[index].cantidad += 1;
//         });
//       } else {
//         // Validar que no se supere la cantidad máxima al agregar
//         final nuevaCantidadTotal = cantidadVerificadaTotal + 1;
//         if (nuevaCantidadTotal > maxima) {
//           Carteles.showDialogs(
//             context, 
//             'No puede superar la cantidad máxima ($nuevaCantidadTotal/$maxima)', 
//             false, 
//             false, 
//             false
//           );
//           return;
//         }
        
//         if (_bultoActual!.bultoId != 0) {
//           await EntregaServices().patchItemBulto(
//             context,
//             entrega.entregaId,
//             _bultoActual!.bultoId,
//             linea.pickLineaId,
//             1,
//             token,
//           );
//         }
        
//         final nuevoItem = BultoItem(
//           codItem: value,
//           raiz: linea.codItem,
//           cantidad: 1,
//           item: linea.descripcion,
//           cantidadMaxima: maxima,
//           bultoId: _bultoActual!.bultoId,
//           bultoLinId: 0,
//           pickLineaId: linea.pickLineaId, 
//           pickId: linea.pickId,
//           itemId: linea.itemId
//         );
        
//         setState(() {
//           _bultoActual!.contenido.add(nuevoItem);
//         });
//       }
      
//       _codigoController.clear();
//       if (mounted) {
//         FocusScope.of(context).requestFocus(focoDeScanner);
//       }
//     } catch (e) {
//       Carteles.showDialogs(context, 'Error al procesar el escaneo: ${e.toString()}', false, false, false);
//       if (mounted) {
//         FocusScope.of(context).requestFocus(focoDeScanner);
//       }
//     }
//   }

//   void _mostrarDialogoTipoBulto() {
//     if (_vistaMonitor) return;
    
//     final colors = Theme.of(context).colorScheme;
    
//     // Filtrar tipos de bulto excluyendo VIRTUAL
//     List<TipoBulto> tiposDisponibles = tipoBultos.where((tipo) => tipo.codTipoBulto != "VIRTUAL").toList();
    
//     if (tiposDisponibles.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No hay tipos de bulto disponibles')),
//       );
//       return;
//     }

//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Seleccionar tipo de bulto'),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: tiposDisponibles.map((tipo) {
//                 return ListTile(
//                   leading: getIcon(tipo.icon, context, colors.secondary),
//                   title: Text(tipo.descripcion),
//                   onTap: () {
//                     Navigator.of(context).pop();
//                     _crearNuevoBulto(tipo);
//                   },
//                 );
//               }).toList(),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Future<void> _crearNuevoBulto(TipoBulto tipoBulto) async {
//     if (_vistaMonitor) return;
    
//     try {
//       final nuevoBulto = await EntregaServices().postBultoEntrega(
//         context,
//         entrega.entregaId,
//         tipoBulto.tipoBultoId,
//         token,
//       );

//       if (nuevoBulto.bultoId != 0) {
//         setState(() {
//           _bultos.add(nuevoBulto);
//           _bultoActual = nuevoBulto;
//         });
//       }
//     } catch (e) {
//       Carteles.showDialogs(context, 'Error al crear el bulto', false, false, false);
//     }
//   }

//   int _getCantidadEnVirtual(int pickLineaId) {
//     if (_bultoVirtual == null) return 0;
    
//     return _bultoVirtual!.contenido
//         .where((item) => item.pickLineaId == pickLineaId)
//         .fold(0, (sum, item) => sum + item.cantidad);
//   }

//   Future<void> _ajustarBultoVirtual(int pickLineaId, int cantidad, BultoItem itemOriginal) async {
//     if (_bultoVirtual == null) return;
    
//     try {
//       final indexVirtual = _bultoVirtual!.contenido.indexWhere(
//         (i) => i.pickLineaId == pickLineaId
//       );
      
//       if (indexVirtual != -1) {
//         final nuevaCantidadVirtual = _bultoVirtual!.contenido[indexVirtual].cantidad + cantidad;
        
//         if (nuevaCantidadVirtual < 0) {
//           // Esto no debería pasar si validamos antes
//           return;
//         }
        
//         // Actualizar servidor para bulto virtual
//         if (_bultoVirtual!.bultoId != 0) {
//           await EntregaServices().patchItemBulto(
//             context,
//             entrega.entregaId,
//             _bultoVirtual!.bultoId,
//             pickLineaId,
//             nuevaCantidadVirtual,
//             token,
//           );
//         }
        
//         // Actualizar localmente bulto virtual
//         if (nuevaCantidadVirtual == 0) {
//           _bultoVirtual!.contenido.removeAt(indexVirtual);
//         } else {
//           _bultoVirtual!.contenido[indexVirtual].cantidad = nuevaCantidadVirtual;
//         }
//       } else if (cantidad > 0) {
//         // Si no existe el item en virtual y estamos agregando, crear uno nuevo
//         final nuevoItem = BultoItem(
//           codItem: itemOriginal.codItem,
//           raiz: itemOriginal.raiz,
//           cantidad: cantidad,
//           item: itemOriginal.item,
//           cantidadMaxima: itemOriginal.cantidadMaxima,
//           bultoId: _bultoVirtual!.bultoId,
//           bultoLinId: 0,
//           pickLineaId: pickLineaId, 
//           pickId: itemOriginal.pickId,
//           itemId: itemOriginal.itemId
//         );
        
//         // Actualizar servidor para bulto virtual
//         if (_bultoVirtual!.bultoId != 0) {
//           await EntregaServices().patchItemBulto(
//             context,
//             entrega.entregaId,
//             _bultoVirtual!.bultoId,
//             pickLineaId,
//             cantidad,
//             token,
//           );
//         }
        
//         // Actualizar localmente bulto virtual
//         _bultoVirtual!.contenido.add(nuevoItem);
//       }
      
//       setState(() {});
      
//     } catch (e) {
//       Carteles.showDialogs(context, 'Error al ajustar bulto virtual: ${e.toString()}', false, false, false);
//     }
//   }

//   void _eliminarItem(BultoItem item) async {
//     if (_vistaMonitor) return;
    
//     final pickLineaId = item.pickLineaId;
//     final cantidadAEliminar = item.cantidad;
    
//     // Primero transferimos la cantidad al bulto virtual
//     if (_bultoVirtual != null && cantidadAEliminar > 0) {
//       await _ajustarBultoVirtual(pickLineaId, cantidadAEliminar, item);
//     }
    
//     // Luego intentamos actualizar el servidor con conteo = 0
//     if (_bultoActual?.bultoId != null && _bultoActual!.bultoId != 0) {
//       try {
//         await EntregaServices().patchItemBulto(
//           context,
//           entrega.entregaId,
//           _bultoActual!.bultoId,
//           pickLineaId,
//           0, // Enviamos conteo = 0 para eliminar el item
//           token,
//         );
        
//         // Si el servidor responde OK, eliminamos el item localmente
//         setState(() {
//           _bultoActual?.contenido.remove(item);
//         });
        
//       } catch (e) {
//         // Si hay error, mostramos mensaje y mantenemos el item
//         Carteles.showDialogs(context, 'Error al eliminar item', false, false, false);
//         if (mounted) {
//           setState(() {
//             // Revertir el cambio en el bulto virtual
//             if (_bultoVirtual != null) {
//               _ajustarBultoVirtual(pickLineaId, -cantidadAEliminar, item);
//             }
//           });
//         }
//       }
//     } else {
//       // Si es un bulto nuevo (sin ID), simplemente lo eliminamos localmente
//       // (ya transferimos al virtual previamente)
//       setState(() {
//         _bultoActual?.contenido.remove(item);
//       });
//     }
//   }

//   Future<void> _procesarEdicionCantidadConTransferencia(
//     BultoItem item, 
//     int nuevaCantidad, 
//     int cantidadEnOtrosBultos, 
//     int cantidadMaxima,
//     int cantidadEnVirtual
//   ) async {
//     if (_vistaMonitor) return;
    
//     if (nuevaCantidad < 0) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('La cantidad no puede ser negativa')),
//       );
//       return;
//     }
    
//     final diferencia = nuevaCantidad - item.cantidad;
//     final totalProyectado = cantidadEnOtrosBultos + diferencia;
    
//     if (totalProyectado > cantidadMaxima) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('No puede superar $cantidadMaxima (Total actual: $totalProyectado')),
//       );
//       return;
//     }
    
//     // Calcular cuánto debemos ajustar en el bulto virtual
//     final ajusteVirtual = -diferencia; // Si aumentamos en físico, disminuimos en virtual
    
//     // Verificar si hay suficiente cantidad en el bulto virtual para el ajuste
//     if (ajusteVirtual > 0 && cantidadEnVirtual < ajusteVirtual) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('No hay suficiente cantidad en el bulto virtual ($cantidadEnVirtual) para realizar esta operación')),
//       );
//       return;
//     }
    
//     // Realizar el ajuste en el bulto virtual si es necesario
//     if (ajusteVirtual != 0 && _bultoVirtual != null) {
//       await _ajustarBultoVirtual(item.pickLineaId, ajusteVirtual, item);
//     }
    
//     // Actualizar la cantidad en el bulto físico
//     setState(() {
//       item.cantidad = nuevaCantidad;
//     });

//     if (_bultoActual?.bultoId != null && _bultoActual!.bultoId != 0) {
//       try {
//         await EntregaServices().patchItemBulto(
//           context,
//           entrega.entregaId,
//           _bultoActual!.bultoId,
//           item.pickLineaId,
//           item.cantidad,
//           token,
//         );
//       } catch (e) {
//         Carteles.showDialogs(context, 'Error al actualizar cantidad', false, false, false);
//         // Revertir el cambio local si falla el servidor
//         if (mounted) {
//           setState(() {
//             item.cantidad = item.cantidad - diferencia; // Revertir al valor original
//           });
//           // Revertir también el cambio en el bulto virtual
//           if (_bultoVirtual != null) {
//             await _ajustarBultoVirtual(item.pickLineaId, -ajusteVirtual, item);
//           }
//         }
//       }
//     }
//   }

//   void _editarCantidadItem(BultoItem item) async {
//     if (_vistaMonitor) return;
    
//     final controller = TextEditingController(text: item.cantidad.toString());
//     final (cantidadEnOtrosBultos, _) = _getCantidadVerificadaYMaxima(item.raiz, item.pickLineaId);
//     final FocusNode focusNode = FocusNode();

//     // Obtener la cantidad máxima correcta según la modalidad
//     final linea = _lineasOrdenSeleccionada.firstWhere(
//       (l) => l.pickLineaId == item.pickLineaId,
//       orElse: () => PickingLinea.empty(),
//     );
//     final cantidadMaxima = _ordenSeleccionada?.modalidad == 'PAPEL' 
//         ? linea.cantidadPedida 
//         : linea.cantidadPickeada;

//     // Obtener la cantidad actual en el bulto virtual para este producto
//     final cantidadEnVirtual = _getCantidadEnVirtual(item.pickLineaId);

//     // ignore: unused_local_variable
//     int diferencia = 0;

//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return StatefulBuilder(
//           builder: (context, setStateDialog) {
//             return AlertDialog(
//               title: const Text('Editar cantidad'),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text('Cantidad actual en bulto virtual: $cantidadEnVirtual'),
//                   const SizedBox(height: 10),
//                   TextField(
//                     controller: controller,
//                     focusNode: focusNode,
//                     keyboardType: TextInputType.number,
//                     decoration: const InputDecoration(labelText: 'Nueva cantidad'),
//                     onChanged: (value) {
//                       final nuevaCantidad = int.tryParse(value) ?? item.cantidad;
//                       final nuevaDiferencia = nuevaCantidad - item.cantidad;
//                       setStateDialog(() {
//                         diferencia = nuevaDiferencia;
//                       });
//                     },
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   child: const Text('Cancelar'),
//                   onPressed: () => Navigator.of(context).pop(),
//                 ),
//                 TextButton(
//                   child: const Text('Guardar'),
//                   onPressed: () async {
//                     final nuevaCantidad = int.tryParse(controller.text) ?? item.cantidad;
//                     await _procesarEdicionCantidadConTransferencia(
//                       item, 
//                       nuevaCantidad, 
//                       cantidadEnOtrosBultos, 
//                       cantidadMaxima,
//                       cantidadEnVirtual
//                     );
//                     if (mounted) {
//                       Navigator.of(context).pop();
//                     }
//                   },
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );

//     focusNode.requestFocus();
//     controller.selection = TextSelection(
//       baseOffset: 0,
//       extentOffset: controller.text.length,
//     );
//   }

//   Future<void> _transferirItemDesdeVirtual(BultoItem item, int cantidad) async {
//     if (_vistaMonitor || _bultoActual == null || _bultoVirtual == null) return;
    
//     try {
//       // 1. Reducir cantidad en bulto virtual
//       final indexVirtual = _bultoVirtual!.contenido.indexWhere(
//         (i) => i.pickLineaId == item.pickLineaId
//       );
      
//       if (indexVirtual != -1) {
//         final nuevaCantidadVirtual = _bultoVirtual!.contenido[indexVirtual].cantidad - cantidad;
        
//         if (nuevaCantidadVirtual < 0) {
//           Carteles.showDialogs(context, 'No hay suficiente cantidad en el bulto virtual', false, false, false);
//           return;
//         }
        
//         // Actualizar servidor para bulto virtual
//         if (_bultoVirtual!.bultoId != 0) {
//           await EntregaServices().patchItemBulto(
//             context,
//             entrega.entregaId,
//             _bultoVirtual!.bultoId,
//             item.pickLineaId,
//             nuevaCantidadVirtual,
//             token,
//           );
//         }
        
//         // Actualizar localmente bulto virtual
//         if (nuevaCantidadVirtual == 0) {
//           _bultoVirtual!.contenido.removeAt(indexVirtual);
//         } else {
//           _bultoVirtual!.contenido[indexVirtual].cantidad = nuevaCantidadVirtual;
//         }
//       }
      
//       // 2. Agregar cantidad al bulto actual
//       final indexActual = _bultoActual!.contenido.indexWhere(
//         (i) => i.pickLineaId == item.pickLineaId
//       );
      
//       if (indexActual != -1) {
//         // Actualizar servidor para bulto actual
//         if (_bultoActual!.bultoId != 0) {
//           await EntregaServices().patchItemBulto(
//             context,
//             entrega.entregaId,
//             _bultoActual!.bultoId,
//             item.pickLineaId,
//             _bultoActual!.contenido[indexActual].cantidad + cantidad,
//             token,
//           );
//         }
        
//         // Actualizar localmente bulto actual
//         _bultoActual!.contenido[indexActual].cantidad += cantidad;
//       } else {
//         // Crear nuevo item en bulto actual
//         final nuevoItem = BultoItem(
//           codItem: item.codItem,
//           raiz: item.raiz,
//           cantidad: cantidad,
//           item: item.item,
//           cantidadMaxima: item.cantidadMaxima,
//           bultoId: _bultoActual!.bultoId,
//           bultoLinId: 0,
//           pickLineaId: item.pickLineaId, 
//           pickId: item.pickId,
//           itemId: item.itemId
//         );
        
//         // Actualizar servidor para bulto actual
//         if (_bultoActual!.bultoId != 0) {
//           await EntregaServices().patchItemBulto(
//             context,
//             entrega.entregaId,
//             _bultoActual!.bultoId,
//             item.pickLineaId,
//             cantidad,
//             token,
//           );
//         }
        
//         // Actualizar localmente bulto actual
//         _bultoActual!.contenido.add(nuevoItem);
//       }
      
//       setState(() {});
      
//     } catch (e) {
//       Carteles.showDialogs(context, 'Error al transferir item: ${e.toString()}', false, false, false);
//     }
//   }

//   void _mostrarDialogoTransferencia(BultoItem item) {
//     if (_vistaMonitor || _bultoActual == null) return;
    
//     final controller = TextEditingController(text: '1');
//     final FocusNode focusNode = FocusNode();

//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Transferir ${item.item}'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text('Cantidad disponible en virtual: ${item.cantidad}'),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: controller,
//                 focusNode: focusNode,
//                 keyboardType: TextInputType.number,
//                 decoration: const InputDecoration(labelText: 'Cantidad a transferir'),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               child: const Text('Cancelar'),
//               onPressed: () => Navigator.of(context).pop(),
//             ),
//             TextButton(
//               child: const Text('Transferir'),
//               onPressed: () async {
//                 final cantidad = int.tryParse(controller.text) ?? 0;
//                 if (cantidad > 0 && cantidad <= item.cantidad) {
//                   Navigator.of(context).pop();
//                   await _transferirItemDesdeVirtual(item, cantidad);
//                 } else {
//                   Carteles.showDialogs(context, 'Cantidad inválida', false, false, false);
//                 }
//               },
//             ),
//           ],
//         );
//       },
//     );

//     focusNode.requestFocus();
//     controller.selection = TextSelection(
//       baseOffset: 0,
//       extentOffset: controller.text.length,
//     );
//   }

//   void _mostrarDialogoCierreBultos() {
//     if (_vistaMonitor) return;
    
//     // Crear selecciones para bultos
//     final List<bool> selecciones = List.filled(_bultos.length, false);
//     ModoEnvio? metodoEnvio;
//     FormaEnvio? empresaEnvioSeleccionada;
//     FormaEnvio? transportistaSeleccionado;
//     final comentarioController = TextEditingController();
//     bool procesandoRetiro = false;
//     bool incluyeFactura = false;

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return StatefulBuilder(
//           builder: (context, setStateDialog) {
//             return AlertDialog(
//               title: const Text('Seleccionar bultos y método de envío'),
//               content: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Text('Seleccionar bultos:'),
//                     ..._bultos.asMap().entries.map((entry) {
//                       final index = entry.key;
//                       final bulto = entry.value;
//                       final tipoBulto = tipoBultos.firstWhere(
//                         (t) => t.tipoBultoId == bulto.tipoBultoId,
//                         orElse: () => TipoBulto.empty()
//                       );
//                       return CheckboxListTile(
//                         title: Text('Bulto ${index + 1} (${tipoBulto.descripcion})'),
//                         value: selecciones[index],
//                         onChanged: procesandoRetiro ? null : (value) {
//                           setStateDialog(() {
//                             selecciones[index] = value!;
//                           });
//                         },
//                       );
//                     }),
                    
//                     const SizedBox(height: 20),
//                     const Text('Método de envío:'),
//                     DropdownButtonFormField<ModoEnvio>(
//                       isExpanded: true,
//                       value: metodoEnvio,
//                       hint: const Text('Seleccione método'),
//                       decoration: const InputDecoration(
//                         border: OutlineInputBorder()
//                       ),
//                       items: modoEnvios.map((value) {
//                         return DropdownMenuItem(
//                           value: value,
//                           child: Text(value.descripcion),
//                         );
//                       }).toList(),
//                       onChanged: procesandoRetiro ? null : (ModoEnvio? newValue) {
//                         setStateDialog(() {
//                           metodoEnvio = newValue;
//                           if (newValue?.modoEnvioId != 2) {
//                             empresaEnvioSeleccionada = null;
//                             transportistaSeleccionado = null;
//                           }
//                         });
//                       },
//                     ),
                    
//                     if (metodoEnvio?.modoEnvioId == 2) ...[
//                       const SizedBox(height: 10),                    
//                       const Text('Transportista:'),
//                       DropdownButtonFormField<FormaEnvio>(
//                         isExpanded: true,
//                         value: transportistaSeleccionado,
//                         hint: const Text('Seleccione transportista'),
//                         decoration: const InputDecoration(
//                           border: OutlineInputBorder()
//                         ),
//                         items: transportistas.map((FormaEnvio value) {
//                           return DropdownMenuItem(
//                             value: value,
//                             child: Text(value.descripcion.toString()),
//                           );
//                         }).toList(),
//                         onChanged: procesandoRetiro ? null : (FormaEnvio? newValue) {
//                           setStateDialog(() {
//                             transportistaSeleccionado = newValue;
//                           });
//                         },
//                       ),
//                       const SizedBox(height: 10),
//                       const Text('Empresa de envío:'),
//                       DropdownSearch<FormaEnvio>(
//                         popupProps: const PopupProps.menu(
//                           showSearchBox: true,
//                           searchDelay: Duration.zero,
//                           searchFieldProps: TextFieldProps(
//                             decoration: InputDecoration(
//                               hintText: "Buscar empresa...",
//                               border: OutlineInputBorder(),
//                               prefixIcon: Icon(Icons.search),
//                             ),
//                           ),
//                         ),
//                         items: empresasEnvio,
//                         itemAsString: (FormaEnvio item) => item.descripcion.toString(),
//                         selectedItem: empresaEnvioSeleccionada,
//                         onChanged: procesandoRetiro ? null : (FormaEnvio? newValue) {
//                           setStateDialog(() {
//                             empresaEnvioSeleccionada = newValue;
//                           });
//                         },
//                         dropdownDecoratorProps: const DropDownDecoratorProps(
//                           dropdownSearchDecoration: InputDecoration(
//                             hintText: "Seleccione empresa",
//                             border: OutlineInputBorder(),
//                           ),
//                         ),
//                         compareFn: (item, selectedItem) => item.codFormaEnvio == selectedItem.codFormaEnvio,
//                       ),
//                     ],
//                     const SizedBox(height: 10),
//                     CheckboxListTile(
//                       title: const Text('Incluye factura'),
//                       value: incluyeFactura,
//                       onChanged: procesandoRetiro ? null : (bool? value) {
//                         setStateDialog(() {
//                           incluyeFactura = value ?? false;
//                         });
//                       },
//                     ),
//                     CustomTextFormField(
//                       controller: comentarioController,
//                       minLines: 1,
//                       maxLines: 5,
//                       hint: 'Comentario',
//                       enabled: !procesandoRetiro,
//                     ),
//                     if (procesandoRetiro) 
//                       const Padding(
//                         padding: EdgeInsets.all(8.0),
//                         child: CircularProgressIndicator(),
//                       ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 if (!procesandoRetiro)
//                   TextButton(
//                     child: const Text('Cancelar'),
//                     onPressed: () => Navigator.of(context).pop(),
//                   ),
//                 TextButton(
//                   onPressed: procesandoRetiro ? null : () async {
//                     final bultosSeleccionados = selecciones.where((s) => s).length;
                    
//                     if (metodoEnvio == null || bultosSeleccionados == 0) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('Debe seleccionar al menos un bulto y un método de envío')),
//                       );
//                       return;
//                     }
                    
//                     if (metodoEnvio?.modoEnvioId == 2 && (empresaEnvioSeleccionada == null || transportistaSeleccionado == null)) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('Para envío por correo debe seleccionar empresa y transportista')),
//                       );
//                       return;
//                     }
                    
//                     setStateDialog(() {
//                       procesandoRetiro = true;
//                     });

//                     try {
//                       // Procesar cada bulto seleccionado
//                       for (int i = 0; i < selecciones.length; i++) {
//                         if (selecciones[i]) {
//                           final bulto = _bultos[i];
                          
//                           // 1. Actualizar datos del bulto con PUT
//                           await EntregaServices().putBultoEntrega(
//                             context,
//                             entrega.entregaId,
//                             bulto.bultoId,
//                             _ordenSeleccionada?.entidadId ?? 0, // clienteId
//                             _ordenSeleccionada?.nombre ?? '', // nombreCliente
//                             metodoEnvio!.modoEnvioId,
//                             transportistaSeleccionado?.formaEnvioId ?? 0, // agenciaTrId
//                             empresaEnvioSeleccionada?.formaEnvioId ?? 0, // agenciaUFId
//                             '', // direccion
//                             _ordenSeleccionada!.localidad, // localidad
//                             _ordenSeleccionada!.telefono, // telefono
//                             comentarioController.text, // comentarioEnvio
//                             comentarioController.text, // comentario
//                             bulto.tipoBultoId, // tipoBultoId
//                             incluyeFactura,
//                             bulto.nroBulto,
//                             bulto.totalBultos,
//                             token,
//                           );

//                           // 2. Cambiar estado del bulto a CERRADO
//                           await EntregaServices().patchBultoEstado(
//                             context,
//                             entrega.entregaId,
//                             bulto.bultoId,
//                             'CERRADO',
//                             token,
//                           );
//                         }
//                       }

//                       // Verificar si todos los bultos están cerrados
//                       final bultosNoCerrados = await EntregaServices().getBultosEntrega(
//                         context,
//                         entrega.entregaId,
//                         token,
//                       ).then((bultos) => bultos.where((b) => b.estado != 'CERRADO').length);

//                       if (bultosNoCerrados == 0) {
//                         // 3. Si todos los bultos están cerrados, cerrar la entrega
//                         await EntregaServices().patchEntregaEstado(
//                           context,
//                           entrega.entregaId,
//                           'finalizado',
//                           token,
//                         );
//                       }

//                       // Actualizar la UI
//                       if (mounted) {
//                         setState(() {
//                           // Mover bultos seleccionados a cerrados
//                           final bultosACerrar = _bultos.where((bulto) => selecciones[_bultos.indexOf(bulto)]).toList();
//                           _bultosCerrados.addAll(bultosACerrar);
                          
//                           // Eliminar de la lista de bultos activos
//                           _bultos.removeWhere((bulto) => bultosACerrar.contains(bulto));
                          
//                           // Actualizar bulto actual si es necesario
//                           if (_bultos.isEmpty) {
//                             _bultoActual = null;
//                             Navigator.of(context).pop();
//                           } else if (_bultoActual != null && !_bultos.contains(_bultoActual)) {
//                             _bultoActual = _bultos.first;
//                           }
//                         });
//                       }
//                     } catch (e) {
//                       if (mounted) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(content: Text('Error al procesar cierre: ${e.toString()}')),
//                         );
//                         setStateDialog(() {
//                           procesandoRetiro = false;
//                         });
//                       }
//                     }
//                   },
//                   child: const Text('Confirmar'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   void _eliminarBulto(Bulto bulto) {
//     if (_vistaMonitor) return;
    
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirmar eliminación'),
//         content: const Text('¿Estás seguro que deseas eliminar este bulto?'),
//         actions: [
//           TextButton(
//             child: const Text('Cancelar'),
//             onPressed: () => Navigator.of(context).pop(),
//           ),
//           TextButton(
//             child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
//             onPressed: () async {
//               await EntregaServices().patchBultoEstado(context, entrega.entregaId, bulto.bultoId, 'DESCARTADO', token);
//               Navigator.of(context).pop();
//               setState(() {
//                 _bultos.remove(bulto);
//                 if (_bultoActual == bulto) {
//                   _bultoActual = _bultos.isNotEmpty ? _bultos.first : null;
//                 }
//               });
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Bulto eliminado')),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _cargarItemsBulto(Bulto bulto) async {
//     if (bulto.bultoId == 0) return;

//     setState(() => _isLoadingLineas = true);
//     try {
//       final items = await EntregaServices().getItemsBulto(
//         context,
//         entrega.entregaId,
//         bulto.bultoId,
//         token,
//       );

//       // Usar las líneas ya cargadas para completar la información de los items
//       final itemsActualizados = items.map((item) {
//         final linea = _lineasOrdenSeleccionada.firstWhere(
//           (l) => l.pickLineaId == item.pickLineaId,
//           orElse: () => PickingLinea.empty(),
//         );
        
//         return item.copyWith(
//           cantidadMaxima: linea.cantidadPickeada,
//           item: linea.descripcion,
//           raiz: linea.codItem,
//         );
//       }).toList();

//       setState(() {
//         bulto.contenido.clear();
//         bulto.contenido.addAll(itemsActualizados);
//       });
//     } catch (e) {
//       Carteles.showDialogs(context, 'Error al cargar items del bulto', false, false, false);
//     } finally {
//       setState(() => _isLoadingLineas = false);
//     }
//   }

//   Widget _buildBultoVirtualSection() {
//     if (_bultoVirtual == null || _bultoVirtual!.contenido.isEmpty) {
//       return const Card(
//         child: Padding(
//           padding: EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Bulto Virtual',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//               SizedBox(height: 10),
//               Text('No hay productos en el bulto virtual'),
//             ],
//           ),
//         ),
//       );
//     }

//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Cantidad controlada',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//                 color: Colors.blue,
//               ),
//             ),
//             const SizedBox(height: 10),
//             ConstrainedBox(
//               constraints: const BoxConstraints(maxHeight: 300),
//               child: ListView.builder(
//                 shrinkWrap: true,
//                 itemCount: _bultoVirtual!.contenido.length,
//                 itemBuilder: (context, index) {
//                   final item = _bultoVirtual!.contenido[index];
//                   final (verificadaTotal, maximaTotal) = _getCantidadVerificadaYMaxima(item.raiz, item.pickLineaId);
                  
//                   return Container(
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey.shade300),
//                       borderRadius: BorderRadius.circular(8),
//                       color: Colors.blue.shade50,
//                     ),
//                     margin: const EdgeInsets.only(bottom: 8),
//                     child: ListTile(
//                       title: Text('${item.raiz} - ${item.item}'),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text('Cantidad: ${item.cantidad}'),
//                           Text('Total verificado: $verificadaTotal/$maximaTotal'),
//                         ],
//                       ),
//                       trailing: !_vistaMonitor ? IconButton(
//                         icon: const Icon(Icons.arrow_forward, color: Colors.blue),
//                         onPressed: () => _mostrarDialogoTransferencia(item),
//                       ) : null,
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBultosSection() {
//     final colors = Theme.of(context).colorScheme;

//     return StatefulBuilder(
//       builder: (context, setStateLocal) {
//         return Column(
//           children: [
//             if (_bultos.isNotEmpty || _bultosCerrados.isNotEmpty)
//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           const Text(
//                             'Bultos Físicos',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           Row(
//                             children: [
//                               const Text('Mostrar cerrados:'),
//                               Switch(
//                                 value: mostrarCerrados,
//                                 onChanged: (value) {
//                                   setStateLocal(() {
//                                     mostrarCerrados = value;
//                                     // Resetear bulto actual al cambiar vista
//                                     if (mostrarCerrados && _bultosCerrados.isNotEmpty) {
//                                       _bultoActual = _bultosCerrados.first;
//                                     } else if (!mostrarCerrados && _bultos.isNotEmpty) {
//                                       _bultoActual = _bultos.first;
//                                     } else {
//                                       _bultoActual = null;
//                                     }
//                                   });
//                                 },
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 10),
                      
//                       // Selector de bultos (ChoiceChips)
//                       SingleChildScrollView(
//                         scrollDirection: Axis.horizontal,
//                         child: Row(
//                           children: mostrarCerrados
//                               ? _bultosCerrados.map((bulto) => _buildBultoChip(bulto, colors, true))
//                                   .toList()
//                               : _bultos.map((bulto) => _buildBultoChip(bulto, colors, false))
//                                   .toList(),
//                         ),
//                       ),
                      
//                       // Detalle del bulto seleccionado
//                       if (_bultoActual != null)
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const SizedBox(height: 20),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     Builder(
//                                       builder: (context) {
//                                         final tipoBulto = tipoBultos.firstWhere(
//                                           (t) => t.tipoBultoId == _bultoActual!.tipoBultoId,
//                                           orElse: () => TipoBulto.empty()
//                                         );
//                                         return Text(
//                                           'Bulto ${(mostrarCerrados ? _bultosCerrados : _bultos).indexOf(_bultoActual!) + 1} - ${tipoBulto.descripcion}',
//                                           style: const TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 16,
//                                           ),
//                                         );
//                                       },
//                                     ),
//                                     const SizedBox(width: 10),
//                                     Text('Items: ${_bultoActual?.contenido.length}'),
//                                   ],
//                                 ),
//                                 if (!_vistaMonitor && !mostrarCerrados)
//                                   ElevatedButton.icon(
//                                     icon: const Icon(Icons.delete, size: 20),
//                                     label: const Text('Eliminar'),
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: Colors.red,
//                                       foregroundColor: Colors.white,
//                                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                                     ),
//                                     onPressed: () => _eliminarBulto(_bultoActual!),
//                                   ),
//                               ],
//                             ),
//                             const SizedBox(height: 10),
//                             const Text(
//                               'Contenido:',
//                               style: TextStyle(fontWeight: FontWeight.bold),
//                             ),
//                             ConstrainedBox(
//                               constraints: const BoxConstraints(maxHeight: 300),
//                               child: ListView.builder(
//                                 shrinkWrap: true,
//                                 itemCount: _bultoActual!.contenido.length,
//                                 itemBuilder: (context, index) {
//                                   final item = _bultoActual!.contenido[index];
//                                   final (verificadaTotal, maximaTotal) = _getCantidadVerificadaYMaxima(item.raiz, item.pickLineaId);
//                                   return Container(
//                                     decoration: BoxDecoration(
//                                       border: Border.all(color: Colors.grey.shade300),
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     margin: const EdgeInsets.only(bottom: 8),
//                                     child: ListTile(
//                                       title: Text('${item.raiz} - ${item.item}'),
//                                       subtitle: Column(
//                                         crossAxisAlignment: CrossAxisAlignment.start,
//                                         children: [
//                                           Text('En este bulto: ${item.cantidad}'),
//                                           Text('Total verificado: $verificadaTotal/$maximaTotal'),
//                                         ],
//                                       ),
//                                       trailing: Row(
//                                         mainAxisSize: MainAxisSize.min,
//                                         children: [
//                                           if (verificadaTotal >= maximaTotal)
//                                             const Icon(Icons.check_circle, color: Colors.green),
//                                           if (!_vistaMonitor && !mostrarCerrados) ...[
//                                             IconButton(
//                                               icon: const Icon(Icons.edit),
//                                               onPressed: () => _editarCantidadItem(item),
//                                             ),
//                                             IconButton(
//                                               icon: const Icon(Icons.delete, color: Colors.red),
//                                               onPressed: () => _eliminarItem(item),
//                                             ),
//                                           ],
//                                         ],
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//                           ],
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildBultoChip(Bulto bulto, ColorScheme colors, bool esCerrado) {
//     final tipoBulto = tipoBultos.firstWhere(
//       (t) => t.tipoBultoId == bulto.tipoBultoId,
//       orElse: () => TipoBulto.empty()
//     );
    
//     return Padding(
//       padding: const EdgeInsets.only(right: 8.0),
//       child: ChoiceChip(
//         label: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text('B ${(esCerrado ? _bultosCerrados : _bultos).indexOf(bulto) + 1}', 
//                 style: const TextStyle(fontSize: 22)),
//             const SizedBox(width: 8),
//             getIcon(tipoBulto.icon, context, _bultoActual == bulto ? colors.onPrimary : colors.secondary),
//           ],
//         ),
//         selected: _bultoActual == bulto,
//         onSelected: (selected) {
//           if (selected) {
//             setState(() {
//               _bultoActual = bulto;
//             });
//             _cargarItemsBulto(bulto).then((_) {
//               if (mounted) {
//                 setState(() {});
//               }
//             });
//           }
//         },
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final colors = Theme.of(context).colorScheme;
//     final isWideScreen = MediaQuery.of(context).size.width > 800;

//     return SafeArea(
//       child: Scaffold(
//         appBar: AppBar(
//           backgroundColor: colors.primary,
//           title: Text(
//             _vistaMonitor ? 'Monitor de Creación de Bultos - Entrega: ${entrega.entregaId}' : 'Creación de Bultos - Entrega: ${entrega.entregaId}', 
//             style: TextStyle(color: colors.onPrimary)
//           ),
//           iconTheme: IconThemeData(color: colors.onPrimary),
//         ),
//         body: SingleChildScrollView(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               if (_vistaMonitor)
//                 Container(
//                   padding: const EdgeInsets.all(16.0),
//                   color: Colors.orange[100],
//                   child: const Text(
//                     'MODO MONITOR: Solo visualización',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.orange,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         'Seleccionar Orden:',
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       const SizedBox(height: 10),
//                       DropdownButtonFormField<OrdenPicking>(
//                         value: _ordenSeleccionada,
//                         items: _ordenes.map((OrdenPicking orden) {
//                           return DropdownMenuItem<OrdenPicking>(
//                             value: orden,
//                             child: Text('${orden.serie}-${orden.numeroDocumento} - ${orden.nombre}'),
//                           );
//                         }).toList(),
//                         onChanged: _ordenes.length > 1 ? (OrdenPicking? nuevaOrden) {
//                           if (nuevaOrden != null) {
//                             setState(() {
//                               _ordenSeleccionada = nuevaOrden;
//                             });
//                             _cargarLineasOrden(nuevaOrden);
//                           }
//                         } : null,
//                         decoration: InputDecoration(
//                           border: const OutlineInputBorder(),
//                           enabled: _ordenes.length > 1
//                         ),
//                         isExpanded: true,
//                         disabledHint: _ordenSeleccionada != null 
//                             ? Text('${_ordenSeleccionada!.numeroDocumento}-${_ordenSeleccionada!.serie} - ${_ordenSeleccionada!.nombre}')
//                             : null,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),            
//               if (_ordenSeleccionada != null) ...[
//                 const SizedBox(height: 20),
//                 isWideScreen
//                   ? Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Expanded(
//                           flex: 1,
//                           child: _buildBultoVirtualSection(),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           flex: 1,
//                           child: _buildBultosSection(),
//                         ),
//                       ],
//                     )
//                   : Column(
//                       children: [
//                         _buildBultoVirtualSection(),
//                         const SizedBox(height: 20),
//                         _buildBultosSection(),
//                       ],
//                     ),
//               ],
//             ],
//           ),
//         ),
//         bottomNavigationBar: _vistaMonitor 
//             ? null 
//             : BottomAppBar(
//                 notchMargin: 10,
//                 elevation: 0,
//                 shape: const CircularNotchedRectangle(),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     if (_ordenSeleccionada != null && !_isLoadingLineas)
//                       ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: colors.primary,
//                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                         ),
//                         onPressed: _mostrarDialogoTipoBulto,
//                         child: Text(_bultos.isEmpty ? 'Crear Primer Bulto' : 'Crear Nuevo Bulto', style: TextStyle(color: colors.onPrimary)),
//                       ),
//                     if (_bultos.isNotEmpty)
//                       Tooltip(
//                         message: _validarCompletitudProductos() 
//                             ? '' 
//                             : 'No se pueden cerrar bultos hasta verificar todos los productos',
//                         child: ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: _validarCompletitudProductos() 
//                                 ? colors.primary 
//                                 : Colors.grey,
//                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                           ),
//                           onPressed: _validarCompletitudProductos() 
//                               ? _mostrarDialogoCierreBultos 
//                               : null,
//                           child: Text(
//                             'Cerrar Bultos', 
//                             style: TextStyle(
//                               color: _validarCompletitudProductos() 
//                                   ? colors.onPrimary 
//                                   : Colors.grey[700],
//                             ),
//                           ),
//                         ),
//                       ), 
//                   ],
//                 ),
//               ),
//       ),
//     );
//   }
// }