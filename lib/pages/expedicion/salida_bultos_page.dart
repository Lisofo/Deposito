import 'package:deposito/models/bulto.dart';
import 'package:deposito/models/entrega.dart';
import 'package:deposito/models/forma_envio.dart';
import 'package:deposito/models/modo_envio.dart';
import 'package:deposito/models/tipo_bulto.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/entrega_services.dart';
import 'package:deposito/services/product_services.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:deposito/widgets/custom_form_field.dart';
import 'package:deposito/widgets/icon_string.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/services/picking_services.dart';

class SalidaBultosScreenCopia extends StatefulWidget {
  const SalidaBultosScreenCopia({super.key});

  @override
  SalidaBultosScreenCopiaState createState() => SalidaBultosScreenCopiaState();
}

class SalidaBultosScreenCopiaState extends State<SalidaBultosScreenCopia> {
  
  OrdenPicking? _ordenSeleccionada;
  Bulto? _bultoActual;
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _comentarioController = TextEditingController();
  final PickingServices _pickingServices = PickingServices();
  bool _isLoadingLineas = false;
  late String token;
  FocusNode focoDeScanner = FocusNode();
  Entrega entrega = Entrega.empty();
  bool _vistaMonitor = false;
  bool mostrarCerrados = false; // Estado local para controlar qué bultos mostrar

  // Datos para envíos
  List<FormaEnvio> empresasEnvio = [];
  List<FormaEnvio> transportistas = [];
  List<FormaEnvio> formasEnvio = [];
  List<TipoBulto> tipoBultos = [];
  List<ModoEnvio> modoEnvios = [];
  List<OrdenPicking> _ordenes = [];
  final List<Bulto> _bultos = [];
  final List<Bulto> _bultosCerrados = [];
  List<PickingLinea> _lineasOrdenSeleccionada = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        focoDeScanner.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _comentarioController.dispose();
    focoDeScanner.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      token = productProvider.token;
      entrega = productProvider.entrega;
      _vistaMonitor = productProvider.vistaMonitor;
      
      // Load initial data
      formasEnvio = await EntregaServices().formaEnvio(context, token);
      tipoBultos = await EntregaServices().tipoBulto(context, token);
      modoEnvios = await EntregaServices().modoEnvio(context, token);
      
      // Load existing bultos for this delivery
      if (entrega.entregaId != 0) {
        final bultosExistentes = await EntregaServices().getBultosEntrega(
          context, 
          entrega.entregaId, 
          token
        );
        
        // Cargar items para cada bulto
        for (var bulto in bultosExistentes) {
          await _cargarItemsBulto(bulto);
          
          if (bulto.estado == 'CERRADO') {
            _bultosCerrados.add(bulto);
          } else if (bulto.estado == 'PENDIENTE') {
            _bultos.add(bulto);
          }
        }

        if (mounted) {
          setState(() {
            if (_bultos.isNotEmpty) {
              _bultoActual = _bultos.first;
            }
          });
        }
      }

      for (var forma in formasEnvio) {
        if(forma.tr == true) {
          transportistas.add(forma);
          transportistas.sort((a, b) => a.descripcion!.compareTo(b.descripcion.toString()));
        } 
        if (forma.envio == true) {
          empresasEnvio.add(forma);
          empresasEnvio.sort((a, b) => a.descripcion!.compareTo(b.descripcion.toString()));
        }
      }

      if (_vistaMonitor) {
        // Cargar órdenes desde los pickIds de la entrega
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
        if (mounted) {
          setState(() {
            _ordenes = ordenesMonitor;
            if (_ordenes.isNotEmpty) {
              _ordenSeleccionada = _ordenes[0];
              _cargarLineasOrden(_ordenSeleccionada!);
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _ordenes = productProvider.ordenesExpedicion;
            
            if (_ordenes.length == 1) {
              _ordenSeleccionada = _ordenes[0];
              _cargarLineasOrden(_ordenSeleccionada!);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        Carteles.showDialogs(context, 'Error al cargar datos iniciales: ${e.toString()}', false, false, false);
      }
    }
  }

  Future<void> _cargarLineasOrden(OrdenPicking orden) async {
    if (orden.lineas != null && orden.lineas!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _lineasOrdenSeleccionada = orden.lineas!;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoadingLineas = true);
    }
    
    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final token = productProvider.token;
      final almacenId = productProvider.almacen.almacenId;
      
      final ordenCompleta = await _pickingServices.getLineasOrder(
        context, 
        orden.pickId, 
        almacenId, 
        token
      ) as OrdenPicking?;

      if (ordenCompleta != null && mounted) {
        setState(() {
          _lineasOrdenSeleccionada = ordenCompleta.lineas ?? [];
          final index = _ordenes.indexWhere((o) => o.pickId == orden.pickId);
          if (index != -1) {
            _ordenes[index] = ordenCompleta;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        Carteles.showDialogs(context, 'Error al cargar líneas de orden: ${e.toString()}', false, false, false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLineas = false);
        focoDeScanner.requestFocus();
      }
    }
  }

  (int verificada, int maxima) _getCantidadVerificadaYMaxima(String codigoRaiz, int pickLineaId) {
    try {
      final linea = _lineasOrdenSeleccionada.firstWhere(
        (linea) => linea.pickLineaId == pickLineaId,
      );
      
      final verificada = [..._bultos, ..._bultosCerrados].fold(0, (total, bulto) {
        return total + bulto.contenido
          .where((item) => item.pickLineaId == pickLineaId)
          .fold(0, (sum, item) => sum + item.cantidad);
      });
      
      // Si la modalidad es PAPEL, usar cantidadPedida como máximo
      if (_ordenSeleccionada?.modalidad == 'PAPEL') {
        return (verificada, linea.cantidadPedida);
      } else {
        // Para WMS, usar cantidadPickeada como máximo
        return (verificada, linea.cantidadPickeada);
      }
    } catch (e) {
      return (0, 0);
    }
  }

  bool _validarCompletitudProductos() {
    if (_ordenSeleccionada == null || _lineasOrdenSeleccionada.isEmpty) return false;
    
    for (final linea in _lineasOrdenSeleccionada) {
      // Para PAPEL, verificar todas las líneas basado en cantidadPedida
      // Para WMS, solo verificar líneas con cantidadPickeada > 0
      if (_ordenSeleccionada!.modalidad == 'WMS' && linea.cantidadPickeada == 0) continue;
      
      final (cantidadVerificada, maxima) = _getCantidadVerificadaYMaxima(linea.codItem, linea.pickLineaId);
      if (cantidadVerificada < maxima) {
        return false;
      }
    }
    return true;
  }

  Future<void> procesarEscaneoUbicacion(String value) async {
    if (value.isEmpty || _bultoActual == null || _vistaMonitor) return;
    
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
      
      if (linea.codItem.isEmpty) {
        Carteles.showDialogs(context, 'Producto no encontrado en la orden', false, false, false);
        return;
      }
      
      // Obtener la cantidad máxima según la modalidad
      final maxima = _ordenSeleccionada?.modalidad == 'PAPEL' 
          ? linea.cantidadPedida 
          : linea.cantidadPickeada;
      
      final (cantidadVerificadaTotal, _) = _getCantidadVerificadaYMaxima(linea.codItem, linea.pickLineaId);
      
      // Siempre validar que no se supere la cantidad máxima
      if (cantidadVerificadaTotal >= maxima) {
        Carteles.showDialogs(
          context, 
          'Ya se verificó la cantidad máxima para este producto en todos los bultos', 
          false, 
          false, 
          false
        );
        return;
      }
      
      final index = _bultoActual!.contenido.indexWhere(
        (item) => item.pickLineaId == linea.pickLineaId
      );
      
      if (index != -1) {
        // Validar que no se supere la cantidad máxima al agregar
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
        
        if (_bultoActual!.bultoId != 0) {
          await EntregaServices().patchItemBulto(
            context,
            entrega.entregaId,
            _bultoActual!.bultoId,
            _bultoActual!.contenido[index].pickLineaId,
            _bultoActual!.contenido[index].cantidad + 1,
            token,
          );
        }
        
        if (mounted) {
          setState(() {
            _bultoActual!.contenido[index].cantidad += 1;
          });
        }
      } else {
        // Validar que no se supere la cantidad máxima al agregar
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
        
        if (_bultoActual!.bultoId != 0) {
          await EntregaServices().patchItemBulto(
            context,
            entrega.entregaId,
            _bultoActual!.bultoId,
            linea.pickLineaId,
            1,
            token,
          );
        }
        
        final nuevoItem = BultoItem(
          codigo: value,
          codigoRaiz: linea.codItem,
          cantidad: 1,
          descripcion: linea.descripcion,
          cantidadMaxima: maxima,
          bultoId: _bultoActual!.bultoId,
          bultoLinId: 0,
          pickLineaId: linea.pickLineaId
        );
        
        if (mounted) {
          setState(() {
            _bultoActual!.contenido.add(nuevoItem);
          });
        }
      }
      
      _codigoController.clear();
      if (mounted) {
        FocusScope.of(context).requestFocus(focoDeScanner);
      }
    } catch (e) {
      Carteles.showDialogs(context, 'Error al procesar el escaneo: ${e.toString()}', false, false, false);
      if (mounted) {
        FocusScope.of(context).requestFocus(focoDeScanner);
      }
    }
  }

  void _mostrarDialogoTipoBulto() {
    if (_vistaMonitor) return;
    
    final colors = Theme.of(context).colorScheme;
    
    // Determinar si es el primer bulto (no hay bultos activos)
    final bool esPrimerBulto = _bultos.isEmpty;
    
    // Filtrar tipos de bulto según el caso
    List<TipoBulto> tiposDisponibles = [];
    
    if (esPrimerBulto) {
      // Para el primer bulto, usar solo tipoBultoId = 4 (VIRTUAL)
      tiposDisponibles = tipoBultos.where((tipo) => tipo.tipoBultoId == 4).toList();
    } else {
      // Para bultos adicionales, excluir VIRTUAL
      tiposDisponibles = tipoBultos.where((tipo) => tipo.codTipoBulto != "VIRTUAL").toList();
    }
    
    if (tiposDisponibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay tipos de bulto disponibles')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(esPrimerBulto 
            ? 'Creando primer bulto (VIRTUAL)' 
            : 'Seleccionar tipo de bulto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: tiposDisponibles.map((tipo) {
                return ListTile(
                  leading: getIcon(tipo.icon, context, colors.secondary),
                  title: Text(tipo.descripcion),
                  onTap: () {
                    Navigator.of(context).pop();
                    _crearNuevoBulto(tipo);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _crearNuevoBulto(TipoBulto tipoBulto) async {
    if (_vistaMonitor) return;
    
    try {
      final nuevoBulto = await EntregaServices().postBultoEntrega(
        context,
        entrega.entregaId,
        tipoBulto.tipoBultoId,
        token,
      );

      if (nuevoBulto.bultoId != 0 && mounted) {
        setState(() {
          _bultos.add(nuevoBulto);
          _bultoActual = nuevoBulto;
        });
      }
    } catch (e) {
      Carteles.showDialogs(context, 'Error al crear el bulto', false, false, false);
    }
  }

  void _eliminarItem(BultoItem item) async {
    if (_vistaMonitor) return;
    
    final pickLineaId = item.pickLineaId;
    
    // Primero intentamos actualizar el servidor con conteo = 0
    if (_bultoActual?.bultoId != null && _bultoActual!.bultoId != 0) {
      try {
        await EntregaServices().patchItemBulto(
          context,
          entrega.entregaId,
          _bultoActual!.bultoId,
          pickLineaId,
          0, // Enviamos conteo = 0 para eliminar el item
          token,
        );
        
        // Si el servidor responde OK, eliminamos el item localmente
        if (mounted) {
          setState(() {
            _bultoActual?.contenido.remove(item);
          });
        }
        
      } catch (e) {
        // Si hay error, mostramos mensaje y mantenemos el item
        Carteles.showDialogs(context, 'Error al eliminar item', false, false, false);
      }
    } else {
      // Si es un bulto nuevo (sin ID), simplemente lo eliminamos localmente
      if (mounted) {
        setState(() {
          _bultoActual?.contenido.remove(item);
        });
      }
    }
  }

  void _editarCantidadItem(BultoItem item) {
    if (_vistaMonitor) return;
    
    final controller = TextEditingController(text: item.cantidad.toString());
    final (cantidadEnOtrosBultos, _) = _getCantidadVerificadaYMaxima(item.codigoRaiz, item.pickLineaId);
    final FocusNode focusNode = FocusNode();

    // Obtener la cantidad máxima correcta según la modalidad
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

    // Enfocar y seleccionar todo el texto al mostrar el diálogo
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
    if (_vistaMonitor) return;
    
    final nuevaCantidad = int.tryParse(nuevoValor) ?? item.cantidad;
    
    if (nuevaCantidad < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La cantidad no puede ser negativa')),
      );
      return;
    }
    
    if (nuevaCantidad == 0) {
      // Cantidad cero = eliminar el ítem
      _eliminarItem(item);
      return;
    }

    // Siempre validar que no se supere la cantidad máxima
    final totalProyectado = cantidadEnOtrosBultos - item.cantidad + nuevaCantidad;
    
    if (totalProyectado > cantidadMaxima) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No puede superar $cantidadMaxima (Total actual: $totalProyectado')),
      );
      return;
    }
    
    if (mounted) {
      setState(() {
        item.cantidad = nuevaCantidad;
      });
    }

    if (_bultoActual?.bultoId != null && _bultoActual!.bultoId != 0) {
      try {
        await EntregaServices().patchItemBulto(
          context,
          entrega.entregaId,
          _bultoActual!.bultoId,
          item.pickLineaId,
          item.cantidad,
          token,
        );
      } catch (e) {
        Carteles.showDialogs(context, 'Error al actualizar cantidad', false, false, false);
        // Revertir el cambio local si falla el servidor
        if (mounted) {
          setState(() {
            item.cantidad = int.tryParse(nuevoValor) ?? item.cantidad;
          });
        }
      }
    }
  }

  void _mostrarDialogoCierreBultos() {
    if (_vistaMonitor) return;
    
    // Primero filtrar los bultos no virtuales
    final bultosNoVirtuales = _bultos.where((bulto) {
      final tipoBulto = tipoBultos.firstWhere(
        (t) => t.tipoBultoId == bulto.tipoBultoId,
        orElse: () => TipoBulto.empty()
      );
      return tipoBulto.codTipoBulto != "VIRTUAL";
    }).toList();

    // Crear selecciones solo para bultos no virtuales
    final List<bool> selecciones = List.filled(bultosNoVirtuales.length, false);
    ModoEnvio? metodoEnvio;
    FormaEnvio? empresaEnvioSeleccionada;
    FormaEnvio? transportistaSeleccionado;
    final comentarioController = TextEditingController();
    bool procesandoRetiro = false;
    bool incluyeFactura = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Seleccionar bultos y método de envío'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Seleccionar bultos:'),
                    ...bultosNoVirtuales.asMap().entries.map((entry) {
                      final index = entry.key;
                      final bulto = entry.value;
                      final tipoBulto = tipoBultos.firstWhere(
                        (t) => t.tipoBultoId == bulto.tipoBultoId,
                        orElse: () => TipoBulto.empty()
                      );
                      return CheckboxListTile(
                        title: Text('Bulto ${index + 1} (${tipoBulto.descripcion})'),
                        value: selecciones[index],
                        onChanged: procesandoRetiro ? null : (value) {
                          setStateDialog(() {
                            selecciones[index] = value!;
                          });
                        },
                      );
                    }),
                    
                    const SizedBox(height: 20),
                    const Text('Método de envío:'),
                    DropdownButtonFormField<ModoEnvio>(
                      isExpanded: true,
                      value: metodoEnvio,
                      hint: const Text('Seleccione método'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder()
                      ),
                      items: modoEnvios.map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value.descripcion),
                        );
                      }).toList(),
                      onChanged: procesandoRetiro ? null : (ModoEnvio? newValue) {
                        setStateDialog(() {
                          metodoEnvio = newValue;
                          if (newValue?.modoEnvioId != 2) {
                            empresaEnvioSeleccionada = null;
                            transportistaSeleccionado = null;
                          }
                        });
                      },
                    ),
                    
                    if (metodoEnvio?.modoEnvioId == 2) ...[
                      const SizedBox(height: 10),                    
                      const Text('Transportista:'),
                      DropdownButtonFormField<FormaEnvio>(
                        isExpanded: true,
                        value: transportistaSeleccionado,
                        hint: const Text('Seleccione transportista'),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder()
                        ),
                        items: transportistas.map((FormaEnvio value) {
                          return DropdownMenuItem(
                            value: value,
                            child: Text(value.descripcion.toString()),
                          );
                        }).toList(),
                        onChanged: procesandoRetiro ? null : (FormaEnvio? newValue) {
                          setStateDialog(() {
                            transportistaSeleccionado = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      const Text('Empresa de envío:'),
                      DropdownSearch<FormaEnvio>(
                        popupProps: const PopupProps.menu(
                          showSearchBox: true,
                          searchDelay: Duration.zero,
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              hintText: "Buscar empresa...",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                        ),
                        items: empresasEnvio,
                        itemAsString: (FormaEnvio item) => item.descripcion.toString(),
                        selectedItem: empresaEnvioSeleccionada,
                        onChanged: procesandoRetiro ? null : (FormaEnvio? newValue) {
                          setStateDialog(() {
                            empresaEnvioSeleccionada = newValue;
                          });
                        },
                        dropdownDecoratorProps: const DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            hintText: "Seleccione empresa",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        compareFn: (item, selectedItem) => item.codFormaEnvio == selectedItem.codFormaEnvio,
                      ),
                    ],
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      title: const Text('Incluye factura'),
                      value: incluyeFactura,
                      onChanged: procesandoRetiro ? null : (bool? value) {
                        setStateDialog(() {
                          incluyeFactura = value ?? false;
                        });
                      },
                    ),
                    CustomTextFormField(
                      controller: comentarioController,
                      minLines: 1,
                      maxLines: 5,
                      hint: 'Comentario',
                      enabled: !procesandoRetiro,
                    ),
                    if (procesandoRetiro) 
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
              actions: [
                if (!procesandoRetiro)
                  TextButton(
                    child: const Text('Cancelar'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                TextButton(
                  onPressed: procesandoRetiro ? null : () async {
                    if (!_validarCompletitudProductos()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No se pueden cerrar bultos hasta verificar todos los productos de la orden'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                      return;
                    }

                    final bultosSeleccionados = selecciones.where((s) => s).length;
                    
                    if (metodoEnvio == null || bultosSeleccionados == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Debe seleccionar al menos un bulto y un método de envío')),
                      );
                      return;
                    }
                    
                    if (metodoEnvio?.modoEnvioId == 2 && (empresaEnvioSeleccionada == null || transportistaSeleccionado == null)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Para envío por correo debe seleccionar empresa y transportista')),
                      );
                      return;
                    }
                    
                    setStateDialog(() {
                      procesandoRetiro = true;
                    });

                    try {
                      // Procesar cada bulto seleccionado
                      for (int i = 0; i < selecciones.length; i++) {
                        if (selecciones[i]) {
                          final bulto = bultosNoVirtuales[i];
                          
                          // 1. Actualizar datos del bulto con PUT
                          await EntregaServices().putBultoEntrega(
                            context,
                            entrega.entregaId,
                            bulto.bultoId,
                            _ordenSeleccionada?.entidadId ?? 0, // clienteId
                            _ordenSeleccionada?.nombre ?? '', // nombreCliente
                            metodoEnvio!.modoEnvioId,
                            transportistaSeleccionado?.formaEnvioId ?? 0, // agenciaTrId
                            empresaEnvioSeleccionada?.formaEnvioId ?? 0, // agenciaUFId
                            '', // direccion
                            _ordenSeleccionada?.localidad ?? '', // localidad
                            _ordenSeleccionada?.telefono ?? '', // telefono
                            comentarioController.text, // comentarioEnvio
                            comentarioController.text, // comentario
                            bulto.tipoBultoId, // tipoBultoId
                            incluyeFactura,
                            bulto.nroBulto,
                            bulto.totalBultos,
                            token,
                          );

                          // 2. Cambiar estado del bulto a CERRADO
                          await EntregaServices().patchBultoEstado(
                            context,
                            entrega.entregaId,
                            bulto.bultoId,
                            'CERRADO',
                            token,
                          );
                        }
                      }

                      // Verificar si todos los bultos están cerrados
                      final bultosNoCerrados = await EntregaServices().getBultosEntrega(
                        context,
                        entrega.entregaId,
                        token,
                      ).then((bultos) => bultos.where((b) => b.estado != 'CERRADO').length);

                      if (bultosNoCerrados == 0) {
                        // 3. Si todos los bultos están cerrados, cerrar la entrega
                        await EntregaServices().patchEntregaEstado(
                          context,
                          entrega.entregaId,
                          'finalizado',
                          token,
                        );
                      }

                      // Actualizar la UI
                      if (mounted) {
                        setState(() {
                          // Mover bultos cerrados a la lista de cerrados
                          final bultosACerrar = bultosNoVirtuales.where((bulto) => 
                              selecciones[bultosNoVirtuales.indexOf(bulto)]).toList();
                          _bultosCerrados.addAll(bultosACerrar);
                          
                          // Eliminar de la lista de bultos activos
                          _bultos.removeWhere((bulto) => bultosACerrar.contains(bulto));
                          
                          // Actualizar bulto actual si es necesario
                          if (_bultos.isEmpty) {
                            _bultoActual = null;
                            Navigator.of(context).pop();
                          } else if (_bultoActual != null && !_bultos.contains(_bultoActual)) {
                            _bultoActual = _bultos.first;
                          }
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al procesar cierre: ${e.toString()}')),
                        );
                        setStateDialog(() {
                          procesandoRetiro = false;
                        });
                      }
                    }
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _eliminarBulto(Bulto bulto) {
    if (_vistaMonitor) return;
    
    // Obtener el tipo de bulto para verificar si es VIRTUAL
    final tipoBulto = tipoBultos.firstWhere(
      (t) => t.tipoBultoId == bulto.tipoBultoId,
      orElse: () => TipoBulto.empty()
    );
    
    // No permitir eliminar bultos VIRTUAL
    if (tipoBulto.codTipoBulto == "VIRTUAL") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pueden eliminar bultos virtuales')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro que deseas eliminar este bulto?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await EntregaServices().patchBultoEstado(context, entrega.entregaId, bulto.bultoId, 'DESCARTADO', token);
              if (mounted) {
                setState(() {
                  _bultos.remove(bulto);
                  if (_bultoActual == bulto) {
                    _bultoActual = _bultos.isNotEmpty ? _bultos.first : null;
                  }
                });
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _cargarItemsBulto(Bulto bulto) async {
    try {
      final items = await EntregaServices().getItemsBulto(
        context, 
        entrega.entregaId, 
        bulto.bultoId, 
        token
      );
      
      if (mounted) {
        setState(() {
          bulto.contenido = items;
        });
      }
    } catch (e) {
      if (mounted) {
        Carteles.showDialogs(context, 'Error al cargar items del bulto', false, false, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final provider = Provider.of<ProductProvider>(context);
    final bool esMonitor = provider.vistaMonitor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salida de Bultos'),
        actions: [
          if (!esMonitor)
            IconButton(
              icon: const Icon(Icons.add_box),
              onPressed: _mostrarDialogoTipoBulto,
            ),
          if (!esMonitor && _bultos.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _mostrarDialogoCierreBultos,
            ),
          IconButton(
            icon: Icon(mostrarCerrados ? Icons.lock_open : Icons.lock_outline),
            onPressed: () {
              setState(() {
                mostrarCerrados = !mostrarCerrados;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Selector de órdenes (solo si hay más de una)
          if (_ordenes.length > 1)
            Container(
              padding: const EdgeInsets.all(8),
              color: colors.surfaceVariant,
              child: DropdownButton<OrdenPicking>(
                isExpanded: true,
                value: _ordenSeleccionada,
                items: _ordenes.map((OrdenPicking orden) {
                  return DropdownMenuItem<OrdenPicking>(
                    value: orden,
                    child: Text('${orden.nombre} (${orden.pickId})'),
                  );
                }).toList(),
                onChanged: (OrdenPicking? nuevaOrden) {
                  if (nuevaOrden != null) {
                    setState(() {
                      _ordenSeleccionada = nuevaOrden;
                    });
                    _cargarLineasOrden(nuevaOrden);
                  }
                },
              ),
            ),

          // Campo de escaneo
          if (!esMonitor)
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      focusNode: focoDeScanner,
                      controller: _codigoController,
                      decoration: const InputDecoration(
                        labelText: 'Escanear ubicación',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: procesarEscaneoUbicacion,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () {
                      focoDeScanner.requestFocus();
                    },
                  ),
                ],
              ),
            ),

          // Selector de bultos
          if (!esMonitor && _bultos.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _bultos.length,
                itemBuilder: (context, index) {
                  final bulto = _bultos[index];
                  final tipoBulto = tipoBultos.firstWhere(
                    (t) => t.tipoBultoId == bulto.tipoBultoId,
                    orElse: () => TipoBulto.empty()
                  );
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text('Bulto ${index + 1} (${tipoBulto.descripcion})'),
                      selected: _bultoActual == bulto,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _bultoActual = bulto;
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ),

          // Bultos cerrados (si se están mostrando)
          if (mostrarCerrados && _bultosCerrados.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: colors.surfaceVariant.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bultos Cerrados:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _bultosCerrados.map((bulto) {
                      final tipoBulto = tipoBultos.firstWhere(
                        (t) => t.tipoBultoId == bulto.tipoBultoId,
                        orElse: () => TipoBulto.empty()
                      );
                      return Chip(
                        label: Text(tipoBulto.descripcion),
                        backgroundColor: colors.secondaryContainer,
                        deleteIcon: const Icon(Icons.visibility),
                        onDeleted: () {
                          setState(() {
                            _bultoActual = bulto;
                            mostrarCerrados = false;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Contenido principal
          Expanded(
            child: _isLoadingLineas
                ? const Center(child: CircularProgressIndicator())
                : _ordenSeleccionada == null
                    ? const Center(child: Text('Seleccione una orden'))
                    : _buildContenidoOrden(size, colors),
          ),
        ],
      ),
    );
  }

  Widget _buildContenidoOrden(Size size, ColorScheme colors) {
    return Row(
      children: [
        // Panel de productos de la orden
        Expanded(
          flex: 2,
          child: _buildPanelProductos(colors),
        ),

        // Panel de contenido del bulto actual
        Expanded(
          flex: 3,
          child: _buildPanelBultoActual(size, colors),
        ),
      ],
    );
  }

  Widget _buildPanelProductos(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: colors.outline)),
      ),
      child: Column(
        children: [
          Text(
            'Productos de la Orden (${_ordenSeleccionada?.modalidad ?? 'N/A'})',
            style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _lineasOrdenSeleccionada.length,
              itemBuilder: (context, index) {
                final linea = _lineasOrdenSeleccionada[index];
                
                // Para WMS, omitir líneas sin cantidad pickeada
                if (_ordenSeleccionada?.modalidad == 'WMS' && linea.cantidadPickeada == 0) {
                  return const SizedBox.shrink();
                }
                
                final (cantidadVerificada, maxima) = _getCantidadVerificadaYMaxima(
                  linea.codItem, 
                  linea.pickLineaId
                );
                
                final bool completo = cantidadVerificada >= maxima;
                
                return Card(
                  color: completo ? colors.surfaceVariant : null,
                  child: ListTile(
                    title: Text(linea.codItem),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(linea.descripcion),
                        Text('$cantidadVerificada/$maxima ${completo ? '✓' : ''}'),
                      ],
                    ),
                    trailing: completo ? const Icon(Icons.check_circle, color: Colors.green) : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelBultoActual(Size size, ColorScheme colors) {
    final bulto = _bultoActual;
    
    if (bulto == null) {
      return const Center(child: Text('No hay bultos activos'));
    }

    final tipoBulto = tipoBultos.firstWhere(
      (t) => t.tipoBultoId == bulto.tipoBultoId,
      orElse: () => TipoBulto.empty()
    );

    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bulto: ${tipoBulto.descripcion}',
                style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary),
              ),
              if (!_vistaMonitor && tipoBulto.codTipoBulto != "VIRTUAL")
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _eliminarBulto(bulto),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Contenido del bulto
          Expanded(
            child: bulto.contenido.isEmpty
                ? const Center(child: Text('El bulto está vacío'))
                : ListView.builder(
                    itemCount: bulto.contenido.length,
                    itemBuilder: (context, index) {
                      final item = bulto.contenido[index];
                      return Card(
                        child: ListTile(
                          title: Text(item.codigo),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.descripcion),
                              Text('Cantidad: ${item.cantidad}'),
                            ],
                          ),
                          trailing: !_vistaMonitor ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editarCantidadItem(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _eliminarItem(item),
                              ),
                            ],
                          ) : null,
                        ),
                      );
                    },
                  ),
          ),
          
          // Resumen del bulto
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total items: ${bulto.contenido.length}'),
                Text('Estado: ${bulto.estado}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}