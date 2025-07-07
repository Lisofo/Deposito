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
import 'package:intl/intl.dart';

class SalidaBultosScreen extends StatefulWidget {
  const SalidaBultosScreen({super.key});

  @override
  SalidaBultosScreenState createState() => SalidaBultosScreenState();
}

class SalidaBultosScreenState extends State<SalidaBultosScreen> {
  
  OrdenPicking? _ordenSeleccionada;
  Bulto? _bultoActual;
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _comentarioController = TextEditingController();
  final PickingServices _pickingServices = PickingServices();
  bool _isLoadingLineas = false;
  late String token;
  FocusNode focoDeScanner = FocusNode();
  Entrega entrega = Entrega.empty();

  // Datos para envíos
  late List<FormaEnvio> empresasEnvio = [];
  late List<FormaEnvio> transportistas = [];
  late List<FormaEnvio> formasEnvio = [];
  late List<TipoBulto> tipoBultos = [];
  late List<ModoEnvio> modoEnvios = [];
  late List<OrdenPicking> _ordenes = [];
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
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    token = productProvider.token;
    entrega = productProvider.entrega;
    
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
      }
      
      setState(() {
        _bultos.addAll(bultosExistentes);
        if (_bultos.isNotEmpty) {
          _bultoActual = _bultos.first;
        }
      });
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

    setState(() {
      _ordenes = productProvider.ordenesExpedicion;
      
      if (_ordenes.length == 1) {
        _ordenSeleccionada = _ordenes[0];
        _cargarLineasOrden(_ordenSeleccionada!);
      }
    });
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
      if (mounted) {
        focoDeScanner.requestFocus();
      }
    }
  }

  int _getCantidadVerificada(String codigoRaiz) {
    // Sumar de todos los bultos (activos y cerrados)
    return [..._bultos, ..._bultosCerrados].fold(0, (total, bulto) {
      final bultoItems = bulto.contenido.where((item) => item.codigoRaiz == codigoRaiz);
      return total + bultoItems.fold(0, (sum, item) => sum + item.cantidad);
    });
  }

  bool _validarCompletitudProductos() {
    for (final linea in _lineasOrdenSeleccionada) {
      if (linea.cantidadPickeada == 0) continue;
      
      final cantidadVerificada = _getCantidadVerificada(linea.codItem);
      if (cantidadVerificada < linea.cantidadPickeada) {
        return false;
      }
    }
    return true;
  }

  Future<void> procesarEscaneoUbicacion(String value) async {
    if (value.isEmpty || _bultoActual == null) return;
    
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
      
      final cantidadVerificadaTotal = _getCantidadVerificada(linea.codItem);
      if (cantidadVerificadaTotal >= linea.cantidadPickeada) {
        Carteles.showDialogs(
          context, 
          'Ya se verificó la cantidad máxima para este producto en todos los bultos', 
          false, 
          false, 
          false
        );
        return;
      }
      
      // Buscar por pickLineaId en lugar de codigo o codigoRaiz
      final index = _bultoActual!.contenido.indexWhere(
        (item) => item.pickLineaId == linea.pickLineaId
      );
      
      if (index != -1) {
        // Item existente - incrementar cantidad
        final nuevaCantidadTotal = cantidadVerificadaTotal + 1;
        if (nuevaCantidadTotal > linea.cantidadPickeada) {
          Carteles.showDialogs(
            context, 
            'No puede superar la cantidad total pickeada ($nuevaCantidadTotal/${linea.cantidadPickeada})', 
            false, 
            false, 
            false
          );
          return;
        }
        
        // Primero actualizar en el servidor
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
        
        // Luego actualizar localmente
        setState(() {
          _bultoActual!.contenido[index].cantidad += 1;
        });
      } else {
        // Nuevo item
        final nuevaCantidadTotal = cantidadVerificadaTotal + 1;
        if (nuevaCantidadTotal > linea.cantidadPickeada) {
          Carteles.showDialogs(
            context, 
            'No puede superar la cantidad total pickeada ($nuevaCantidadTotal/${linea.cantidadPickeada})', 
            false, 
            false, 
            false
          );
          return;
        }
        
        // Primero crear en el servidor si el bulto existe
        if (_bultoActual!.bultoId != 0) {
          await EntregaServices().patchItemBulto(
            context,
            entrega.entregaId,
            _bultoActual!.bultoId,
            linea.pickLineaId,
            1, // Cantidad inicial
            token,
          );
        }
        
        // Luego crear localmente
        final nuevoItem = BultoItem(
          codigo: value,
          codigoRaiz: linea.codItem,
          cantidad: 1,
          descripcion: linea.descripcion,
          cantidadMaxima: linea.cantidadPickeada,
          bultoId: _bultoActual!.bultoId,
          bultoLinId: 0,
          pickLineaId: linea.pickLineaId
        );
        
        setState(() {
          _bultoActual!.contenido.add(nuevoItem);
        });
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
    final colors = Theme.of(context).colorScheme;
    if (tipoBultos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay tipos de bulto disponibles')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar tipo de bulto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: tipoBultos.map((tipo) {
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
    try {
      final nuevoBulto = await EntregaServices().postBultoEntrega(
        context,
        entrega.entregaId,
        tipoBulto.tipoBultoId,
        token,
      );

      if (nuevoBulto.bultoId != 0) {
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
    final pickLineaId = item.pickLineaId;
    final cantidadOriginal = item.cantidad;
    
    setState(() {
      _bultoActual?.contenido.remove(item);
    });

    // Si el bulto está guardado, actualizar el servidor
    if (_bultoActual?.bultoId != null && _bultoActual!.bultoId != 0) {
      try {
        await EntregaServices().patchItemBulto(
          context,
          entrega.entregaId,
          _bultoActual!.bultoId,
          pickLineaId,
          0, // Cantidad 0 para eliminar
          token,
        );
      } catch (e) {
        // Si falla, revertir el cambio
        setState(() {
          item.cantidad = cantidadOriginal;
          _bultoActual?.contenido.add(item);
        });
        Carteles.showDialogs(context, 'Error al eliminar item', false, false, false);
      }
    }
  }

  void _editarCantidadItem(BultoItem item) {
    final controller = TextEditingController(text: item.cantidad.toString());
    final cantidadEnOtrosBultos = _getCantidadVerificada(item.codigoRaiz) - item.cantidad;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar cantidad'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Nueva cantidad'),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Guardar'),
              onPressed: () async {
                final nuevaCantidad = int.tryParse(controller.text) ?? item.cantidad;
                final totalProyectado = cantidadEnOtrosBultos + nuevaCantidad;
                
                if (totalProyectado > item.cantidadMaxima) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No puede superar ${item.cantidadMaxima} (Total actual: $totalProyectado')),
                  );
                  return;
                }
                
                setState(() {
                  item.cantidad = nuevaCantidad;
                });

                // Actualizar en el servidor si el bulto ya está guardado
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
                  }
                }

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoCierreBultos() {
    final List<bool> selecciones = List.filled(_bultos.length, false);
    ModoEnvio? metodoEnvio;
    FormaEnvio? empresaEnvioSeleccionada;
    String? transportista;
    _comentarioController.text = '';
    bool _procesandoRetiro = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Evita que se cierre al tocar fuera
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
                    ..._bultos.asMap().entries.map((entry) {
                      final index = entry.key;
                      final bulto = entry.value;
                      final tipoBulto = tipoBultos.firstWhere(
                        (t) => t.tipoBultoId == bulto.tipoBultoId,
                        orElse: () => TipoBulto.empty()
                      );
                      return CheckboxListTile(
                        title: Text('Bulto ${index + 1} (${tipoBulto.descripcion})'),
                        value: selecciones[index],
                        onChanged: _procesandoRetiro ? null : (value) {
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
                      onChanged: _procesandoRetiro ? null : (ModoEnvio? newValue) {
                        setStateDialog(() {
                          metodoEnvio = newValue;
                          if (newValue?.modoEnvioId != 2) {
                            empresaEnvioSeleccionada = null;
                            transportista = null;
                          }
                        });
                      },
                    ),
                    
                    if (metodoEnvio?.modoEnvioId == 2) ...[
                      const SizedBox(height: 10),                    
                      const Text('Transportista:'),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: transportista,
                        hint: const Text('Seleccione transportista'),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder()
                        ),
                        items: transportistas.map((FormaEnvio value) {
                          return DropdownMenuItem(
                            value: value.descripcion,
                            child: Text(value.descripcion.toString()),
                          );
                        }).toList(),
                        onChanged: _procesandoRetiro ? null : (String? newValue) {
                          setStateDialog(() {
                            transportista = newValue;
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
                        onChanged: _procesandoRetiro ? null : (FormaEnvio? newValue) {
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
                    CustomTextFormField(
                      controller: _comentarioController,
                      minLines: 1,
                      maxLines: 5,
                      hint: 'Comentario',
                      enabled: !_procesandoRetiro,
                    ),
                    if (_procesandoRetiro) 
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
              actions: [
                if (!_procesandoRetiro)
                  TextButton(
                    child: const Text('Cancelar'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                TextButton(
                  onPressed: _procesandoRetiro ? null : () async {
                    // Validar que todos los productos estén completos
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
                    
                    if (metodoEnvio?.modoEnvioId == 2 && (empresaEnvioSeleccionada == null || transportista == null)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Para envío por correo debe seleccionar empresa y transportista')),
                      );
                      return;
                    }
                    
                    setStateDialog(() {
                      _procesandoRetiro = true;
                    });

                    try {
                      // Procesar cada bulto seleccionado
                      for (int i = 0; i < selecciones.length; i++) {
                        if (selecciones[i]) {
                          final bulto = _bultos[i];
                          
                          // Registrar el retiro del bulto
                          await EntregaServices().postRetiroBulto(
                            context,
                            bulto.bultoId,
                            empresaEnvioSeleccionada?.formaEnvioId ?? 0,
                            transportista ?? '',
                            _comentarioController.text,
                            token,
                          );
                        }
                      }

                      // Actualizar la UI
                      if (mounted) {
                        setState(() {
                          // Mover bultos cerrados a la lista de cerrados
                          final bultosACerrar = _bultos.where((bulto) => selecciones[_bultos.indexOf(bulto)]).toList();
                          _bultosCerrados.addAll(bultosACerrar);
                          
                          // Eliminar de la lista activa
                          _bultos.removeWhere((bulto) => selecciones[_bultos.indexOf(bulto)]);
                          
                          if (_bultos.isEmpty) {
                            _bultoActual = null;
                            Navigator.of(context).pop(); // Cerrar diálogo si no hay más bultos
                          } else if (_bultoActual != null && !_bultos.contains(_bultoActual)) {
                            _bultoActual = _bultos.first;
                          }
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al procesar retiro: ${e.toString()}')),
                        );
                        setStateDialog(() {
                          _procesandoRetiro = false;
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
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _bultos.remove(bulto);
                if (_bultoActual == bulto) {
                  _bultoActual = _bultos.isNotEmpty ? _bultos.first : null;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bulto eliminado')),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _cargarItemsBulto(Bulto bulto) async {
    if (bulto.bultoId == 0) return; // Bulto nuevo que aún no se guardó

    setState(() => _isLoadingLineas = true);
    try {
      final items = await EntregaServices().getItemsBulto(
        context,
        entrega.entregaId,
        bulto.bultoId,
        token,
      );

      setState(() {
        // En lugar de reasignar el campo, limpiamos y agregamos los nuevos items
        bulto.contenido.clear();
        bulto.contenido.addAll(items);
      });
    } catch (e) {
      Carteles.showDialogs(context, 'Error al cargar items del bulto', false, false, false);
    } finally {
      setState(() => _isLoadingLineas = false);
    }
  }

  Widget _buildProductosSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalles de la Orden:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Text('Cliente: ${_ordenSeleccionada!.nombre}'),
            Text('Tipo: ${_ordenSeleccionada!.descTipo}'),
            const SizedBox(height: 10),
            const Text(
              'Productos:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            _isLoadingLineas
              ? const Center(child: CircularProgressIndicator())
              : _lineasOrdenSeleccionada.isEmpty
                  ? const Text('No hay productos en esta orden')
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _lineasOrdenSeleccionada.where((linea) => linea.cantidadPickeada != 0).length,
                        itemBuilder: (context, index) {
                          final linea = _lineasOrdenSeleccionada.where((linea) => linea.cantidadPickeada != 0).toList()[index];
                          final cantidadVerificada = _getCantidadVerificada(linea.codItem);
                          return ListTile(
                            title: Text('${linea.pickLineaId} - ${linea.codItem} - ${linea.descripcion}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pickeado: ${linea.cantidadPickeada}/${linea.cantidadPedida}'),
                                Text('Verificado: $cantidadVerificada/${linea.cantidadPickeada}'),
                              ],
                            ),
                            trailing: cantidadVerificada >= linea.cantidadPickeada
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : null,
                          );
                        },
                      ),
                    ),
          ],
        ),
      ),
    );
  }

  Widget _buildBultosSection() {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        if (_bultos.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bultos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _bultos.map((bulto) {
                        final tipoBulto = tipoBultos.firstWhere(
                          (t) => t.tipoBultoId == bulto.tipoBultoId,
                          orElse: () => TipoBulto.empty()
                        );
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Bulto ${_bultos.indexOf(bulto) + 1}', style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 8,),
                                getIcon(tipoBulto.icon, context, _bultoActual == bulto ? colors.onPrimary : colors.secondary)
                              ],
                            ),
                            selected: _bultoActual == bulto,
                            onSelected: (selected) {
                              if (selected) {
                                _cargarItemsBulto(bulto);
                              }
                              setState(() {
                                _bultoActual = selected ? bulto : null;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (_bultoActual != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Builder(
                            builder: (context) {
                              final tipoBulto = tipoBultos.firstWhere(
                                (t) => t.tipoBultoId == _bultoActual!.tipoBultoId,
                                orElse: () => TipoBulto.empty()
                              );
                              return Text(
                                'Bulto ${_bultos.indexOf(_bultoActual!) + 1} - ${tipoBulto.descripcion}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              );
                            },
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.delete, size: 20),
                            label: const Text('Eliminar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () => _eliminarBulto(_bultoActual!),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        focusNode: focoDeScanner,
                        controller: _codigoController,
                        decoration: const InputDecoration(
                          labelText: 'Escanear código de producto',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.barcode_reader),
                        ),
                        onSubmitted: (value) async {
                          await procesarEscaneoUbicacion(value);
                          _codigoController.clear();
                          FocusScope.of(context).requestFocus(focoDeScanner);
                        },
                        autofocus: true,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Contenido del bulto:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _bultoActual!.contenido.length,
                          itemBuilder: (context, index) {
                            final item = _bultoActual!.contenido[index];
                            final cantidadTotal = _getCantidadVerificada(item.codigoRaiz);
                            return ListTile(
                              title: Text('${item.pickLineaId} - ${item.codigo} - ${item.descripcion}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('En este bulto: ${item.cantidad}'),
                                  Text('Total verificado: $cantidadTotal/${item.cantidadMaxima}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (cantidadTotal >= item.cantidadMaxima)
                                    const Icon(Icons.check_circle, color: Colors.green),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editarCantidadItem(item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _eliminarItem(item),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBultosCerradosSection() {
    if (_bultosCerrados.isEmpty) return const SizedBox();

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
                
                return ExpansionTile(
                  leading: getIcon(tipoBulto.icon, context, Theme.of(context).colorScheme.secondary),
                  title: Text('Bulto ${index + 1} - ${tipoBulto.descripcion}'),
                  subtitle: Text('Cerrado el ${DateFormat('dd/MM/yyyy HH:mm').format(bulto.fechaBulto)}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: bulto.contenido.map((item) => ListTile(
                          title: Text('${item.pickLineaId} - ${item.descripcion}'),
                          subtitle: Text('Cantidad: ${item.cantidad}'),
                        )).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        title: Text('Salida por Bultos', style: TextStyle(color: colors.onPrimary)),
        iconTheme: IconThemeData(color: colors.onPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
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
                    DropdownButtonFormField<OrdenPicking>(
                      value: _ordenSeleccionada,
                      items: _ordenes.map((OrdenPicking orden) {
                        return DropdownMenuItem<OrdenPicking>(
                          value: orden,
                          child: Text('${orden.serie}-${orden.numeroDocumento} - ${orden.nombre}'),
                        );
                      }).toList(),
                      onChanged: _ordenes.length > 1 ? (OrdenPicking? nuevaOrden) {
                        if (nuevaOrden != null) {
                          setState(() {
                            _ordenSeleccionada = nuevaOrden;
                          });
                          _cargarLineasOrden(nuevaOrden);
                        }
                      } : null,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        enabled: _ordenes.length > 1
                      ),
                      isExpanded: true,
                      disabledHint: _ordenSeleccionada != null 
                          ? Text('${_ordenSeleccionada!.numeroDocumento}-${_ordenSeleccionada!.serie} - ${_ordenSeleccionada!.nombre}')
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),            
            if (_ordenSeleccionada != null) ...[
              const SizedBox(height: 20),
              isWideScreen
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildProductosSection(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: _buildBultosSection(),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildProductosSection(),
                      const SizedBox(height: 20),
                      _buildBultosSection(),
                    ],
                  ),
              _buildBultosCerradosSection(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        notchMargin: 10,
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_ordenSeleccionada != null && !_isLoadingLineas)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: _mostrarDialogoTipoBulto,
                child: Text('Crear Nuevo Bulto', style: TextStyle(color: colors.onPrimary)),
              ),
            if (_bultos.isNotEmpty)
              Tooltip(
                message: _validarCompletitudProductos() 
                    ? '' 
                    : 'No se pueden cerrar bultos hasta verificar todos los productos',
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _validarCompletitudProductos() 
                        ? colors.primary 
                        : Colors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: _validarCompletitudProductos() 
                      ? _mostrarDialogoCierreBultos 
                      : null,
                  child: Text(
                    'Cerrar Bultos y Seleccionar Envío', 
                    style: TextStyle(
                      color: _validarCompletitudProductos() 
                          ? colors.onPrimary 
                          : Colors.grey[700],
                    ),
                  ),
                ),
              ), 
          ],
        ),
      ),
    );
  }
}