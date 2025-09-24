// ignore_for_file: unused_field

import 'dart:async';
import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/bulto.dart';
import 'package:deposito/models/entrega.dart';
import 'package:deposito/models/modo_envio.dart';
import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/models/tipo_bulto.dart';
import 'package:deposito/models/usuario.dart';
import 'package:deposito/models/retiro.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/entrega_services.dart';
import 'package:deposito/services/picking_services.dart';
import 'package:deposito/widgets/filtros_bulto.dart';
import 'package:deposito/widgets/filtros_entregas.dart';
import 'package:deposito/widgets/filtros_picking.dart';
import 'package:deposito/widgets/segmented_buttons.dart';
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
  Timer? _refreshTimer;
  DateTime _ultimaActualizacion = DateTime.now();

  // Datos para órdenes
  List<OrdenPicking> _ordenes = [];
  List<OrdenPicking> _filteredOrdenes = [];
  
  // Datos para entregas
  List<Entrega> _entregas = [];
  List<Entrega> _filteredEntregas = [];
  
  // Datos para bultos
  List<Bulto> _bultos = [];
  List<Bulto> _filteredBultos = [];
  
  // Datos para retiros
  List<Retiro> _retiros = [];
  List<Retiro> _filteredRetiros = [];
  
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
  int _groupValueOrdenes = 0;

  // Filtros para entregas
  DateTime? _fechaDesdeEntregas;
  DateTime? _fechaHastaEntregas;
  int _groupValueEntregas = 0;
  Usuario? _selectedUsuarioEntrega;

  // Filtros para bultos
  DateTime? _fechaDesdeBultos;
  DateTime? _fechaHastaBultos;
  int _groupValueBultos = 0;
  int? _selectedModoEnvioId;
  int? _selectedTipoBultoId;
  Usuario? _selectedUsuarioArmado;

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
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      token = context.read<ProductProvider>().token;
      _loadData();
      _startRefreshTimer();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchControllerNombre.dispose();
    _searchControllerNumeroDoc.dispose();
    _searchControllerClienteBulto.dispose();
    _searchControllerBultoId.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      _startRefreshTimer();
      _loadData();
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _pickingServices.resetStatusCode();
      await _entregaServices.resetStatusCode();
      
      // Cargar datos comunes
      usuarios = await _pickingServices.getUsuarios(context, token);
      
      // Cargar datos según la pestaña activa
      switch (_tabController.index) {
        case 0:
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
                ? ['PENDIENTE', 'EN PROCESO', 'PREPARADO'][_groupValueOrdenes - 1] 
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
              _ultimaActualizacion = DateTime.now();
            });
          }
          break;
        
        case 1:
          final resultEntregas = await _entregaServices.getEntregas(
            context,
            token,
            usuId: _selectedUsuarioEntrega?.usuarioId,
            estado: _groupValueEntregas != 0 
                ? ['PENDIENTE', 'EN PROCESO', 'FINALIZADO'][_groupValueEntregas - 1] 
                : null,
            fechaDateDesde: _fechaDesdeEntregas,
            fechaDateHasta: _fechaHastaEntregas
          );
          
          if (resultEntregas != [] && _entregaServices.statusCode == 1) {
            setState(() {
              _entregas = resultEntregas;
              _filteredEntregas = List.from(_entregas);
              _ultimaActualizacion = DateTime.now();
            });
          }
          break;
        
        case 2:
          modosEnvio = await _entregaServices.modoEnvio(context, token);
          tiposBulto = await _entregaServices.tipoBulto(context, token);
          
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
              _ultimaActualizacion = DateTime.now();
            });
          }
          break;
        
        case 3:
          final resultRetiros = await _entregaServices.getRetiros(context, token);
          
          if (resultRetiros != [] && _entregaServices.statusCode == 1) {
            setState(() {
              _retiros = resultRetiros;
              _filteredRetiros = List.from(_retiros);
              _ultimaActualizacion = DateTime.now();
            });
          }
          break;
      }
    } finally {
      setState(() {
        _isFilterExpanded = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _resetFilters() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _fechaDesdeOrdenes = null;
          _fechaHastaOrdenes = null;
          _selectedPrioridad = null;
          _selectedTipos?.clear();
          _groupValueOrdenes = 0;
          _searchControllerNombre.clear();
          _searchControllerNumeroDoc.clear();
          _selectedUsuarioCreado = null;
          _selectedUsuarioMod = null;
          break;
        case 1:
          _fechaDesdeEntregas = null;
          _fechaHastaEntregas = null;
          _groupValueEntregas = 0;
          _selectedUsuarioEntrega = null;
          break;
        case 2:
          _fechaDesdeBultos = null;
          _fechaHastaBultos = null;
          _groupValueBultos = 0;
          _selectedModoEnvioId = null;
          _selectedTipoBultoId = null;
          _selectedUsuarioArmado = null;
          _searchControllerClienteBulto.clear();
          _searchControllerBultoId.clear();
          break;
        case 3:
          // No hay filtros para retiros
          break;
      }
      _isFilterExpanded = false;
    });
    _loadData();
  }
  
  bool _hasActiveFilters() {
    switch (_tabController.index) {
      case 0:
        return _fechaDesdeOrdenes != null ||
              _fechaHastaOrdenes != null ||
              (_selectedPrioridad != null && _selectedPrioridad != 'TODAS') ||
              (_selectedTipos != null && _selectedTipos!.isNotEmpty) ||
              _searchControllerNombre.text.isNotEmpty ||
              _searchControllerNumeroDoc.text.isNotEmpty ||
              _selectedUsuarioCreado != null ||
              _selectedUsuarioMod != null ||
              _groupValueOrdenes != 0;
      case 1:
        return _fechaDesdeEntregas != null ||
              _fechaHastaEntregas != null ||
              _selectedUsuarioEntrega != null ||
              _groupValueEntregas != 0;
      case 2:
        return _fechaDesdeBultos != null ||
              _fechaHastaBultos != null ||
              _searchControllerClienteBulto.text.isNotEmpty ||
              _searchControllerBultoId.text.isNotEmpty ||
              _selectedUsuarioArmado != null ||
              _selectedModoEnvioId != null ||
              _selectedTipoBultoId != null ||
              _groupValueBultos != 0;
      case 3:
        // No hay filtros para retiros
        return false;
      default:
        return false;
    }
  }

  Widget _buildOrdenesTab() {
    return Column(
      children: [
        CustomSegmentedControl(
          groupValue: _groupValueOrdenes,
          onValueChanged: (newValue) {
            setState(() {
              _groupValueOrdenes = newValue;
              _loadData();
            });
          },
          options: SegmentedOptions.monitorOrdenes,
          usePickingStyle: true,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Última actualización: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(_ultimaActualizacion)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
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

  Widget _buildEntregasTab() {
    return Column(
      children: [
        CustomSegmentedControl(
          groupValue: _groupValueEntregas,
          onValueChanged: (newValue) {
            setState(() {
              _groupValueEntregas = newValue;
              _loadData();
            });
          },
          options: SegmentedOptions.monitorEntregas,
          usePickingStyle: true,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Última actualización: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(_ultimaActualizacion)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  child: _filteredEntregas.isEmpty
                      ? _buildEmptyState('No se encontraron entregas')
                      : ListView.builder(
                          itemCount: _filteredEntregas.length,
                          itemBuilder: (context, index) {
                            final entrega = _filteredEntregas[index];
                            return _buildEntregaCard(entrega);
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
        CustomSegmentedControl(
          groupValue: _groupValueBultos,
          onValueChanged: (newValue) {
            setState(() {
              _groupValueBultos = newValue;
              _loadData();
            });
          },
          options: SegmentedOptions.monitorBultos,
          usePickingStyle: true,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Última actualización: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(_ultimaActualizacion)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
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

  Widget _buildRetirosTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Última actualización: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(_ultimaActualizacion)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  child: _filteredRetiros.isEmpty
                      ? _buildEmptyState('No se encontraron retiros')
                      : ListView.builder(
                          itemCount: _filteredRetiros.length,
                          itemBuilder: (context, index) {
                            final retiro = _filteredRetiros[index];
                            return _buildRetiroCard(retiro);
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildRetiroCard(Retiro retiro) {
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
        onTap: () => _confirmarImpresionRetiro(retiro),
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
                        'Retiro #${retiro.retiroId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Fecha: ${retiro.fecha != null ? DateFormat('dd/MM/yyyy HH:mm').format(retiro.fecha!) : 'N/A'}',
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
                            _infoBox('Transportista:', '${retiro.agenciaTrId}'),
                            _infoBox('Retirado por:', retiro.retiradoPor),
                            _infoBox('Usuario:', '${retiro.usuarioId}'),
                            if (retiro.comentario.isNotEmpty)
                              _infoBox('Comentario:', retiro.comentario),
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
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'RETIRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
                  _infoBox('Transportista:', '${retiro.agenciaTrId}'),
                  _infoBox('Retirado por:', retiro.retiradoPor),
                  _infoBox('Usuario:', '${retiro.usuarioId}'),
                  if (retiro.comentario.isNotEmpty)
                    _infoBox('Comentario:', retiro.comentario),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarImpresionRetiro(Retiro retiro) async {
    bool confirmado = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Impresión'),
        content: const Text('¿Desea imprimir los datos de este retiro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ACEPTAR'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await _imprimirRetiro(retiro.retiroId);
    }
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

  Widget _buildEntregaCard(Entrega entrega) {
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
          Provider.of<ProductProvider>(context, listen: false).setEntrega(entrega);
          Provider.of<ProductProvider>(context, listen: false).setVistaMonitor(true);
          appRouter.push('/salidaBultos');
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
                        'Entrega #${entrega.entregaId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(entrega.fechaDate)}',
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
                            _infoBox('Almacén:', '${entrega.almacenIdOrigen}'),
                            _infoBox('Usuario:', '${entrega.usuId}'),
                            _infoBox('Bultos:', '${entrega.cantBultos}'),
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
                          color: _getEntregaStatusColor(entrega.estado),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          entrega.estado,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
                  _infoBox('Almacén:', '${entrega.almacenIdOrigen}'),
                  _infoBox('Usuario:', '${entrega.usuId}'),
                  _infoBox('Bultos:', '${entrega.cantBultos}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBultoCard(Bulto bulto) {
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
                            _infoBox('Fecha:', DateFormat('dd/MM/yyyy HH:mm').format(bulto.fechaDate)),
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
                  _infoBox('Fecha:', DateFormat('dd/MM/yyyy HH:mm').format(bulto.fechaDate)),
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
    } else if (_tabController.index == 1) {
      return FiltrosEntregas(
        usuarios: usuarios,
        onSearch: (fechaDesde, fechaHasta, usuario) {
          setState(() {
            _fechaDesdeEntregas = fechaDesde;
            _fechaHastaEntregas = fechaHasta;
            _selectedUsuarioEntrega = usuario;
          });
          _loadData();
        },
        isFilterExpanded: _isFilterExpanded,
        onToggleFilter: (expanded) {
          setState(() {
            _isFilterExpanded = expanded;
          });
        },
        cantidadDeEntregas: _filteredEntregas.length, 
        onReset: _resetFilters,
      );
    } else if (_tabController.index == 2) {
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
    } else {
      // No hay filtros para la pestaña de retiros
      return const SizedBox.shrink();
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
              _startRefreshTimer();
              _loadData();
            },
            labelColor: colors.onPrimary,
            unselectedLabelColor: colors.onPrimary.withValues(alpha: 0.7),
            indicatorColor: colors.onPrimary,
            tabs: const [
              Tab(text: 'Órdenes', icon: Icon(Icons.list_alt)),
              Tab(text: 'Entregas', icon: Icon(Icons.dashboard)),
              Tab(text: 'Bultos', icon: Icon(Icons.inventory_2)),
              Tab(text: 'Retiros', icon: Icon(Icons.local_shipping)),
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
                  _buildEntregasTab(),
                  _buildBultosTab(),
                  _buildRetirosTab(),
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
      case 'PREPARADO':
        return Colors.green;
      case 'CANCELADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getEntregaStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'EN PROCESO':
        return Colors.blue;
      case 'FINALIZADA':
        return Colors.green;
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

  Future<void> _imprimirRetiro(int retiroId) async {
    try {
      await _entregaServices.postImprimirRetiro(
        context,
        retiroId,
        token,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impresión del retiro enviada correctamente'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al imprimir: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}