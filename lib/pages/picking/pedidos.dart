// ignore_for_file: unused_field

import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/picking_services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ListaPicking extends StatefulWidget {
  const ListaPicking({super.key});

  @override
  State<ListaPicking> createState() => _ListaPickingState();
}

class _ListaPickingState extends State<ListaPicking> {
  final PickingServices _pickingServices = PickingServices();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  late Almacen almacen = Almacen.empty();
  
  List<OrdenPicking> _ordenes = [];
  List<OrdenPicking> _filteredOrdenes = [];
  bool _isLoading = true;
  bool _isFilterExpanded = false; // Nuevo: controla si los filtros están expandidos

  // Filtros
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  String? _selectedPrioridad;
  String? _selectedEstado;
  int _groupValue = -1;

  // Opciones para dropdowns
  final List<String> _prioridades = ['ALTA', 'NORMAL', 'BAJA', 'TODAS'];
  final List<String> _estados = ['Pendiente', 'En proceso', 'Cerrado', 'Cancelado', 'Todos'];

  String token = '';

  @override
  void initState() {
    super.initState();
    token = context.read<ProductProvider>().token;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _pickingServices.resetStatusCode();
      String menu = context.read<ProductProvider>().menu;
      var menuSplitted = menu.split('-');
      final result = await _pickingServices.getOrdenesPicking(context, almacen.almacenId,token, tipo: menuSplitted[1]);
      if (result != null && _pickingServices.statusCode == 1) {
        setState(() {
          _ordenes = result;
          _filteredOrdenes = List.from(_ordenes); // Primero carga todos los datos sin filtros
          _applyFilters(); // Luego aplica los filtros si los hay
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      await _pickingServices.resetStatusCode();
      String menu = context.read<ProductProvider>().menu;
      var menuSplitted = menu.split('-');
      final result = await _pickingServices.getOrdenesPicking(context, almacen.almacenId,token, tipo: menuSplitted[1]);
      if (result != null && _pickingServices.statusCode == 1) {
        setState(() {
          _ordenes = result;
          _applyFilters(); // Aplica los filtros activos (incluyendo el estado del segmented control)
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<OrdenPicking> filtered = List.from(_ordenes);

    // Filtro de búsqueda de texto
    if (_searchController.text.isNotEmpty) {
      final searchText = _searchController.text.toLowerCase();
      filtered = filtered.where((orden) =>
        orden.tipo.toLowerCase().contains(searchText) ||
        orden.nombre.toLowerCase().contains(searchText) ||
        orden.numeroDocumento.toString().contains(searchText) ||
        (orden.serie?.toLowerCase().contains(searchText) ?? false)
      ).toList();
    }

    // Filtro por estado (segmented control)
    if (_groupValue != -1) {
      switch (_groupValue) {
        case 0:
          filtered = filtered.where((orden) => orden.estado.toUpperCase() == 'PENDIENTE').toList();
          break;
        case 1:
          filtered = filtered.where((orden) => orden.estado.toUpperCase() == 'EN PROCESO').toList();
          break;
        case 2:
          filtered = filtered.where((orden) => orden.estado.toUpperCase() == 'CERRADO').toList();
          break;
      }
    }

    // Filtro por fecha desde
    if (_fechaDesde != null) {
      filtered = filtered.where((orden) => 
        orden.fechaDate.isAfter(_fechaDesde!) || 
        orden.fechaDate.isAtSameMomentAs(_fechaDesde!)
      ).toList();
    }

    // Filtro por fecha hasta
    if (_fechaHasta != null) {
      filtered = filtered.where((orden) => 
        orden.fechaDate.isBefore(_fechaHasta!) || 
        orden.fechaDate.isAtSameMomentAs(_fechaHasta!)
      ).toList();
    }

    // Filtro por prioridad
    if (_selectedPrioridad != null && _selectedPrioridad!.isNotEmpty && _selectedPrioridad != 'TODAS') {
      filtered = filtered.where((orden) => orden.prioridad == _selectedPrioridad).toList();
    }    
    setState(() => _filteredOrdenes = filtered);
  }

  void _resetFilters() {
    setState(() {
      _fechaDesde = null;
      _fechaHasta = null;
      _selectedPrioridad = null;
      _selectedEstado = null;
      _groupValue = -1;
      _searchController.clear();
      _filteredOrdenes = List.from(_ordenes);
    });
  }

  Future<void> _selectDate(BuildContext context, bool isDesde) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isDesde) {
          _fechaDesde = picked;
        } else {
          _fechaHasta = picked;
        }
        _applyFilters();
      });
    }
  }

  // Método para verificar si hay filtros activos
  bool _hasActiveFilters() {
    return _fechaDesde != null ||
           _fechaHasta != null ||
           (_selectedPrioridad != null && _selectedPrioridad != 'TODAS') ||
           _searchController.text.isNotEmpty ||
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
            // Indicador de filtros activos
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
            Card(
              margin: const EdgeInsets.all(10),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isFilterExpanded = !_isFilterExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.filter_list),
                          const SizedBox(width: 8),
                          const Text(
                            'Filtros',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          // Mostrar conteo de filtros activos
                          if (_hasActiveFilters())
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_filteredOrdenes.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Icon(
                            _isFilterExpanded 
                              ? Icons.keyboard_arrow_up 
                              : Icons.keyboard_arrow_down,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Contenido de filtros (colapsable)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _isFilterExpanded ? null : 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _isFilterExpanded ? 1.0 : 0.0,
                      child: _isFilterExpanded
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: Column(
                              children: [
                                const Divider(),
                                // Búsqueda general
                                TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    labelText: 'Buscar (Tipo, Código, RUC, Documento, Serie)',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _searchController.clear();
                                            _applyFilters();
                                          },
                                        )
                                      : const Icon(Icons.search),
                                  ),
                                  onChanged: (value) => _applyFilters(),
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => _selectDate(context, true),
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            labelText: 'Fecha Desde',
                                            border: const OutlineInputBorder(),
                                            suffixIcon: _fechaDesde != null
                                              ? IconButton(
                                                  icon: const Icon(Icons.clear, size: 18),
                                                  onPressed: () {
                                                    setState(() {
                                                      _fechaDesde = null;
                                                      _applyFilters();
                                                    });
                                                  },
                                                )
                                              : const Icon(Icons.calendar_today, size: 18),
                                          ),
                                          child: Text(
                                            _fechaDesde != null 
                                              ? DateFormat('dd/MM/yyyy').format(_fechaDesde!)
                                              : 'Seleccionar fecha',
                                            style: TextStyle(
                                              color: _fechaDesde != null 
                                                ? Colors.black 
                                                : Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => _selectDate(context, false),
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            labelText: 'Fecha Hasta',
                                            border: const OutlineInputBorder(),
                                            suffixIcon: _fechaHasta != null
                                              ? IconButton(
                                                  icon: const Icon(Icons.clear, size: 18),
                                                  onPressed: () {
                                                    setState(() {
                                                      _fechaHasta = null;
                                                      _applyFilters();
                                                    });
                                                  },
                                                )
                                              : const Icon(Icons.calendar_today, size: 18),
                                          ),
                                          child: Text(
                                            _fechaHasta != null 
                                              ? DateFormat('dd/MM/yyyy').format(_fechaHasta!)
                                              : 'Seleccionar fecha',
                                            style: TextStyle(
                                              color: _fechaHasta != null 
                                                ? Colors.black 
                                                : Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                // Prioridad Dropdown
                                DropdownButtonFormField<String>(
                                  value: _selectedPrioridad,
                                  decoration: InputDecoration(
                                    labelText: 'Prioridad',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: _selectedPrioridad != null && _selectedPrioridad != 'TODAS'
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            setState(() {
                                              _selectedPrioridad = 'TODAS';
                                              _applyFilters();
                                            });
                                          },
                                        )
                                      : null,
                                  ),
                                  items: _prioridades.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedPrioridad = newValue;
                                      _applyFilters();
                                    });
                                  },
                                ),
                              ],
                            ),
                          )
                        : Container(),
                    ),
                  ),
                ],
              ),
            ),
            // Segmented Control para estados (siempre visible)
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
                  _applyFilters();
                });
              },
            ),
            const SizedBox(height: 10),
            // Lista de resultados
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
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text('Tipo: ${orden.tipo}'),
                                          Text('Cliente: ${orden.codEntidad} - ${orden.nombre}'),
                                          Text('RUC: ${orden.ruc}'),
                                          Row(
                                            children: [
                                              Text('Prioridad: ${orden.prioridad}'),
                                              const Spacer(),
                                              Text('Líneas: ${orden.cantLineas ?? 0}'),
                                            ],
                                          ),
                                          Text(orden.transaccion),
                                          Row(
                                            children: [
                                              Text('Fecha: ${DateFormat('dd/MM/yyyy').format(orden.fechaDate)}'),
                                              const Spacer(),
                                              Text(orden.pickId.toString())
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