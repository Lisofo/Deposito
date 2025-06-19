import 'package:deposito/widgets/filtros_picking.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/picking_services.dart';
import 'package:provider/provider.dart';

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
  
  List<OrdenPicking> _ordenes = [];
  List<OrdenPicking> _filteredOrdenes = [];
  bool _isLoading = true;
  bool _isFilterExpanded = false;

  // Filtros
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  String? _selectedPrioridad;
  int _groupValue = -1;

  String token = '';
  late String menu;
  late List<String> menuSplitted;

  @override
  void initState() {
    super.initState();
    token = context.read<ProductProvider>().token;
    menu = context.read<ProductProvider>().menu;
    menuSplitted = menu.split('-');
    _loadData();
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
      );
      
      if (result != null && _pickingServices.statusCode == 1) {
        setState(() {
          _ordenes = result;
          _filteredOrdenes = List.from(_ordenes);
        });
      }
    } finally {
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
              usuarios: null,
              mostrarFiltroUsuarios: false,
              mostrarFiltroTipos: false,
              onSearch: (fechaDesde, fechaHasta, prioridad, tipos, usuarioCreado, usuarioMod) {
                setState(() {
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
                -1: buildSegment('Todos'),
                0: buildSegment('Pendiente'),
                1: buildSegment('En Proceso'),
                2: buildSegment('Completado'),
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
                                            children: [
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
                                          Text('Tipo: ${orden.tipo}'),
                                          Text('Cliente: ${orden.codEntidad} - ${orden.nombre}'),
                                          Text('RUC: ${orden.ruc}'),
                                          Text(orden.transaccion),
                                          Text('Fecha: ${DateFormat('dd/MM/yyyy').format(orden.fechaDate)}'),
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