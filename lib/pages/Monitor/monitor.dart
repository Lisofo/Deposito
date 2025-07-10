// ignore_for_file: unused_field

import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/bulto.dart';
import 'package:deposito/models/modo_envio.dart';
import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/models/tipo_bulto.dart';
import 'package:deposito/models/usuario.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/entrega_services.dart';
import 'package:deposito/services/picking_services.dart';
import 'package:deposito/widgets/filtros_bulto.dart';
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

class _MonitorPageState extends State<MonitorPage> with SingleTickerProviderStateMixin {
  final PickingServices _pickingServices = PickingServices();
  final EntregaServices _entregaServices = EntregaServices();
  final TextEditingController _searchControllerNombre = TextEditingController();
  final TextEditingController _searchControllerNumeroDoc = TextEditingController();
  final TextEditingController _searchControllerClienteBulto = TextEditingController();
  final TextEditingController _searchControllerBultoId = TextEditingController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  late Almacen almacen = Almacen.empty();

  // Datos para órdenes
  List<OrdenPicking> _ordenes = [];
  List<OrdenPicking> _filteredOrdenes = [];
  
  // Datos para bultos
  List<Bulto> _bultos = [];
  List<Bulto> _filteredBultos = [];
  
  // Datos para filtros
  List<Usuario> usuarios = [];
  List<Almacen> almacenes = [];
  List<ModoEnvio> modosEnvio = [];
  List<TipoBulto> tiposBulto = [];
  
  bool _isLoading = true;
  bool _isFilterExpanded = false;
  late TabController _tabController;

  // Filtros para órdenes
  DateTime? _fechaDesdeOrdenes;
  DateTime? _fechaHastaOrdenes;
  String? _selectedPrioridad;
  List<Map<String, String>>? _selectedTipos = [];
  Usuario? _selectedUsuarioMod;
  Usuario? _selectedUsuarioCreado;
  int _groupValueOrdenes = 0; // 0 = Todos, 1 = Pendiente, 2 = En Proceso, 3 = CERRADO

  // Filtros para bultos
  DateTime? _fechaDesdeBultos;
  DateTime? _fechaHastaBultos;
  int _groupValueBultos = 0; // 0 = Todos, 1 = Pendiente, 2 = Cerrado, 3 = Despachado
  int? _selectedModoEnvioId;
  int? _selectedTipoBultoId;
  Usuario? _selectedUsuarioArmado;

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
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      token = context.read<ProductProvider>().token;
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchControllerNombre.dispose();
    _searchControllerNumeroDoc.dispose();
    _searchControllerClienteBulto.dispose();
    _searchControllerBultoId.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _pickingServices.resetStatusCode();
      await _entregaServices.resetStatusCode();
      
      // Cargar datos comunes
      usuarios = await _pickingServices.getUsuarios(context, token);
      
      // Cargar datos específicos según la pestaña activa
      if (_tabController.index == 0 || _ordenes.isEmpty) {
        // Cargar órdenes
        final resultOrdenes = await _pickingServices.getOrdenesPicking(
          context,
          almacen.almacenId,
          token,
          tipo: _selectedTipos != null && _selectedTipos!.isNotEmpty 
              ? _selectedTipos!.map((t) => t['value']!).join(',') 
              : null,
          prioridad: _selectedPrioridad != null && _selectedPrioridad != 'TODAS' 
              ? _selectedPrioridad 
              : null,
          fechaDateDesde: _fechaDesdeOrdenes,
          fechaDateHasta: _fechaHastaOrdenes,
          estado: _groupValueOrdenes != 0 
              ? ['PENDIENTE', 'EN PROCESO', 'CERRADO'][_groupValueOrdenes - 1] 
              : null,
          numeroDocumento: _searchControllerNumeroDoc.text.isNotEmpty ? _searchControllerNumeroDoc.text : null,
          nombre: _searchControllerNombre.text.isNotEmpty ? _searchControllerNombre.text : null,
          usuId: _selectedUsuarioCreado?.usuarioId,
          modUsuId: _selectedUsuarioMod?.usuarioId,
        );
        
        if (resultOrdenes != null && _pickingServices.statusCode == 1) {
          setState(() {
            _ordenes = resultOrdenes;
            _filteredOrdenes = List.from(_ordenes);
          });
        }
      }
      
      if (_tabController.index == 1 || _bultos.isEmpty) {
        // Cargar datos específicos de bultos
        
        modosEnvio = await _entregaServices.modoEnvio(context, token);
        tiposBulto = await _entregaServices.tipoBulto(context, token);
        
        // Cargar bultos
        final resultBultos = await _entregaServices.getBultos(
          context,
          token,
          estado: _groupValueBultos != 0 
              ? ['PENDIENTE', 'CERRADO', 'DESPACHADO'][_groupValueBultos - 1] 
              : null,
          fechaDateDesde: _fechaDesdeBultos != null ? DateFormat('yyyy-MM-dd').format(_fechaDesdeBultos!) : null,
          fechaDateHasta: _fechaHastaBultos != null ? DateFormat('yyyy-MM-dd').format(_fechaHastaBultos!) : null,
          nombreCliente: _searchControllerClienteBulto.text.isNotEmpty ? _searchControllerClienteBulto.text : null,
          bultoId: _searchControllerBultoId.text.isNotEmpty ? int.tryParse(_searchControllerBultoId.text) : null,
          armadoPorUsuId: _selectedUsuarioArmado?.usuarioId,
          modoEnvioId: _selectedModoEnvioId,
          tipoBultoId: _selectedTipoBultoId,
        );
        
        if (resultBultos != [] && _entregaServices.statusCode == 1) {
          setState(() {
            _bultos = resultBultos;
            _filteredBultos = List.from(_bultos);
          });
        }
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
      if (_tabController.index == 0) {
        // Reset filtros de órdenes
        _fechaDesdeOrdenes = null;
        _fechaHastaOrdenes = null;
        _selectedPrioridad = null;
        _selectedTipos?.clear();
        _groupValueOrdenes = 0;
        _searchControllerNombre.clear();
        _searchControllerNumeroDoc.clear();
        _selectedUsuarioCreado = null;
        _selectedUsuarioMod = null;
      } else {
        // Reset filtros de bultos
        _fechaDesdeBultos = null;
        _fechaHastaBultos = null;
        _groupValueBultos = 0;
        _selectedModoEnvioId = null;
        _selectedTipoBultoId = null;
        _selectedUsuarioArmado = null;
        _searchControllerClienteBulto.clear();
        _searchControllerBultoId.clear();
      }
      _isFilterExpanded = false;
      _loadData();
    });
  }
  
  bool _hasActiveFilters() {
    if (_tabController.index == 0) {
      return _fechaDesdeOrdenes != null ||
            _fechaHastaOrdenes != null ||
            (_selectedPrioridad != null && _selectedPrioridad != 'TODAS') ||
            (_selectedTipos != null && _selectedTipos!.isNotEmpty) ||
            _searchControllerNombre.text.isNotEmpty ||
            _searchControllerNumeroDoc.text.isNotEmpty ||
            _selectedUsuarioCreado != null ||
            _selectedUsuarioMod != null ||
            _groupValueOrdenes != 0;
    } else {
      return _fechaDesdeBultos != null ||
            _fechaHastaBultos != null ||
            _searchControllerClienteBulto.text.isNotEmpty ||
            _searchControllerBultoId.text.isNotEmpty ||
            _selectedUsuarioArmado != null ||
            _selectedModoEnvioId != null ||
            _selectedTipoBultoId != null ||
            _groupValueBultos != 0;
    }
  }

  Widget _buildOrdenesTab() {
    return Column(
      children: [
        CupertinoSegmentedControl<int>(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          groupValue: _groupValueOrdenes,
          borderColor: Theme.of(context).colorScheme.primary,
          selectedColor: Theme.of(context).colorScheme.primary,
          unselectedColor: Colors.white,
          children: const {
            0: Text('Todos'),
            1: Text('Pendiente'),
            2: Text('En Proceso'),
            3: Text('Completado'),
          },
          onValueChanged: (newValue) {
            setState(() {
              _groupValueOrdenes = newValue;
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
                      ? _buildEmptyState('No se encontraron órdenes')
                      : ListView.builder(
                          itemCount: _filteredOrdenes.length,
                          itemBuilder: (context, index) {
                            final orden = _filteredOrdenes[index];
                            return _buildOrdenCard(orden);
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildBultosTab() {
    return Column(
      children: [
        CupertinoSegmentedControl<int>(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          groupValue: _groupValueBultos,
          borderColor: Theme.of(context).colorScheme.primary,
          selectedColor: Theme.of(context).colorScheme.primary,
          unselectedColor: Colors.white,
          children: const {
            0: Text('Todos'),
            1: Text('Pendiente'),
            2: Text('Cerrado'),
            3: Text('Despachado'),
          },
          onValueChanged: (newValue) {
            setState(() {
              _groupValueBultos = newValue;
              _loadData();
            });
          },
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  child: _filteredBultos.isEmpty
                      ? _buildEmptyState('No se encontraron bultos')
                      : ListView.builder(
                          itemCount: _filteredBultos.length,
                          itemBuilder: (context, index) {
                            final bulto = _filteredBultos[index];
                            return _buildBultoCard(bulto);
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(
          child: Column(
            children: [
              const Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
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

  Widget _buildOrdenCard(OrdenPicking orden) {
    final colors = Theme.of(context).colorScheme;
    
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
  }

  Widget _buildBultoCard(Bulto bulto) {
    // final colors = Theme.of(context).colorScheme;
    
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
          // Provider.of<ProductProvider>(context, listen: false).setBulto(bulto);
          // appRouter.push('/detalleBulto');
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bulto #${bulto.bultoId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Entrega #${bulto.entregaId}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
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
                            _infoBox('Cliente:', bulto.nombreCliente ?? 'N/A'),
                            _infoBox('Fecha:', DateFormat('dd/MM/yyyy').format(bulto.fechaDate)),
                            if (bulto.tipoBultoId != 0) 
                              _infoBox('Tipo Bulto:', '${bulto.tipoBultoId}'),
                            _infoBox('Armado por:', 'Usuario ${bulto.armadoPorUsuId}'),
                            _infoBox('Estado:', bulto.estado),
                            if (bulto.modoEnvioId != null)
                              _infoBox('Modo Envío:', '${bulto.modoEnvioId}'),
                            if (bulto.almacenId != 0)
                              _infoBox('Almacén:', '${bulto.almacenId}'),
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
                          color: _getBultoStatusColor(bulto.estado),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          bulto.estado,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (bulto.retiroId != null) 
                        Text('Retiro #${bulto.retiroId}'),
                      Text('Items: ${bulto.contenido.length}'),
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
                  _infoBox('Cliente:', bulto.nombreCliente ?? 'N/A'),
                  _infoBox('Fecha:', DateFormat('dd/MM/yyyy').format(bulto.fechaDate)),
                  if (bulto.tipoBultoId != 0)
                    _infoBox('Tipo Bulto:', '${bulto.tipoBultoId}'),
                  _infoBox('Armado por:', 'Usuario ${bulto.armadoPorUsuId}'),
                  _infoBox('Estado:', bulto.estado),
                  if (bulto.modoEnvioId != null)
                    _infoBox('Modo Envío:', '${bulto.modoEnvioId}'),
                  if (bulto.almacenId != 0)
                    _infoBox('Almacén:', '${bulto.almacenId}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    if (_tabController.index == 0) {
      return FiltrosPicking(
        usuarios: usuarios,
        onSearch: (fechaDesde, fechaHasta, prioridad, tipos, usuarioCreado, usuarioMod) {
          setState(() {
            _fechaDesdeOrdenes = fechaDesde;
            _fechaHastaOrdenes = fechaHasta;
            _selectedPrioridad = prioridad;
            _selectedTipos = tipos;
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
        tiposDisponibles: _tipos,
      );
    } else {
      return FiltrosBulto(
        usuarios: usuarios,
        modosEnvio: modosEnvio,
        tiposBulto: tiposBulto,
        onSearch: (fechaDesde, fechaHasta, modoEnvioId, tipoBultoId, usuarioArmado, nombreCliente, bultoId) {
          setState(() {
            _fechaDesdeBultos = fechaDesde;
            _fechaHastaBultos = fechaHasta;
            _selectedModoEnvioId = modoEnvioId;
            _selectedTipoBultoId = tipoBultoId;
            _selectedUsuarioArmado = usuarioArmado;
            if (nombreCliente != null) _searchControllerClienteBulto.text = nombreCliente;
            if (bultoId != null) _searchControllerBultoId.text = bultoId;
          });
          _loadData();
        },
        onReset: _resetFilters,
        nombreClienteController: _searchControllerClienteBulto,
        bultoIdController: _searchControllerBultoId,
        isFilterExpanded: _isFilterExpanded,
        onToggleFilter: (expanded) {
          setState(() {
            _isFilterExpanded = expanded;
          });
        },
        cantidadDeBultos: _filteredBultos.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          bottom: TabBar(
            controller: _tabController,
            onTap: (index) {
              setState(() {});
              _loadData();
            },
            labelColor: colors.onPrimary,
            unselectedLabelColor: colors.onPrimary.withValues(alpha: 0.7),
            indicatorColor: colors.onPrimary,
            tabs: [
              Tab(
                text: 'Órdenes',
                icon: Icon(Icons.list_alt, color: colors.onPrimary),
              ),
              Tab(
                text: 'Bultos',
                icon: Icon(Icons.inventory_2, color: colors.onPrimary),
              ),
            ],
          ),
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
            _buildFiltros(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrdenesTab(),
                  _buildBultosTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(String label, String value) {
    return SizedBox(
      width: 360,
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

  Color _getBultoStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'CERRADO':
        return Colors.green;
      case 'DESPACHADO':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}