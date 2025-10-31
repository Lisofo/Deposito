// ignore_for_file: library_private_types_in_public_api

import 'package:deposito/config/router/pages.dart';
import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/entrega.dart';
import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/services/entrega_services.dart';
import 'package:deposito/services/picking_services.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:deposito/widgets/segmented_buttons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:deposito/widgets/filtros_expedicion.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'dart:async';

class SeleccionOrdenesScreen extends StatefulWidget {
  const SeleccionOrdenesScreen({super.key});

  @override
  SeleccionOrdenesScreenState createState() => SeleccionOrdenesScreenState();
}

class SeleccionOrdenesScreenState extends State<SeleccionOrdenesScreen> {
  final List<OrdenPicking> _ordenesSeleccionadas = [];
  late List<OrdenPicking> _ordenes = [];
  late Entrega entrega = Entrega.empty();
  final PickingServices _pickingServices = PickingServices();
  late Almacen almacen = Almacen.empty();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final entregaServices = EntregaServices();
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _numeroDocController = TextEditingController();
  final TextEditingController _pickIDController = TextEditingController();
  FocusNode focoDeScanner = FocusNode();
  FocusNode focoDeScanner2 = FocusNode();
  TextEditingController textController = TextEditingController();
  TextEditingController textController2 = TextEditingController();
  bool _isFilterExpanded = false;
  bool _filtroMostrador = false;
  final Map<int, int> _lineaIndexMap = {};
  late AutoScrollController _scrollController;
  Timer? _refreshTimer; // Timer para refresco automático

  bool _isLoading = true;
  bool camera = false;
  String token = '';
  int _groupValue = 0;

  @override
  void initState() {
    super.initState();
    token = context.read<ProductProvider>().token;
    camera = context.read<ProductProvider>().camera;
    almacen = context.read<ProductProvider>().almacen;
    _filtroMostrador = context.read<ProductProvider>().filtroMostrador;
    _scrollController = AutoScrollController();
    
    _loadData();
    // _iniciarTimerRefresh(); // Iniciar el timer al cargar la página
  }

  @override
  void dispose() {
    _cancelarTimerRefresh(); // Cancelar el timer al destruir la página
    _clienteController.dispose();
    _numeroDocController.dispose();
    _pickIDController.dispose();
    focoDeScanner.dispose();
    focoDeScanner2.dispose();
    textController.dispose();
    textController2.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Método para iniciar el timer de refresco
  void _iniciarTimerRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _refreshData();
      }
    });
  }

  // Método para cancelar el timer
  void _cancelarTimerRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  // Método para refrescar los datos
  Future<void> _refreshData() async {
    if (mounted && !_isLoading) {
      await _loadData();
    }
  }

  // Método para mantener el foco en el scanner
  void _mantenerFocoScanner() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // focoDeScanner.requestFocus();
      }
    });
  }

  Future<void> _loadData({DateTime? fechaDesde, DateTime? fechaHasta, String? cliente, String? numeroDocumento, String? pickId}) async {
    setState(() => _isLoading = true);
    try {
      await _pickingServices.resetStatusCode();
      
      // 1. Obtener todas las órdenes primero
      final result = await _pickingServices.getOrdenesPicking(
        context, 
        almacen.almacenId,
        token, 
        tipo: 'V,P,TS',
        estado: _groupValue != -1 ? ['PREPARADO, PAPEL', 'EMBALAJE', 'E. PARCIAL, PAPEL'][_groupValue] : null,
        fechaDateDesde: fechaDesde,
        fechaDateHasta: fechaHasta,
        nombre: cliente,
        numeroDocumento: numeroDocumento,
        pickId: int.tryParse(pickId.toString()),
        envio: !_filtroMostrador,
      );

      // 2. Aplicar filtro de mostrador si está activo
      List<OrdenPicking> ordenesFiltradas = result ?? [];
      if (_filtroMostrador) {
        ordenesFiltradas = ordenesFiltradas.where((orden) => orden.envio == false).toList();
      }

      // 3. Obtener entregas en proceso para el usuario actual
      var entregas = await EntregaServices().getEntregas(
        context, 
        token, 
        estado: 'EN PROCESO, VERIFICADO',
        usuId: context.read<ProductProvider>().uId
      );

      if (result != null && _pickingServices.statusCode == 1) {
        setState(() {
          _ordenes = ordenesFiltradas; // Usar las órdenes filtradas
          _ordenesSeleccionadas.clear(); // Limpiar selecciones anteriores
          
          // 4. Llenar el mapa de índices
          _lineaIndexMap.clear();
          for (int i = 0; i < _ordenes.length; i++) {
            _lineaIndexMap[_ordenes[i].pickId] = i;
          }
          
          // 5. Verificar si hay entregas y tomar la primera (posición 0)
          if (entregas.isNotEmpty) {
            final entrega = entregas[0]; // Tomamos la primera entrega
            
            // Buscar órdenes que coincidan con los pickIds de esta entrega
            for (var orden in _ordenes) {
              if (entrega.pickIds.contains(orden.pickId)) {
                _ordenesSeleccionadas.add(orden);
              }
            }
            
            // También guardamos la entrega para usarla luego si es necesario
            this.entrega = entrega;
          }
        });
      }
    } finally {
      setState(() => _isLoading = false);
      // _manteneFocoScanner();
    }
  }

  void _onFiltroMostradorChanged(bool value) {
    setState(() {
      _filtroMostrador = value;
    });
    
    // Guardar el estado en el provider para persistencia
    context.read<ProductProvider>().setFiltroMostrador(value);
    
    // Recargar datos con el nuevo filtro
    _loadData();
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
    return SafeArea(
      child: Scaffold(
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
                  // Fila que contiene FiltrosExpedicion + Mostrador/Switch
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // FiltrosExpedicion expandido
                        Expanded(
                          child: FiltrosExpedicion(
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
                              _mantenerFocoScanner();
                            },
                            cantidadDeOrdenes: _ordenes.length,
                          ),
                        ),
                        
                        // Separador visual
                        Container(
                          width: 1,
                          height: 30,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          color: Colors.grey[300],
                        ),
                        
                        // Switch de Mostrador
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _filtroMostrador ? 'Mostrador' : 'Envío',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: _filtroMostrador,
                              onChanged: _onFiltroMostradorChanged,
                              activeColor: colors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  CustomSegmentedControl(
                    groupValue: _groupValue,
                    onValueChanged: (newValue) {
                      setState(() {
                        _groupValue = newValue;
                        _loadData();
                      });
                    },
                    options: SegmentedOptions.expedicionStates,
                    usePickingStyle: true,
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
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: TextFormField(
                              focusNode: focoDeScanner,
                              controller: textController,
                              decoration: const InputDecoration(
                                labelText: 'Escanear orden',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.barcode_reader),
                              ),
                              onFieldSubmitted: (value) => procesarEscaneoUbicacion(value, false),
                              autofocus: false,
                            ),
                          ),
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
                                controller: textController2,
                                onFieldSubmitted: (value) => procesarEscaneoUbicacion(value, true),
                              ),
                            )
                          ),
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: _ordenes.length,
                              itemBuilder: (context, index) {
                                final orden = _ordenes[index];
                                return _buildOrdenItem(orden, index);
                              },
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
                            await siguiente(context, productProvider);
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
      ),
    );
  }

  Future<void> siguiente(BuildContext context, ProductProvider productProvider) async {
    int? statusCode;
    List<int> pickIds = _ordenesSeleccionadas.map((orden) => orden.pickId).toList();
    if (entrega.estado == 'VERIFICADO') {
      Provider.of<ProductProvider>(context, listen: false).setVistaMonitor(false);
      productProvider.setOrdenesExpedicion(_ordenesSeleccionadas);
      productProvider.setEntrega(entrega);
      appRouter.push('/salidaBultos');
    } else {
      entrega = await entregaServices.postEntrega(context, pickIds, almacen.almacenId, token);
      statusCode = await entregaServices.getStatusCode();
      await entregaServices.resetStatusCode();
      if(statusCode == 1) {
        Provider.of<ProductProvider>(context, listen: false).setVistaMonitor(false);
        productProvider.setOrdenesExpedicion(_ordenesSeleccionadas);
        productProvider.setEntrega(entrega);
        appRouter.push('/salidaBultos');
      }
    }
    
  }

  Widget _buildOrdenItem(OrdenPicking orden, int index) {
    final isSelected = _ordenesSeleccionadas.contains(orden);
    final colors = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 800;

    return AutoScrollTag(
      key: ValueKey(orden.pickId),
      controller: _scrollController,
      index: index,
      child: Card(
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
            _mantenerFocoScanner();
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
                        _mantenerFocoScanner();
                      },
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            value: orden.porcentajeCompletado / 100,
                            strokeWidth: 5,
                            backgroundColor: Colors.grey[400],
                            color: orden.porcentajeCompletado == 100.0 ? Colors.green : colors.secondary,
                          ),
                        ),
                        Text(
                          '${orden.porcentajeCompletado.toStringAsFixed(orden.porcentajeCompletado % 1 == 0 ? 0 : 0)}%',
                          style: const TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold
                          ),
                        )
                      ],
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Doc: ${orden.numeroDocumento} ${orden.serie ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    if(!isMobile)
                      Expanded(
                        flex: 10,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _infoBox('Tipo:', orden.descTipo),
                              _infoBox('Fecha:', DateFormat('dd/MM/yyyy').format(orden.fechaDate)),
                              _infoBox('Cliente:', '${orden.codEntidad} - ${orden.nombre}'),
                              _infoBox('Creado por:', orden.creadoPor),
                              if (orden.formaIdEnvio != 0)
                                _infoBox('Agencia:', orden.agencia),
                              _infoBox(
                                'Última modificación por:',
                                orden.modificadoPor,
                              ),
                              if (orden.comentarioEnvio != '')
                                _infoBox('Comentario:', orden.comentarioEnvio),
                              _infoBox("Fecha última modificación:", DateFormat('dd/MM/yyyy HH:mm').format(orden.fechaDate))
                            ],
                          ),
                        ),
                      ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(orden.estado),
                            borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          orden.estado,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(orden.prioridad),
                      Text('PickId: ${orden.pickId}'),
                      Text('Líneas: ${orden.cantLineas ?? 0}'),
                    ],
                  ),
                ],
                ),
                if(isMobile)
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _infoBox('Tipo:', orden.descTipo),
                      _infoBox('Fecha:', DateFormat('dd/MM/yyyy').format(orden.fechaDate)),
                      _infoBox('Cliente:', '${orden.codEntidad} - ${orden.nombre}'),
                      _infoBox('Creado por:', orden.creadoPor),
                      if (orden.formaIdEnvio != 0)
                        _infoBox('Agencia:', orden.agencia),
                      _infoBox(
                        'Última modificación por:',
                        orden.modificadoPor,
                      ),
                      if (orden.comentarioEnvio != '')
                        _infoBox('Comentario:', orden.comentarioEnvio),
                      _infoBox("Fecha última modificación:", DateFormat('dd/MM/yyyy HH:mm').format(orden.fechaDate))
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoBox(String label, String value) {
    return SizedBox(
      width: 360, // ajustá este valor para lograr alineación visual entre columnas
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 14),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget buildSegment(String text) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(
          text,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'E. PARCIAL':
        return Colors.orange;
      case 'EMBALAJE':
        return Colors.blue;
      case 'PREPARADO':
      case 'PAPEL':
        return Colors.green;
      case 'CANCELADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> procesarEscaneoUbicacion(String value, bool invisible) async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    if (value.isEmpty && _ordenesSeleccionadas.isNotEmpty) {
      await siguiente(context, productProvider);
    }
    if (value.isEmpty) return;
    
    try {
      var ordenEncontrada = _ordenes.firstWhere((orden) => (orden.numeroDocumento == int.parse(value) || orden.pickId == int.parse(value)));
      
      // Verificar si la orden ya está seleccionada para evitar duplicados
      if (!_ordenesSeleccionadas.contains(ordenEncontrada)) {
        _ordenesSeleccionadas.add(ordenEncontrada);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollHaciaOrdenPorId(ordenEncontrada.pickId);
      });
      
      if(invisible) {
        textController2.clear();
        focoDeScanner2.requestFocus();
      } else {
        textController.clear();
        focoDeScanner.requestFocus();
      }
      setState(() {});
    } catch (e) {
      Carteles.showDialogs(context, 'Error al procesar el escaneo', false, false, false);
      // Mantener foco incluso después de un error
      _mantenerFocoScanner();
    }
  }

  void _scrollHaciaOrdenPorId(int pickId) {
    if (_lineaIndexMap.containsKey(pickId)) {
      final index = _lineaIndexMap[pickId]!;
      _scrollController.scrollToIndex(
        index,
        duration: const Duration(milliseconds: 700),
        preferPosition: AutoScrollPosition.begin,
      );
    }
  }
}