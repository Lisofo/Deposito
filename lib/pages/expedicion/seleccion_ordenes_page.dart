// ignore_for_file: library_private_types_in_public_api

import 'package:deposito/config/router/pages.dart';
import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/entrega.dart';
import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/services/entrega_services.dart';
import 'package:deposito/services/picking_services.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:deposito/widgets/filtros_expedicion.dart';
import 'package:visibility_detector/visibility_detector.dart';

class SeleccionOrdenesScreen extends StatefulWidget {
  const SeleccionOrdenesScreen({super.key});

  @override
  SeleccionOrdenesScreenState createState() => SeleccionOrdenesScreenState();
}

class SeleccionOrdenesScreenState extends State<SeleccionOrdenesScreen> {
  final List<OrdenPicking> _ordenesSeleccionadas = [];
  late List<OrdenPicking> _ordenes = [];
  final PickingServices _pickingServices = PickingServices();
  late Almacen almacen = Almacen.empty();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final entregaServices = EntregaServices();
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _numeroDocController = TextEditingController();
  final TextEditingController _pickIDController = TextEditingController();
  FocusNode focoDeScanner = FocusNode();
  TextEditingController textController = TextEditingController();
  bool _isFilterExpanded = false;

  bool _isLoading = true;
  bool camera = false;
  String token = '';

  @override
  void initState() {
    super.initState();
    token = context.read<ProductProvider>().token;
    camera = context.read<ProductProvider>().camera;
    almacen = context.read<ProductProvider>().almacen;
    
    _loadData();
  }

  // Método para mantener el foco en el scanner
  void _manteneFocoScanner() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        focoDeScanner.requestFocus();
      }
    });
  }

  Future<void> _loadData({DateTime? fechaDesde, DateTime? fechaHasta, String? cliente, String? numeroDocumento, String? pickId}) async {
    setState(() => _isLoading = true);
    try {
      await _pickingServices.resetStatusCode();
      final result = await _pickingServices.getOrdenesPicking(
        context, 
        almacen.almacenId,
        token, 
        tipo: 'V,P,TS',
        estado: 'CERRADO',
        fechaDateDesde: fechaDesde,
        fechaDateHasta: fechaHasta,
        nombre: cliente,
        numeroDocumento: numeroDocumento,
        pickId: int.tryParse(pickId.toString())
      );
      
      if (result != null && _pickingServices.statusCode == 1) {
        setState(() {
          _ordenes = result;          
        });
      }
    } finally {
      setState(() => _isLoading = false);
      // Mantener foco después de cargar datos
      _manteneFocoScanner();
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _limpiarFiltros() {
    setState(() {
      _clienteController.clear();
      _numeroDocController.clear();
      _pickIDController.clear();
      _isFilterExpanded = false;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        title: Text(
          context.read<ProductProvider>().menuTitle,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: colors.onPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_off),
            tooltip: 'Limpiar filtros',
            onPressed: _limpiarFiltros,
          ),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _refreshData,
            child: Column(
              children: [
                FiltrosExpedicion(
                  onSearch: (fechaDesde, fechaHasta, cliente, numeroDocumento, pickId) {
                    _loadData(
                      fechaDesde: fechaDesde,
                      fechaHasta: fechaHasta,
                      cliente: cliente,
                      numeroDocumento: numeroDocumento,
                      pickId: pickId
                    );
                  },
                  onReset: _limpiarFiltros,
                  clienteController: _clienteController,
                  numeroDocController: _numeroDocController,
                  pickIDController: _pickIDController,
                  isFilterExpanded: _isFilterExpanded,
                  onToggleFilter: (expanded) {
                    setState(() {
                      _isFilterExpanded = expanded;
                    });
                    // Mantener foco cuando se expande/colapsa el filtro
                    _manteneFocoScanner();
                  },
                  cantidadDeOrdenes: _ordenes.length,
                ),
                Expanded(
                  child: _ordenes.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                          const Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No se encontraron órdenes',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ), 
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: _ordenes.length,
                            itemBuilder: (context, index) {
                              final orden = _ordenes[index];
                              return _buildOrdenItem(orden);
                            },
                          ),
                        ),
                        VisibilityDetector(
                          key: const Key('scanner-field-visibility'),
                          onVisibilityChanged: (info) {
                            if (info.visibleFraction > 0) {
                              focoDeScanner.requestFocus();
                            }
                          },
                          child: TextFormField(
                            focusNode: focoDeScanner,
                            cursorColor: Colors.transparent,
                            decoration: const InputDecoration(
                              border: UnderlineInputBorder(borderSide: BorderSide.none),
                            ),
                            style: const TextStyle(color: Colors.transparent),
                            autofocus: true,
                            keyboardType: TextInputType.none,
                            controller: textController,
                            onFieldSubmitted: procesarEscaneoUbicacion,
                          ),
                        ),
                      ],
                    ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: _ordenesSeleccionadas.isNotEmpty
                      ? () async {
                          Entrega entrega = Entrega.empty();
                          int? statusCode;
                          List<int> pickIds = _ordenesSeleccionadas.map((orden) => orden.pickId).toList();
                          await entregaServices.postEntrega(context, pickIds, token);
                          statusCode = await entregaServices.getStatusCode();
                          await entregaServices.resetStatusCode();
                          if(statusCode == 1) {
                            productProvider.setOrdenesExpedicion(_ordenesSeleccionadas);
                            productProvider.setEntrega(entrega);
                            appRouter.push('/salidaBultos');
                          }
                        }
                      : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text(
                      'Siguiente',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
        )
    );
  }

  Widget _buildOrdenItem(OrdenPicking orden) {
    final isSelected = _ordenesSeleccionadas.contains(orden);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _ordenesSeleccionadas.remove(orden);
            } else {
              _ordenesSeleccionadas.add(orden);
            }
          });
          // Mantener foco después de selección manual
          _manteneFocoScanner();
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _ordenesSeleccionadas.add(orden);
                        } else {
                          _ordenesSeleccionadas.remove(orden);
                        }
                      });
                      // Mantener foco después de cambio en checkbox
                      _manteneFocoScanner();
                    },
                  ),
                  Expanded(
                    child: Text(
                      '${orden.serie}-${orden.numeroDocumento}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Chip(
                        label: Text(
                          '${orden.porcentajeCompletado.toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: orden.porcentajeCompletado == 100 ? Colors.green : Colors.orange,
                      ),
                      Text('PickId: ${orden.pickId}'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Cliente: ${orden.nombre}'),
              const SizedBox(height: 8),
              Text('Tipo: ${orden.descTipo}'),
              Text('Cliente: ${orden.codEntidad} - ${orden.nombre}'),
              Text('RUC: ${orden.ruc}'),
              Text(orden.transaccion),
              Text('Fecha: ${DateFormat('dd/MM/yyyy').format(orden.fechaDate)}'),
              Text("Fecha última mod.: ${DateFormat('dd/MM/yyyy HH:mm').format(orden.fechaDate)}"),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> procesarEscaneoUbicacion(String value) async {
    if (value.isEmpty) return;
    
    try {
      var ordenEncontrada = _ordenes.firstWhere((orden) => (orden.numeroDocumento == int.parse(value) || orden.pickId == int.parse(value)));
      
      // Verificar si la orden ya está seleccionada para evitar duplicados
      if (!_ordenesSeleccionadas.contains(ordenEncontrada)) {
        _ordenesSeleccionadas.add(ordenEncontrada);
      }
      
      textController.clear();
      focoDeScanner.requestFocus();
      setState(() {});
    } catch (e) {
      Carteles.showDialogs(context, 'Error al procesar el escaneo', false, false, false);
      // Mantener foco incluso después de un error
      _manteneFocoScanner();
    }
  }
}