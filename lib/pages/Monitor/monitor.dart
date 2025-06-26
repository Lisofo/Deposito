
// ignore_for_file: unused_field

import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/models/usuario.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/picking_services.dart';
import 'package:deposito/widgets/filtros_picking.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

class MonitorPage extends StatefulWidget {
  const MonitorPage({super.key});

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {
  final PickingServices _pickingServices = PickingServices();
  final TextEditingController _searchControllerNombre = TextEditingController();
  final TextEditingController _searchControllerNumeroDoc = TextEditingController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  late Almacen almacen = Almacen.empty();

  List<OrdenPicking> _ordenes = [];
  List<OrdenPicking> _filteredOrdenes = [];
  List<Usuario> usuarios = [];
  bool _isLoading = true;
  bool _isFilterExpanded = false;

  // Filtros
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  String? _selectedPrioridad;
  List<Map<String, String>>? _selectedTipos = [];
  Usuario? _selectedUsuarioMod;
  Usuario? _selectedUsuarioCreado;
  int _groupValue = -1;

  // Opciones para dropdowns
  final List<String> _prioridades = ['ALTA', 'NORMAL', 'BAJA', 'TODAS'];
  final List<Map<String, String>> _tipos = [
    {'value': 'C', 'label': 'Compra'},
    {'value': 'TE', 'label': 'Remito Entrada'},
    {'value': 'V', 'label': 'Venta'},
    {'value': 'TS', 'label': 'Remito Salida'},
    {'value': 'P', 'label': 'Pedido de venta'},
    {'value': '', 'label': 'Todos'},
  ];

  String token = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      token = context.read<ProductProvider>().token;
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _pickingServices.resetStatusCode();
      usuarios = await _pickingServices.getUsuarios(context, token);
      final result = await _pickingServices.getOrdenesPicking(
        context,
        almacen.almacenId,
        token,
        tipo: _selectedTipos != null && _selectedTipos!.isNotEmpty 
            ? _selectedTipos!.map((t) => t['value']!).join(',') 
            : null,
        prioridad: _selectedPrioridad != null && _selectedPrioridad != 'TODAS' 
            ? _selectedPrioridad 
            : null,
        fechaDateDesde: _fechaDesde,
        fechaDateHasta: _fechaHasta,
        estado: _groupValue != -1 ? ['PENDIENTE', 'EN PROCESO', 'CERRADO'][_groupValue] : null,
        numeroDocumento: _searchControllerNumeroDoc.text.isNotEmpty ? _searchControllerNumeroDoc.text : null,
        nombre: _searchControllerNombre.text.isNotEmpty ? _searchControllerNombre.text : null,
        usuId: _selectedUsuarioCreado?.usuarioId,
        modUsuId: _selectedUsuarioMod?.usuarioId,
      );
      
      if (result != null && _pickingServices.statusCode == 1) {
        setState(() {
          _ordenes = result;
          _filteredOrdenes = List.from(_ordenes);
        });
      }
    } finally {
      _isFilterExpanded = false;
      setState(() => _isLoading = false);
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
      _selectedTipos?.clear();
      _groupValue = -1;
      _searchControllerNombre.clear();
      _searchControllerNumeroDoc.clear();
      _selectedUsuarioCreado = null;
      _selectedUsuarioMod = null;
      _isFilterExpanded = false;
      _loadData();
    });
  }
  
  bool _hasActiveFilters() {
    return _fechaDesde != null ||
          _fechaHasta != null ||
          (_selectedPrioridad != null && _selectedPrioridad != 'TODAS') ||
          (_selectedTipos != null && _selectedTipos!.isNotEmpty) ||
          _searchControllerNombre.text.isNotEmpty ||
          _searchControllerNumeroDoc.text.isNotEmpty ||
          _selectedUsuarioCreado != null ||
          _selectedUsuarioMod != null ||
          _groupValue != -1;
  }

  @override
  Widget build(BuildContext context) {
    // final isWeb = MediaQuery.of(context).size.width > 600;
    final colors = Theme.of(context).colorScheme;
    
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
        body: Column(
          children: [
            FiltrosPicking(
              usuarios: usuarios,
              onSearch: (fechaDesde, fechaHasta, prioridad, tipos, usuarioCreado, usuarioMod) {
                setState(() {
                  _fechaDesde = fechaDesde;
                  _fechaHasta = fechaHasta;
                  _selectedPrioridad = prioridad;
                  _selectedTipos = tipos!;
                  _selectedUsuarioCreado = usuarioCreado;
                  _selectedUsuarioMod = usuarioMod;
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
              mostrarFiltroUsuarios: true,
              mostrarFiltroTipos: true,
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
                2: buildSegment('Completado'),
                -1: buildSegment('Todos'),
              },
              onValueChanged: (newValue) {
                setState(() {
                  _groupValue = newValue;
                  _loadData();
                });
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      key: _refreshIndicatorKey,
                      onRefresh: _refreshData,
                      child: _filteredOrdenes.isEmpty
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
                            )
                          : ListView.builder(
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
                                      appRouter.push('/pickingInterno');
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                              const SizedBox(width: 10),
                                              Text(
                                                'Doc: ${orden.numeroDocumento} ${orden.serie ?? ''}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                              const Spacer(),
                                              if(kIsWeb)
                                                Expanded(
                                                  flex: 10,
                                                  child: SizedBox(
                                                    width: MediaQuery.of(context).size.width * 0.8,
                                                    child: Wrap(
                                                      spacing: 16,
                                                      runSpacing: 8,
                                                      alignment: WrapAlignment.center,
                                                      children: [
                                                        _infoBox('Tipo:', _getTipoLabel(orden.tipo)),
                                                        _infoBox('Fecha:', DateFormat('dd/MM/yyyy').format(orden.fechaDate)),
                                                        _infoBox('Cliente:', '${orden.codEntidad} - ${orden.nombre}'),
                                                        _infoBox('Creado por:', orden.creadoPor),
                                                        _infoBox('RUC:', orden.ruc),
                                                        _infoBox(
                                                          'Última modificación por:',
                                                          orden.modificadoPor,
                                                        ),
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
                                          const SizedBox(height: 8),
                                          if (!kIsWeb)
                                          Wrap(
                                            spacing: 16,
                                            runSpacing: 8,
                                            children: [
                                              _infoBox('Tipo:', _getTipoLabel(orden.tipo)),
                                              _infoBox('Fecha:', DateFormat('dd/MM/yyyy').format(orden.fechaDate)),
                                              _infoBox('Cliente:', '${orden.codEntidad} - ${orden.nombre}'),
                                              _infoBox('Creado por:', orden.creadoPor),
                                              _infoBox('RUC:', orden.ruc),
                                              _infoBox(
                                                'Última modificación por:',
                                                orden.modificadoPor,
                                              ),
                                              _infoBox("Fecha última modificación:", DateFormat('dd/MM/yyyy HH:mm').format(orden.fechaDate))
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
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

  String _getTipoLabel(String tipo) {
    final tipoMap = _tipos.firstWhere(
      (item) => item['value'] == tipo,
      orElse: () => {'value': tipo, 'label': tipo},
    );
    return tipoMap['label']!;
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
}