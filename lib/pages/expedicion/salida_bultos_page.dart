import 'package:deposito/models/forma_envio.dart';
import 'package:deposito/models/modo_envio.dart';
import 'package:deposito/models/tipo_bulto.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/entrega_services.dart';
import 'package:deposito/services/product_services.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/services/picking_services.dart';

class SalidaBultosScreen extends StatefulWidget {
  const SalidaBultosScreen({super.key});

  @override
  SalidaBultosScreenState createState() => SalidaBultosScreenState();
}

class SalidaBultosScreenState extends State<SalidaBultosScreen> {
  final List<Bulto> _bultos = [];
  late List<OrdenPicking> _ordenes = [];
  OrdenPicking? _ordenSeleccionada;
  List<PickingLinea> _lineasOrdenSeleccionada = [];
  Bulto? _bultoActual;
  final TextEditingController _codigoController = TextEditingController();
  final PickingServices _pickingServices = PickingServices();
  bool _isLoadingLineas = false;
  late String token;
  FocusNode focoDeScanner = FocusNode();

  // Datos para envíos
  late List<FormaEnvio> empresasEnvio = [];
  late List<FormaEnvio> transportistas = [];
  late List<FormaEnvio> formasEnvio = [];
  late List<TipoBulto> tipoBultos = [];
  late List<ModoEnvio> modoEnvios = [];

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
    focoDeScanner.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    token = context.read<ProductProvider>().token;
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    formasEnvio = await EntregaServices().formaEnvio(context, token);
    tipoBultos = await EntregaServices().tipoBulto(context, token);
    modoEnvios = await EntregaServices().modoEnvio(context, token);
    
    for (var forma in formasEnvio) {
      if(forma.tr != null) {
        transportistas.add(forma);
      } else {
        empresasEnvio.add(forma);
      }
    }

    setState(() {
      _ordenes = productProvider.ordenesExpedicion;
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
    return _bultos.fold(0, (total, bulto) {
      return total + bulto.contenido
          .where((item) => item.codigoRaiz == codigoRaiz)
          .fold(0, (sum, item) => sum + item.cantidad);
    });
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
      
      setState(() {
        final index = _bultoActual!.contenido.indexWhere(
          (item) => item.codigo == value || item.codigoRaiz == linea.codItem
        );
        
        if (index != -1) {
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
          
          _bultoActual!.contenido[index].cantidad += 1;
        } else {
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
          
          _bultoActual!.contenido.add(
            BultoItem(
              codigo: value,
              codigoRaiz: linea.codItem,
              cantidad: 1,
              descripcion: linea.descripcion,
              cantidadMaxima: linea.cantidadPickeada,
            ),
          );
        }
      });
      
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
    if (tipoBultos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay tipos de bulto disponibles')),
      );
      return;
    }

    TipoBulto? tipoSeleccionado;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar tipo de bulto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: tipoBultos.map((tipo) {
                return RadioListTile<TipoBulto>(
                  title: Text(tipo.descripcion),
                  value: tipo,
                  groupValue: tipoSeleccionado,
                  onChanged: (TipoBulto? value) {
                    tipoSeleccionado = value;
                    Navigator.of(context).pop();
                    if (value != null) {
                      _crearNuevoBulto(value.descripcion, tipoBultoId: value.tipoBultoId);
                    }
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _crearNuevoBulto(String tipoDescripcion, {int? tipoBultoId}) {
    final nuevoBulto = Bulto(
      nombre: 'Bulto ${_bultos.length + 1}',
      tipo: tipoDescripcion,
      tipoBultoId: tipoBultoId,
      contenido: [],
    );

    setState(() {
      _bultos.add(nuevoBulto);
      _bultoActual = nuevoBulto;
    });
  }

  void _eliminarItem(BultoItem item) {
    setState(() {
      _bultoActual?.contenido.remove(item);
    });
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
              onPressed: () {
                final nuevaCantidad = int.tryParse(controller.text) ?? item.cantidad;
                final totalProyectado = cantidadEnOtrosBultos + nuevaCantidad;
                
                if (totalProyectado > item.cantidadMaxima) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No puede superar ${item.cantidadMaxima} (Total actual: $totalProyectado)')),
                  );
                  return;
                }
                
                setState(() {
                  item.cantidad = nuevaCantidad;
                });
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
    String? metodoEnvio;
    String? empresaEnvio;
    String? transportista;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                      return CheckboxListTile(
                        title: Text('${bulto.nombre} (${bulto.tipo})'),
                        value: selecciones[index],
                        onChanged: (value) {
                          setState(() {
                            selecciones[index] = value!;
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 20),
                    const Text('Método de envío:'),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: metodoEnvio,
                      hint: const Text('Seleccione método'),
                      items: ['Correo', 'Transporte', 'Retiro en local'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          metodoEnvio = newValue;
                          if (newValue != 'Correo') {
                            empresaEnvio = null;
                            transportista = null;
                          }
                        });
                      },
                    ),
                    
                    if (metodoEnvio == 'Correo') ...[
                      const SizedBox(height: 20),
                      const Text('Empresa de envío:'),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: empresaEnvio,
                        hint: const Text('Seleccione empresa'),
                        items: empresasEnvio.map((FormaEnvio value) {
                          return DropdownMenuItem(
                            value: value.codFormaEnvio,
                            child: Text(value.descripcion.toString()),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            empresaEnvio = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      const Text('Transportista:'),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: transportista,
                        hint: const Text('Seleccione transportista'),
                        items: transportistas.map((FormaEnvio value) {
                          return DropdownMenuItem(
                            value: value.codFormaEnvio,
                            child: Text(value.descripcion.toString()),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            transportista = newValue;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Confirmar'),
                  onPressed: () {
                    if (metodoEnvio == null || !selecciones.contains(true)) {
                      return;
                    }
                    
                    if (metodoEnvio == 'Correo' && (empresaEnvio == null || transportista == null)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Para envío por correo debe seleccionar empresa y transportista')),
                      );
                      return;
                    }
                    
                    String mensaje = '${selecciones.where((s) => s).length} bultos cerrados para envío por $metodoEnvio';
                    if (metodoEnvio == 'Correo') {
                      mensaje += '\nEmpresa: $empresaEnvio\nTransportista: $transportista';
                    }
                    
                    _mostrarDialogo(
                      'Bultos cerrados',
                      mensaje,
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostrarDialogo(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensaje),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
                      onChanged: (OrdenPicking? nuevaOrden) {
                        if (nuevaOrden != null) {
                          setState(() {
                            _ordenSeleccionada = nuevaOrden;
                          });
                          _cargarLineasOrden(nuevaOrden);
                        }
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (_ordenSeleccionada != null)
              Card(
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
                            : Column(
                                children: _lineasOrdenSeleccionada
                                    .where((linea) => linea.cantidadPickeada != 0)
                                    .map((linea) {
                                      final cantidadVerificada = _getCantidadVerificada(linea.codItem);
                                      return ListTile(
                                        title: Text('${linea.codItem} - ${linea.descripcion}'),
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
                                    }).toList(),
                              ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            
            if (_ordenSeleccionada != null && !_isLoadingLineas)
              ElevatedButton(
                onPressed: _mostrarDialogoTipoBulto,
                child: const Text('Crear Nuevo Bulto'),
              ),

            const SizedBox(height: 20),

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
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(bulto.nombre, style: const TextStyle(fontSize: 30)),
                                selected: _bultoActual == bulto,
                                onSelected: (selected) {
                                  setState(() {
                                    _bultoActual = selected ? bulto : null;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_bultoActual != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bulto: ${_bultoActual!.nombre} (${_bultoActual!.tipo})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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
                      ..._bultoActual!.contenido.map((item) {
                        final cantidadTotal = _getCantidadVerificada(item.codigoRaiz);
                        return ListTile(
                          title: Text('${item.codigo} - ${item.descripcion}'),
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
                      }),
                    ],
                  ),
                ),
              ),

            if (_bultos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _mostrarDialogoCierreBultos,
                  child: const Text('Cerrar Bultos y Seleccionar Envío'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class Bulto {
  String nombre;
  String tipo;
  int? tipoBultoId;
  List<BultoItem> contenido;

  Bulto({
    required this.nombre,
    required this.tipo,
    this.tipoBultoId,
    required this.contenido,
  });
}

class BultoItem {
  String codigo;
  String codigoRaiz;
  int cantidad;
  String descripcion;
  int cantidadMaxima;

  BultoItem({
    required this.codigo,
    required this.codigoRaiz,
    required this.cantidad,
    required this.descripcion,
    required this.cantidadMaxima,
  });

  factory BultoItem.empty() => BultoItem(
    codigo: '',
    codigoRaiz: '',
    cantidad: 0,
    descripcion: '',
    cantidadMaxima: 0,
  );
}