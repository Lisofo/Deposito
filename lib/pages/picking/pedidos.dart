import 'dart:async';
import 'package:deposito/config/router/pages.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:deposito/widgets/custom_speed_dial.dart';
import 'package:deposito/widgets/escaner_pda.dart';
import 'package:deposito/widgets/filtros_picking.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/services/picking_services.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ListaPicking extends StatefulWidget {
  const ListaPicking({super.key});

  @override
  State<ListaPicking> createState() => _ListaPickingState();
}

class _ListaPickingState extends State<ListaPicking> {
  final PickingServices _pickingServices = PickingServices();
  final TextEditingController _searchControllerNombre = TextEditingController();
  final TextEditingController _searchControllerNumeroDoc = TextEditingController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  late Almacen almacen = Almacen.empty();
  FocusNode focoDeScanner = FocusNode();
  TextEditingController textController = TextEditingController();
  
  List<OrdenPicking> _ordenes = [];
  List<OrdenPicking> _filteredOrdenes = [];
  bool _isLoading = true;
  bool _isFilterExpanded = false;
  bool scanMode = false;
  bool camera = false;
  Timer? _refreshTimer;
  DateTime _ultimaActualizacion = DateTime.now();

  // Filtros
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  String? _selectedPrioridad;
  int _groupValue = 0;

  String token = '';
  late String menu;
  late List<String> menuSplitted;
  List<Map<String, String>>? _selectedTipos = [];
  final List<Map<String, String>> _tipos = [
    {'value': 'C', 'label': 'Compra'},
    {'value': 'TE', 'label': 'Remito Entrada'},
    {'value': 'V', 'label': 'Venta'},
    {'value': 'TS', 'label': 'Remito Salida'},
    {'value': 'P', 'label': 'Pedido de venta'},
    {'value': '', 'label': 'Todos'},
  ];

  @override
  void initState() {
    super.initState();
    token = context.read<ProductProvider>().token;
    menu = context.read<ProductProvider>().menu;
    camera = context.read<ProductProvider>().camera;
    almacen = context.read<ProductProvider>().almacen;
    menuSplitted = menu.split('-');
    
    if (menuSplitted.length > 1) {
      final tiposMenu = menuSplitted[1].replaceAll('/picking-', '').split(',');
      _selectedTipos = _tipos.where((tipo) => tiposMenu.contains(tipo['value'])).toList();
    }
    
    _loadData();
    _startRefreshTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _searchControllerNombre.dispose();
    _searchControllerNumeroDoc.dispose();
    focoDeScanner.dispose();
    textController.dispose();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    if (_groupValue == 0 && mounted) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (_groupValue == 0 && mounted) {
          _loadData();
        } else {
          timer.cancel();
        }
      });
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _pickingServices.resetStatusCode();
      final result = await _pickingServices.getOrdenesPicking(
        context, 
        almacen.almacenId,
        token, 
        tipo: menuSplitted[1],
        prioridad: _selectedPrioridad != 'TODAS' ? _selectedPrioridad : null,
        fechaDateDesde: _fechaDesde,
        fechaDateHasta: _fechaHasta,
        estado: _groupValue != -1 ? ['PENDIENTE', 'EN PROCESO', 'CERRADO'][_groupValue] : null,
        numeroDocumento: _searchControllerNumeroDoc.text.isNotEmpty ? _searchControllerNumeroDoc.text : null,
        nombre: _searchControllerNombre.text.isNotEmpty ? _searchControllerNombre.text : null,
        modUsuId: _groupValue == 0 ? null : context.read<ProductProvider>().uId
      );
      
      if (result != null && _pickingServices.statusCode == 1) {
        setState(() {
          _ordenes = result;
          _filteredOrdenes = List.from(_ordenes);
        });
      }
    } finally {
      setState(() {
        _ultimaActualizacion = DateTime.now();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _resetFilters() {
    setState(() {
      _fechaDesde = null;
      _fechaHasta = null;
      _selectedPrioridad = null;
      _groupValue = -1;
      _searchControllerNombre.clear();
      _searchControllerNumeroDoc.clear();
      _loadData();
    });
  }

  bool _hasActiveFilters() {
    return _fechaDesde != null ||
           _fechaHasta != null ||
           (_selectedPrioridad != null && _selectedPrioridad != 'TODAS') ||
           _searchControllerNombre.text.isNotEmpty ||
           _searchControllerNumeroDoc.text.isNotEmpty ||
           _groupValue != -1;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return VisibilityDetector(
      key: const Key('lista-picking-visibility'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.9) {
          _startRefreshTimer();
        } else {
          _refreshTimer?.cancel();
        }
      },
      child: SafeArea(
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
                onPressed: () {
                  setState(() {
                    scanMode = !scanMode;
                  });
                },
                icon: const Icon(Icons.qr_code)
              ),
              if (_hasActiveFilters())
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.filter_alt,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.filter_alt_off),
                onPressed: _resetFilters,
                tooltip: 'Resetear filtros',
              ),
            ],
          ),
          backgroundColor: Colors.grey.shade200,
          body: scanMode ? _buildScannerMode() : _buildNormalMode(colors),
          floatingActionButton: scanMode ? _buildFloatingActionButton(colors) : null,
        ),
      ),
    );
  }

  Widget _buildScannerMode() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('Escanee el código QR de alguna orden'),
        EscanerPDA(
          onScan: procesarEscaneoUbicacion,
          focusNode: focoDeScanner,
          controller: textController
        ),
      ],
    );
  }

  Widget _buildNormalMode(ColorScheme colors) {
    return Column(
      children: [
        FiltrosPicking(
          usuarios: null,
          mostrarFiltroUsuarios: false,
          mostrarFiltroTipos: true,
          tiposDisponibles: _tipos,
          selectedTiposIniciales: _selectedTipos,
          onSearch: (fechaDesde, fechaHasta, prioridad, tipos, usuarioCreado, usuarioMod) {
            setState(() {
              _selectedTipos = tipos!;
              _fechaDesde = fechaDesde;
              _fechaHasta = fechaHasta;
              _selectedPrioridad = prioridad;
            });
            _loadData();
          },
          onReset: _resetFilters,
          nombreController: _searchControllerNombre,
          numeroDocController: _searchControllerNumeroDoc,
          isFilterExpanded: _isFilterExpanded,
          onToggleFilter: (expanded) {
            setState(() {
              _isFilterExpanded = expanded;
            });
          },
          cantidadDeOrdenes: _filteredOrdenes.length,
        ),
        CupertinoSegmentedControl<int>(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          groupValue: _groupValue,
          borderColor: colors.primary,
          selectedColor: colors.primary,
          unselectedColor: Colors.white,
          children: {
            0: buildSegment('Pendiente'),
            1: buildSegment('En Proceso'),
            2: buildSegment('Cerrado'),
            -1: buildSegment('Mis ordenes'),
          },
          onValueChanged: (newValue) {
            setState(() {
              _groupValue = newValue;
              _startRefreshTimer();
              _loadData();
            });
          },
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Última actualización: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(_ultimaActualizacion)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: _refreshData,
                  child: _filteredOrdenes.isEmpty
                      ? _buildEmptyState()
                      : _buildOrderList(colors),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
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
              SizedBox(height: 8),
              Text(
                'Intenta ajustar los filtros de búsqueda',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderList(ColorScheme colors) {
    return ListView.builder(
      itemCount: _filteredOrdenes.length,
      itemBuilder: (context, index) {
        final orden = _filteredOrdenes[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          surfaceTintColor: Colors.white,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          elevation: 2,
          child: InkWell(
            onTap: () {
              Provider.of<ProductProvider>(context, listen: false).setOrdenPicking(orden);
              Provider.of<ProductProvider>(context, listen: false).setModoSeleccionUbicacion(true);
              appRouter.push('/pickingInterno');
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Doc: ${orden.numeroDocumento} ${orden.serie ?? ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
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
                  const SizedBox(height: 8),
                  Text('Tipo: ${_getTipoLabel(orden.tipo)}'),
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
      },
    );
  }

  void _resetSearch() {
    focoDeScanner.requestFocus();
    textController.clear();
    setState(() {});
  }

  Widget _buildFloatingActionButton(ColorScheme colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomSpeedDialChild(
          icon: Icons.restore,
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          label: 'Reiniciar',
          onTap: _resetSearch,
        ),
        if (camera) ...[
          CustomSpeedDialChild(
            icon: Icons.qr_code_scanner_outlined,
            label: 'Escanear',
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            onTap: _scanBarcode,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Future<void> _scanBarcode() async {
    final code = await SimpleBarcodeScanner.scanBarcode(
      context,
      lineColor: '#FFFFFF',
      cancelButtonText: 'Cancelar',
      scanType: ScanType.qr,
      isShowFlashIcon: false,
    );
    if (code == '-1') return;
    if (code != '-1') {
      try {
        final ordenObtenida = await _pickingServices.getOrdenesPicking(
          context, 
          almacen.almacenId,
          token, 
          tipo: menuSplitted[1],
          pickId: int.tryParse(code.toString())
        );
        Provider.of<ProductProvider>(context, listen: false).setOrdenPicking(ordenObtenida[0]);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const PedidoInterno())
        );
        textController.clear();
        await Future.delayed(const Duration(milliseconds: 100));
        focoDeScanner.requestFocus();
      } catch (e) {
        Carteles.showDialogs(context, 'Error al procesar el escaneo', false, false, false);
      }
    }
    
    setState(() {});
  }

  Future<void> procesarEscaneoUbicacion(String value) async {
    if (value.isEmpty) return;
    
    try {
      final ordenObtenida = await _pickingServices.getOrdenesPicking(
        context, 
        almacen.almacenId,
        token, 
        tipo: menuSplitted[1],
        pickId: int.tryParse(value)
      );
      Provider.of<ProductProvider>(context, listen: false).setOrdenPicking(ordenObtenida[0]);
      appRouter.push('/pickingInterno');
      textController.clear();
      await Future.delayed(const Duration(milliseconds: 100));
      focoDeScanner.requestFocus();
    } catch (e) {
      Carteles.showDialogs(context, 'Error al procesar el escaneo', false, false, false);
    }
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

  String _getTipoLabel(String tipo) {
    final tipoMap = _tipos.firstWhere(
      (item) => item['value'] == tipo,
      orElse: () => {'value': tipo, 'label': tipo},
    );
    return tipoMap['label']!;
  }
}