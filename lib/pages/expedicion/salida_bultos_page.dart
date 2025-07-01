import 'package:deposito/provider/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/services/picking_services.dart';

class SalidaBultosScreen extends StatefulWidget {
  const SalidaBultosScreen({super.key});

  @override
  _SalidaBultosScreenState createState() => _SalidaBultosScreenState();
}

class _SalidaBultosScreenState extends State<SalidaBultosScreen> {
  final List<Bulto> _bultos = [];
  late List<OrdenPicking> _ordenes = [];
  OrdenPicking? _ordenSeleccionada;
  List<PickingLinea> _lineasOrdenSeleccionada = [];
  Bulto? _bultoActual;
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  final PickingServices _pickingServices = PickingServices();
  bool _isLoadingLineas = false;

  // Datos para envíos
  final List<String> _empresasEnvio = ['OCA', 'Andreani', 'Correo Argentino', 'DHL'];
  final List<String> _transportistas = ['Juan Pérez', 'María Gómez', 'Carlos Rodríguez', 'Transporte Express'];

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    setState(() {
      _ordenes = productProvider.ordenesExpedicion;
      // if (_ordenes.isNotEmpty) {
      //   _ordenSeleccionada = _ordenes.first;
      //   _cargarLineasOrden(_ordenSeleccionada!);
      // }
    });
  }

  Future<void> _cargarLineasOrden(OrdenPicking orden) async {
    if (orden.lineas != null && orden.lineas!.isNotEmpty) {
      // Si ya tenemos las líneas, no hacemos la llamada
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
          // Actualizamos la orden en la lista local con las líneas obtenidas
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

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salida por Bultos'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dropdown para seleccionar orden
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
                      // onChanged: _bultos.isNotEmpty ? null : (OrdenPicking? nuevaOrden) {
                      //   if (nuevaOrden != null) {
                      //     setState(() {
                      //       _ordenSeleccionada = nuevaOrden;
                      //     });
                      //     _cargarLineasOrden(nuevaOrden);
                      //   }
                      // },
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

            // Resumen de la orden seleccionada
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
                                  children: _lineasOrdenSeleccionada.map((linea) {
                                    return ListTile(
                                      title: Text('${linea.codItem} - ${linea.descripcion}'),
                                      subtitle: Text('Pickeado: ${linea.cantidadPickeada}/${linea.cantidadPedida}'),
                                    );
                                  }).toList(),
                                ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Botón para crear nuevo bulto
            if (_ordenSeleccionada != null && !_isLoadingLineas)
              ElevatedButton(
                onPressed: _mostrarDialogoTipoBulto,
                child: const Text('Crear Nuevo Bulto'),
              ),

            const SizedBox(height: 20),

            // Lista de bultos
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
                                label: Text(bulto.nombre),
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

            // Contenido del bulto actual
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
                        controller: _codigoController,
                        decoration: const InputDecoration(
                          labelText: 'Escanear código',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.barcode_reader),
                        ),
                        onChanged: (value) {
                          productProvider.setItem(value);
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _cantidadController,
                        decoration: const InputDecoration(
                          labelText: 'Cantidad',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _agregarProductoABulto,
                        child: const Text('Agregar al Bulto'),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Contenido del bulto:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ..._bultoActual!.contenido.map((item) {
                        return ListTile(
                          title: Text(item.codigo),
                          subtitle: Text('Cantidad: ${item.cantidad}'),
                          trailing: Row(
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
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

            // Botón para cerrar bultos
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

  void _mostrarDialogoTipoBulto() {
    String? tipoSeleccionado;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar tipo de bulto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Caja'),
                value: 'Caja',
                groupValue: tipoSeleccionado,
                onChanged: (String? value) {
                  tipoSeleccionado = value;
                  Navigator.of(context).pop();
                  _crearNuevoBulto(value!);
                },
              ),
              RadioListTile<String>(
                title: const Text('Bolsa'),
                value: 'Bolsa',
                groupValue: tipoSeleccionado,
                onChanged: (String? value) {
                  tipoSeleccionado = value;
                  Navigator.of(context).pop();
                  _crearNuevoBulto(value!);
                },
              ),
              RadioListTile<String>(
                title: const Text('Retiro en mano'),
                value: 'Retiro en mano',
                groupValue: tipoSeleccionado,
                onChanged: (String? value) {
                  tipoSeleccionado = value;
                  Navigator.of(context).pop();
                  _crearNuevoBulto(value!);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _crearNuevoBulto(String tipo) {
    final nuevoBulto = Bulto(
      nombre: 'Bulto ${_bultos.length + 1}',
      tipo: tipo,
      contenido: [],
    );

    setState(() {
      _bultos.add(nuevoBulto);
      _bultoActual = nuevoBulto;
    });
  }

  void _agregarProductoABulto() {
    if (_codigoController.text.isEmpty || _cantidadController.text.isEmpty) return;

    setState(() {
      _bultoActual!.contenido.add(
        BultoItem(
          codigo: _codigoController.text,
          cantidad: int.parse(_cantidadController.text),
        ),
      );
      _codigoController.clear();
      _cantidadController.clear();
    });
  }

  void _eliminarItem(BultoItem item) {
    setState(() {
      _bultoActual!.contenido.remove(item);
    });
  }

  void _editarCantidadItem(BultoItem item) {
    final controller = TextEditingController(text: item.cantidad.toString());

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
                        items: _empresasEnvio.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
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
                        items: _transportistas.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
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
                    
                    // Aquí puedes procesar el cierre de bultos
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
                // Opcional: Navegar a otra pantalla o resetear el estado
              },
            ),
          ],
        );
      },
    );
  }  
}

class Bulto {
  String nombre;
  String tipo;
  List<BultoItem> contenido;

  Bulto({
    required this.nombre,
    required this.tipo,
    required this.contenido,
  });
}

class BultoItem {
  String codigo;
  int cantidad;

  BultoItem({
    required this.codigo,
    required this.cantidad,
  });
}