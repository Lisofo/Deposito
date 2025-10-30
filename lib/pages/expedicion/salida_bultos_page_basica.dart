import 'package:deposito/config/router/pages.dart';
import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/bulto.dart';
import 'package:deposito/models/entrega.dart';
import 'package:deposito/models/forma_envio.dart';
import 'package:deposito/models/modo_envio.dart';
import 'package:deposito/models/tipo_bulto.dart';
import 'package:deposito/pages/expedicion/cierre_de_bultos_page.dart';
import 'package:deposito/services/entrega_services.dart';
import 'package:deposito/services/product_services.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:deposito/widgets/icon_string.dart';
import 'package:flutter/material.dart';
import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/services/picking_services.dart';
import 'package:visibility_detector/visibility_detector.dart';

class SalidaBultosPageBasica extends StatefulWidget {
  final Entrega? entregaExterna;
  final bool? esModoMonitor;

  const SalidaBultosPageBasica({
    super.key,
    this.entregaExterna,
    this.esModoMonitor,
  });

  @override
  SalidaBultosPageBasicaState createState() => SalidaBultosPageBasicaState();
}

class SalidaBultosPageBasicaState extends State<SalidaBultosPageBasica> {
  
  OrdenPicking? _ordenSeleccionada;
  Bulto? _bultoVirtual;
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _codigoController2 = TextEditingController();
  final PickingServices _pickingServices = PickingServices();
  bool _isLoadingLineas = false;
  late String token;
  FocusNode focoDeScanner = FocusNode();
  FocusNode focoDeScanner2 = FocusNode();
  Entrega entrega = Entrega.empty();
  bool _vistaMonitor = false;
  bool _entregaFinalizada = false;

  // Datos para envíos
  late List<FormaEnvio> empresasEnvio = [];
  late List<FormaEnvio> transportistas = [];
  late List<FormaEnvio> formasEnvio = [];
  late List<TipoBulto> tipoBultos = [];
  late List<ModoEnvio> modoEnvios = [];
  late List<OrdenPicking> _ordenes = [];
  final List<Bulto> _bultosCerrados = [];
  List<PickingLinea> _lineasOrdenSeleccionada = [];
  bool _procesandoCierre = false;
  final ScrollController _scrollController = ScrollController();

  // Mapa para guardar la relación entre pickLineaId y el índice en la lista
  final Map<int, int> _lineaIndexMap = {};

  @override
  void initState() {
    super.initState();
    
    if (widget.entregaExterna != null && widget.esModoMonitor == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final productProvider = Provider.of<ProductProvider>(context, listen: false);
          productProvider.setEntrega(widget.entregaExterna as Entrega);
          productProvider.setVistaMonitor(true);
          _cargarDatosIniciales();
        }
      });
    } else {
      _cargarDatosIniciales();
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    focoDeScanner.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    token = productProvider.token;
    
    if (widget.entregaExterna != null) {
      entrega = widget.entregaExterna!;
    } else {
      entrega = productProvider.entrega;
    }
    
    if (widget.esModoMonitor != null) {
      _vistaMonitor = widget.esModoMonitor!;
    } else {
      _vistaMonitor = productProvider.vistaMonitor;
    }
    
    _entregaFinalizada = entrega.estado == 'finalizado';
    
    formasEnvio = await EntregaServices().formaEnvio(context, token);
    tipoBultos = await EntregaServices().tipoBulto(context, token);
    modoEnvios = await EntregaServices().modoEnvio(context, token);
    
    if (_vistaMonitor) {
      final List<OrdenPicking> ordenesMonitor = [];
      for (var pickId in entrega.pickIds) {
        final orden = await _pickingServices.getLineasOrder(
          context,
          pickId,
          productProvider.almacen.almacenId,
          token,
        ) as OrdenPicking?;
        if (orden != null) {
          ordenesMonitor.add(orden);
        }
      }
      setState(() {
        _ordenes = ordenesMonitor;
        if (_ordenes.isNotEmpty) {
          _ordenSeleccionada = _ordenes[0];
          _lineasOrdenSeleccionada = _ordenSeleccionada!.lineas ?? [];
        }
      });
    } else {
      setState(() {
        _ordenes = productProvider.ordenesExpedicion;
        _ordenSeleccionada = _ordenes[0];
        _lineasOrdenSeleccionada = _ordenSeleccionada!.lineas ?? [];
      });
    }

    if (_ordenSeleccionada != null && _lineasOrdenSeleccionada.isEmpty) {
      await _cargarLineasOrden(_ordenSeleccionada!);
    }

    if (entrega.entregaId != 0) {
      final bultosExistentes = await EntregaServices().getBultosEntrega(
        context, 
        entrega.entregaId, 
        token
      );
      
      for (var bulto in bultosExistentes) {
        final tipoBulto = tipoBultos.firstWhere(
          (t) => t.tipoBultoId == bulto.tipoBultoId,
          orElse: () => TipoBulto.empty()
        );
        
        if (tipoBulto.codTipoBulto == "VIRTUAL") {
          await _cargarItemsBulto(bulto);
          setState(() {
            _bultoVirtual = bulto;
          });
          break;
        } else if (bulto.estado == 'CERRADO') {
          _bultosCerrados.add(bulto);
        }
      }

      if (_bultoVirtual == null && !_vistaMonitor && !_entregaFinalizada) {
        await _crearBultoVirtual();
      }
    }

    transportistas.clear();
    empresasEnvio.clear();

    for (var forma in formasEnvio) {
      if(forma.tr == true) {
        transportistas.add(forma);
      } 
      if (forma.envio == true) {
        empresasEnvio.add(forma);
      }
    }

    transportistas.sort((a, b) => a.descripcion!.compareTo(b.descripcion.toString()));
    empresasEnvio.sort((a, b) => a.descripcion!.compareTo(b.descripcion.toString()));
  }

  Future<void> _crearBultoVirtual() async {
    if (_vistaMonitor || _entregaFinalizada) return;
    
    try {
      final tipoVirtual = tipoBultos.firstWhere(
        (t) => t.codTipoBulto == "VIRTUAL",
        orElse: () => TipoBulto.empty()
      );
      
      if (tipoVirtual.tipoBultoId == 0) {
        Carteles.showDialogs(context, 'No se encontró el tipo de bulto VIRTUAL', false, false, false);
        return;
      }

      final nuevoBulto = await EntregaServices().postBultoEntrega(
        context,
        entrega.entregaId,
        tipoVirtual.tipoBultoId,
        token,
      );

      if (nuevoBulto.bultoId != 0) {
        setState(() {
          _bultoVirtual = nuevoBulto;
        });
      }
    } catch (e) {
      Carteles.showDialogs(context, 'Error al crear el bulto virtual', false, false, false);
    }
  }

  Future<void> _cargarLineasOrden(OrdenPicking orden) async {
    if (orden.lineas != null && orden.lineas!.isNotEmpty) {
      setState(() {
        _lineasOrdenSeleccionada = orden.lineas!;
      });
      return;
    }

    setState(() => _isLoadingLineas = true);
    try {
      final token = Provider.of<ProductProvider>(context, listen: false).token;
      final almacenId = Provider.of<ProductProvider>(context, listen: false).almacen.almacenId;
      
      final ordenCompleta = await _pickingServices.getLineasOrder(
        context, 
        orden.pickId, 
        almacenId, 
        token
      ) as OrdenPicking?;

      if (ordenCompleta != null) {
        setState(() {
          _lineasOrdenSeleccionada = ordenCompleta.lineas ?? [];
          final index = _ordenes.indexWhere((o) => o.pickId == orden.pickId);
          if (index != -1) {
            _ordenes[index] = ordenCompleta;
          }
        });
      }
    } finally {
      setState(() => _isLoadingLineas = false);
    }
  }

  (int verificada, int maxima) _getCantidadVerificadaYMaxima(String codigoRaiz, int pickLineaId) {
    try {
      final linea = _lineasOrdenSeleccionada.firstWhere(
        (linea) => linea.pickLineaId == pickLineaId,
        orElse: () => PickingLinea.empty(),
      );
      
      if (linea.pickLineaId == 0) {
        return (0, 0);
      }
      
      int verificada = 0;
      if (_bultoVirtual != null) {
        verificada = _bultoVirtual!.contenido
          .where((item) => item.pickLineaId == pickLineaId)
          .fold(0, (sum, item) => sum + item.cantidad);
      }
      
      int maxima;
      if (_ordenSeleccionada?.modalidad == 'PAPEL') {
        maxima = linea.cantidadPedida;
      } else {
        maxima = linea.cantidadPickeada;
      }
      
      return (verificada, maxima);
    } catch (e) {
      return (0, 0);
    }
  }

  bool _validarCompletitudProductos() {
    for (final linea in _lineasOrdenSeleccionada) {
      if (_ordenSeleccionada?.modalidad == 'WMS' && linea.cantidadPickeada == 0) continue;
      
      final (cantidadVerificada, maxima) = _getCantidadVerificadaYMaxima(linea.codItem, linea.pickLineaId);
      if (cantidadVerificada < maxima) {
        return true;
      }
    }
    return true;
  }

  bool _verificarCompletitudTodasOrdenes() {
    for (var orden in _ordenes) {
      final lineasOrden = orden.lineas ?? [];
      
      for (var linea in lineasOrden) {
        if (orden.modalidad == 'WMS' && linea.cantidadPickeada == 0) {
          continue;
        }
        
        final (cantidadVerificada, maxima) = _getCantidadVerificadaYMaxima(linea.codItem, linea.pickLineaId);
        
        debugPrint('Línea ${linea.pickLineaId}: Verificada=$cantidadVerificada, Máxima=$maxima');
        
        if (cantidadVerificada < maxima) {
          return false;
        }
      }
    }
    return true;
  }

  Future<void> procesarEscaneoUbicacion(String value, bool invisible) async {
    if (value.isEmpty || _bultoVirtual == null || _vistaMonitor || _entregaFinalizada) return;
    
    try {
      final provider = Provider.of<ProductProvider>(context, listen: false);  
      final productos = await ProductServices().getProductByName(
        context, 
        '', 
        '2', 
        provider.almacen.almacenId.toString(), 
        value, 
        '0', 
        provider.token
      );
      
      if (productos.isEmpty) {
        Carteles.showDialogs(context, 'Producto no encontrado', false, false, false);
        return;
      }

      final producto = productos[0];
      final linea = _lineasOrdenSeleccionada.firstWhere(
        (linea) => linea.codItem == producto.raiz,
        orElse: () => PickingLinea.empty(),
      );
      
      if (linea.codItem == '') {
        Carteles.showDialogs(context, 'Producto no encontrado en la orden', false, false, false);
        return;
      }
      
      final maxima = _ordenSeleccionada?.modalidad == 'PAPEL' 
          ? linea.cantidadPedida 
          : linea.cantidadPickeada;
      
      final (cantidadVerificadaTotal, _) = _getCantidadVerificadaYMaxima(linea.codItem, linea.pickLineaId);
      
      if (cantidadVerificadaTotal >= maxima) {
        Carteles.showDialogs(
          context, 
          'Ya se verificó la cantidad máxima para este producto', 
          false, 
          false, 
          false
        );
        return;
      }
      
      final index = _bultoVirtual!.contenido.indexWhere(
        (item) => item.pickLineaId == linea.pickLineaId
      );
      
      if (index != -1) {
        final nuevaCantidadTotal = cantidadVerificadaTotal + 1;
        if (nuevaCantidadTotal > maxima) {
          Carteles.showDialogs(
            context, 
            'No puede superar la cantidad máxima ($nuevaCantidadTotal/$maxima)', 
            false, 
            false, 
            false
          );
          return;
        }
        
        if (_bultoVirtual!.bultoId != 0) {
          await EntregaServices().patchItemBulto(
            context,
            entrega.entregaId,
            _bultoVirtual!.bultoId,
            _bultoVirtual!.contenido[index].pickLineaId,
            _bultoVirtual!.contenido[index].cantidad + 1,
            token,
          );
        }
        
        setState(() {
          _bultoVirtual!.contenido[index].cantidad += 1;
        });
      } else {
        final nuevaCantidadTotal = cantidadVerificadaTotal + 1;
        if (nuevaCantidadTotal > maxima) {
          Carteles.showDialogs(
            context, 
            'No puede superar la cantidad máxima ($nuevaCantidadTotal/$maxima)', 
            false, 
            false, 
            false
          );
          return;
        }
        
        if (_bultoVirtual!.bultoId != 0) {
          await EntregaServices().patchItemBulto(
            context,
            entrega.entregaId,
            _bultoVirtual!.bultoId,
            linea.pickLineaId,
            1,
            token,
          );
        }
        
        final nuevoItem = BultoItem(
          codItem: value,
          raiz: linea.codItem,
          cantidad: 1,
          item: linea.descripcion,
          cantidadMaxima: maxima,
          bultoId: _bultoVirtual!.bultoId,
          bultoLinId: 0,
          pickLineaId: linea.pickLineaId, 
          pickId: linea.pickId,
          itemId: linea.itemId
        );
        
        setState(() {
          _bultoVirtual!.contenido.add(nuevoItem);
        });
      }

      // Después de procesar el escaneo, hacer scroll hacia la línea
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollHaciaLineaPorId(linea.pickLineaId);
      });

      if (invisible) {
        _codigoController2.clear();
        FocusScope.of(context).requestFocus(focoDeScanner2);
      } else {
        _codigoController.clear();
        if (mounted) {
          FocusScope.of(context).requestFocus(focoDeScanner);
        }
      }
      
    } catch (e) {
      Carteles.showDialogs(context, 'Error al procesar el escaneo: ${e.toString()}', false, false, false);
      if (mounted) {
        FocusScope.of(context).requestFocus(focoDeScanner);
      }
    }
  }

  // Nuevo método para hacer scroll hacia una línea específica
  void _scrollHaciaLineaPorId(int pickLineaId) {
    if (_lineaIndexMap.containsKey(pickLineaId)) {
      final index = _lineaIndexMap[pickLineaId]!;
      const double itemHeight = 100.0;
      final double targetPosition = index * itemHeight;

      _scrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _eliminarItem(BultoItem item) async {
    if (_vistaMonitor || _entregaFinalizada) return;
    
    final pickLineaId = item.pickLineaId;
    
    if (_bultoVirtual?.bultoId != null && _bultoVirtual!.bultoId != 0) {
      try {
        await EntregaServices().patchItemBulto(
          context,
          entrega.entregaId,
          _bultoVirtual!.bultoId,
          pickLineaId,
          0,
          token,
        );
        
        setState(() {
          _bultoVirtual?.contenido.remove(item);
        });
        
      } catch (e) {
        Carteles.showDialogs(context, 'Error al eliminar item', false, false, false);
        if (mounted) {
          setState(() {});
        }
      }
    } else {
      setState(() {
        _bultoVirtual?.contenido.remove(item);
      });
    }
  }

  void _editarCantidadItem(BultoItem item) {
    if (_vistaMonitor || _entregaFinalizada) return;
    
    final controller = TextEditingController(text: item.cantidad.toString());
    final (cantidadEnOtrosBultos, _) = _getCantidadVerificadaYMaxima(item.raiz, item.pickLineaId);
    final FocusNode focusNode = FocusNode();

    final linea = _lineasOrdenSeleccionada.firstWhere(
      (l) => l.pickLineaId == item.pickLineaId,
      orElse: () => PickingLinea.empty(),
    );
    final cantidadMaxima = _ordenSeleccionada?.modalidad == 'PAPEL' 
        ? linea.cantidadPedida 
        : linea.cantidadPickeada;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar cantidad'),
          content: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Nueva cantidad'),
            onSubmitted: (value) async {
              await _procesarEdicionCantidad(
                item, 
                controller.text, 
                cantidadEnOtrosBultos, 
                cantidadMaxima
              );
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Guardar'),
              onPressed: () async {
                await _procesarEdicionCantidad(
                  item, 
                  controller.text, 
                  cantidadEnOtrosBultos, 
                  cantidadMaxima
                );
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );

    focusNode.requestFocus();
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  Future<void> _procesarEdicionCantidad(
    BultoItem item, 
    String nuevoValor, 
    int cantidadEnOtrosBultos, 
    int cantidadMaxima
  ) async {
    if (_vistaMonitor || _entregaFinalizada) return;
    
    final nuevaCantidad = int.tryParse(nuevoValor) ?? item.cantidad;
    
    if (nuevaCantidad < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La cantidad no puede ser negativa')),
      );
      return;
    }
    
    if (nuevaCantidad == 0) {
      _eliminarItem(item);
      return;
    }

    final totalProyectado = cantidadEnOtrosBultos - item.cantidad + nuevaCantidad;
    
    if (totalProyectado > cantidadMaxima) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No puede superar $cantidadMaxima (Total actual: $totalProyectado')),
      );
      return;
    }
    
    setState(() {
      item.cantidad = nuevaCantidad;
    });

    if (_bultoVirtual?.bultoId != null && _bultoVirtual!.bultoId != 0) {
      try {
        await EntregaServices().patchItemBulto(
          context,
          entrega.entregaId,
          _bultoVirtual!.bultoId,
          item.pickLineaId,
          item.cantidad,
          token,
        );
      } catch (e) {
        Carteles.showDialogs(context, 'Error al actualizar cantidad', false, false, false);
        if (mounted) {
          setState(() {
            item.cantidad = int.tryParse(nuevoValor) ?? item.cantidad;
          });
        }
      }
    }
  }

  Future<void> _cargarItemsBulto(Bulto bulto) async {
    if (bulto.bultoId == 0) return;

    setState(() => _isLoadingLineas = true);
    try {
      final items = await EntregaServices().getItemsBulto(
        context,
        entrega.entregaId,
        bulto.bultoId,
        token,
      );

      final itemsActualizados = items.map((item) {
        final linea = _lineasOrdenSeleccionada.firstWhere(
          (l) => l.pickLineaId == item.pickLineaId,
          orElse: () => PickingLinea.empty(),
        );
        
        return item.copyWith(
          cantidadMaxima: linea.cantidadPickeada,
          item: linea.descripcion,
          raiz: linea.codItem,
        );
      }).toList();

      setState(() {
        bulto.contenido.clear();
        bulto.contenido.addAll(itemsActualizados);
      });
    } catch (e) {
      Carteles.showDialogs(context, 'Error al cargar items del bulto', false, false, false);
    } finally {
      setState(() => _isLoadingLineas = false);
    }
  }

  Future<void> _reimprimirEtiquetas() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reimprimiendo etiquetas...')),
      );
      
      await Future.delayed(const Duration(seconds: 2));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Etiquetas reimpresas correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al reimprimir etiquetas: ${e.toString()}')),
      );
    }
  }

  Future<void> _mostrarPopupImprimirDetalle() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Imprimir Detalle'),
        content: const Text('¿Desea imprimir el detalle de la entrega?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _imprimirDetalleEntrega();
            },
            child: const Text('Imprimir'),
          ),
        ],
      ),
    );
  }

  Future<void> _imprimirDetalleEntrega() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imprimiendo detalle de entrega...')),
      );

      // Imprimir detalle del bulto virtual (que representa la entrega completa)
      await EntregaServices().imprimirDetalle(
        context,
        _bultoVirtual!.bultoId,
        Provider.of<ProductProvider>(context, listen: false).almacen.almacenId,
        token,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Detalle de entrega impreso correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al imprimir detalle: ${e.toString()}')),
      );
    }
  }

  Widget _buildProductosSection() {
    // Limpiar el mapa al reconstruir la sección
    _lineaIndexMap.clear();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Productos:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            
            _isLoadingLineas
              ? const Center(child: CircularProgressIndicator())
              : _lineasOrdenSeleccionada.isEmpty
                  ? const Text('No hay productos en esta orden')
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: double.infinity),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _ordenSeleccionada!.modalidad == 'PAPEL' 
                            ? _lineasOrdenSeleccionada.length
                            : _lineasOrdenSeleccionada.where((linea) => linea.cantidadPickeada != 0).length,
                        itemBuilder: (context, index) {
                          final linea = _ordenSeleccionada!.modalidad == 'PAPEL'
                              ? _lineasOrdenSeleccionada[index]
                              : _lineasOrdenSeleccionada.where((linea) => linea.cantidadPickeada != 0).toList()[index];
                          
                          // Guardar el índice de esta línea en el mapa
                          _lineaIndexMap[linea.pickLineaId] = index;
                          
                          final (verificada, maxima) = _getCantidadVerificadaYMaxima(linea.codItem, linea.pickLineaId);
                          final itemVerificado = _bultoVirtual?.contenido.firstWhere(
                            (item) => item.pickLineaId == linea.pickLineaId,
                            orElse: () => BultoItem.empty()
                          );
                          
                          return Container(
                            color: verificada == maxima ? Colors.green.shade500 : (verificada < maxima && verificada >= 1) ? Colors.yellow.shade300 : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: _entregaFinalizada ? null : () => _navigateToSimpleProductPage(linea),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        margin: const EdgeInsets.only(right: 12),
                                        child: Image.network(
                                          linea.fotosUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.inventory_2, color: Colors.grey),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${linea.codItem} - ${linea.descripcion}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),                                        
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 12,
                                          children: [
                                            _buildInfoBadge('Pickeado', '${linea.cantidadPickeada}/${linea.cantidadPedida}'),
                                            _buildInfoBadge('Verificado', '$verificada/$maxima'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!_vistaMonitor && !_entregaFinalizada && itemVerificado != null) ...[
                                        Column(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 18),
                                              onPressed: () => _editarCantidadItem(itemVerificado),
                                              padding: EdgeInsets.zero,
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                              onPressed: () => _eliminarItem(itemVerificado),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black)),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _navigateToSimpleProductPage(PickingLinea linea) {
    if (_entregaFinalizada) return;
    
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    productProvider.setRaiz(linea.codItem);
    appRouter.push('/simpleProductPage'); 
  }

  void _mostrarDialogoCierreBultos() async {
    if (_vistaMonitor || _entregaFinalizada) return;
    
    final todasCompletas = _verificarCompletitudTodasOrdenes();
    bool verificacionParcial = !todasCompletas;
    
    final continuar = await _mostrarDialogoConfirmacionCierre(todasCompletas);
    
    if (!continuar) {
      return;
    }

    if (_ordenSeleccionada?.envio == false || _ordenSeleccionada?.envio == null) {
      await _cerrarEntregaDirectamente();
      return;
    }
    
    try {
      final resultado = await EntregaServices().verificarEntrega(
        context, 
        entrega.entregaId, 
        _bultoVirtual!.bultoId, 
        verificacionParcial, 
        token
      );
      
      if (!resultado) {
        Carteles.showDialogs(context, 'Error al verificar la entrega', false, false, false);
        return;
      }
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SalidaCierreBultosPage(
            entrega: entrega,
            ordenSeleccionada: _ordenSeleccionada!,
            bultoVirtual: _bultoVirtual!,
            tipoBultos: tipoBultos,
            modoEnvios: modoEnvios,
            transportistas: transportistas,
            empresasEnvio: empresasEnvio,
            token: token,
          ),
        ),
      ).then((_) {
        _cargarDatosIniciales();
      });
      
    } catch (e) {
      Carteles.showDialogs(context, 'Error al verificar la entrega: ${e.toString()}', false, false, false);
    }
  }

  Future<void> _cerrarEntregaDirectamente() async {
    setState(() {
      _procesandoCierre = true;
    });

    try {
      await EntregaServices().putBultoEntrega(
        context,
        entrega.entregaId,
        _bultoVirtual!.bultoId,
        _ordenSeleccionada!.entidadId,
        _ordenSeleccionada!.nombre,
        0,
        0,
        0,
        '',
        _ordenSeleccionada!.localidad,
        _ordenSeleccionada!.departamentoEnvio,
        _ordenSeleccionada!.telefono,
        '',
        '',
        _bultoVirtual!.tipoBultoId,
        false,
        _bultoVirtual!.nroBulto,
        _bultoVirtual!.totalBultos,
        token,
      );

      await EntregaServices().patchBultoEstado(
        context,
        entrega.entregaId,
        _bultoVirtual!.bultoId,
        'CERRADO',
        token,
      );

      await EntregaServices().cerrarEntrega(
        context,
        entrega.entregaId,
        token,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrega finalizada exitosamente')),
      );

      await _cargarDatosIniciales();

      if (mounted) {
        setState(() {
          _entregaFinalizada = true;
          _procesandoCierre = false;
        });
      }

    } catch (e) {
      Carteles.showDialogs(context, 'Error al finalizar la entrega: ${e.toString()}', false, false, false);
      if (mounted) {
        setState(() {
          _procesandoCierre = false;
        });
      }
    } finally {
      Navigator.of(context).popUntil((route) => route.settings.name == '/expedicionPaquetes');
      GoRouter.of(context).pushReplacement('/expedicionPaquetes');
    }
  }

  Future<bool> _mostrarDialogoConfirmacionCierre(bool estaCompleto) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(estaCompleto ? 'Verificación completa' : 'Verificación incompleta'),
          content: Text(
            estaCompleto && _ordenSeleccionada?.envio == false ? 'La verificación está completa.' 
              : estaCompleto && _ordenSeleccionada?.envio == true ? "La verificación está completa. ¿Está seguro de que desea proceder al cierre de bultos?" 
                : 'Hay líneas que no han sido verificadas completamente. ¿Desea continuar igual con el cierre de bultos?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Widget _buildBultosCerradosSection() {
    if (_bultosCerrados.isEmpty) {
      return Container();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bultos Cerrados:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _bultosCerrados.length,
              itemBuilder: (context, index) {
                final bulto = _bultosCerrados[index];
                final tipoBulto = tipoBultos.firstWhere(
                  (t) => t.tipoBultoId == bulto.tipoBultoId,
                  orElse: () => TipoBulto.empty()
                );
                
                return ListTile(
                  leading: getIcon(tipoBulto.icon, context, Colors.grey),
                  title: Text('Bulto ${bulto.bultoId} - ${tipoBulto.descripcion}'),
                  subtitle: Text('Estado: ${bulto.estado}'),
                  trailing: _entregaFinalizada
                    ? IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () => _verDetallesBulto(bulto),
                      )
                    : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _verDetallesBulto(Bulto bulto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles del Bulto ${bulto.nroBulto}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tipo: ${tipoBultos.firstWhere((t) => t.tipoBultoId == bulto.tipoBultoId, orElse: () => TipoBulto.empty()).descripcion}'),
              Text('Estado: ${bulto.estado}'),
              Text('Comentario: ${bulto.comentario}'),
              const SizedBox(height: 16),
              const Text('Contenido:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...bulto.contenido.map((item) => 
                ListTile(
                  title: Text(item.item),
                  subtitle: Text('Cantidad: ${item.cantidad}'),
                )
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerField() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        focusNode: focoDeScanner,
        controller: _codigoController,
        decoration: InputDecoration(
          labelText: 'Escanear código de producto',
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.barcode_reader),
          enabled: !_vistaMonitor && !_entregaFinalizada,
        ),
        onSubmitted: (value) async {
          await procesarEscaneoUbicacion(value, false);
          _codigoController.clear();
          FocusScope.of(context).requestFocus(focoDeScanner);
        },
        autofocus: false,
        readOnly: _vistaMonitor || _entregaFinalizada,
      ),
    );
  }

  Widget _buildSelectorOrdenes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seleccionar Orden:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _ordenes.length,
                itemBuilder: (context, index) {
                  final orden = _ordenes[index];
                  final bool isSelected = _ordenSeleccionada?.pickId == orden.pickId;
                  
                  return Container(
                    margin: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        '${orden.serie}-${orden.numeroDocumento}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: _entregaFinalizada ? null : (selected) {
                        if (selected) {
                          setState(() {
                            _ordenSeleccionada = orden;
                          });
                          _cargarLineasOrden(orden);
                        }
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: Theme.of(context).primaryColor,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colors.primary,
          title: Text(
            _vistaMonitor ? 'Monitor - Contenido Entrega: ${entrega.entregaId}' 
              : _entregaFinalizada ? 'Entrega Finalizada - ${entrega.entregaId}' 
              : 'Verificación de Productos - Entrega: ${entrega.entregaId}', 
            style: TextStyle(color: colors.onPrimary)
          ),
          iconTheme: IconThemeData(color: colors.onPrimary),
        ),
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            if (!_vistaMonitor && !_entregaFinalizada)
              SliverPersistentHeader(
                pinned: true,
                delegate: _ScannerHeaderDelegate(
                  minHeight: 80.0,
                  maxHeight: 80.0,
                  child: _buildScannerField(),
                ),
              ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_vistaMonitor)
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      color: Colors.orange[100],
                      child: const Text(
                        'MODO MONITOR: Solo visualización',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  if (_entregaFinalizada)
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      color: Colors.green[100],
                      child: const Text(
                        'ENTREGA FINALIZADA - MODO SOLO LECTURA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  _buildSelectorOrdenes(),
                  SizedBox.shrink(
                    child: VisibilityDetector(
                      key: const Key('scanner-field-visibility'),
                      onVisibilityChanged: (info) {
                        if (info.visibleFraction > 0) {
                          focoDeScanner2.requestFocus();
                        }
                      },
                      child: TextFormField(
                        focusNode: focoDeScanner2,
                        cursorColor: Colors.transparent,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(borderSide: BorderSide.none),
                        ),
                        style: const TextStyle(color: Colors.transparent),
                        autofocus: true,
                        keyboardType: TextInputType.none,
                        controller: _codigoController2,
                        onFieldSubmitted: (value) => procesarEscaneoUbicacion(value, true),
                      ),
                    )
                  ), 
                  if (_ordenSeleccionada != null && MediaQuery.of(context).size.width > 600)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Detalles de la Orden Seleccionada:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Cliente: ${_ordenSeleccionada!.nombre}'),
                                    Text('Tipo: ${_ordenSeleccionada!.descTipo}'),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Documento: ${_ordenSeleccionada!.serie}-${_ordenSeleccionada!.numeroDocumento}'),
                                    if (_ordenSeleccionada!.envio == false)
                                      Text('Tipo de entrega: MOSTRADOR', style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade700
                                      )),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),            
                  if (_ordenSeleccionada != null) ...[
                    _buildProductosSection(),
                    const SizedBox(height: 20),
                    _buildBultosCerradosSection(),
                  ],
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _vistaMonitor 
            ? BottomAppBar(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.description, color: colors.onPrimary,),
                        label: const Text('Reimprimir Detalle'),
                        onPressed: _mostrarPopupImprimirDetalle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : _entregaFinalizada
                ? BottomAppBar(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // ElevatedButton.icon(
                          //   icon: const Icon(Icons.print),
                          //   label: const Text('Reimprimir Etiquetas'),
                          //   onPressed: _reimprimirEtiquetas,
                          //   style: ElevatedButton.styleFrom(
                          //     backgroundColor: colors.primary,
                          //     foregroundColor: colors.onPrimary,
                          //   ),
                          // ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.inventory_2),
                            label: const Text('Ver Bultos'),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => SalidaCierreBultosPage(
                                    entrega: entrega,
                                    ordenSeleccionada: _ordenSeleccionada!,
                                    bultoVirtual: _bultoVirtual!,
                                    tipoBultos: tipoBultos,
                                    modoEnvios: modoEnvios,
                                    transportistas: transportistas,
                                    empresasEnvio: empresasEnvio,
                                    token: token,
                                    modoReadOnly: true,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : BottomAppBar(
                    notchMargin: 10,
                    elevation: 0,
                    shape: const CircularNotchedRectangle(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _procesandoCierre
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _validarCompletitudProductos() 
                                      ? colors.primary 
                                      : Colors.grey,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                onPressed: _procesandoCierre ? null : _mostrarDialogoCierreBultos,
                                child: Text(
                                  (_ordenSeleccionada?.envio == false || _ordenSeleccionada?.envio == null) 
                                    ? 'Finalizar Entrega' 
                                    : 'Siguiente',
                                  style: TextStyle(
                                    color: _validarCompletitudProductos() 
                                        ? colors.onPrimary 
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _ScannerHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _ScannerHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(_ScannerHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}