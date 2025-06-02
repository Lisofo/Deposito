// ignore_for_file: unused_field

import 'package:deposito/config/router/router.dart';
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

  List<OrdenPicking> _ordenes = [];
  List<OrdenPicking> _filteredOrdenes = [];
  bool _isLoading = true;

  // Filtros
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  String? _selectedPrioridad;
  String? _selectedEstado;
  int _groupValue = -1;

  // Opciones para dropdowns
  final List<String> _prioridades = ['Alta', 'Media', 'Baja', 'Todas'];
  final List<String> _estados = ['Pendiente', 'En proceso', 'Completado', 'Cancelado', 'Todos'];

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
      final result = await _pickingServices.getOrdenesPicking(context, token);
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

  void _applyFilters() {
    List<OrdenPicking> filtered = List.from(_ordenes);

    if (_searchController.text.isNotEmpty) {
      final searchText = _searchController.text.toLowerCase();
      filtered = filtered.where((orden) =>
        orden.tipo.toLowerCase().contains(searchText) ||
        orden.codEntidad.toLowerCase().contains(searchText) ||
        orden.ruc.toLowerCase().contains(searchText) ||
        orden.numeroDocumento.toString().contains(searchText) ||
        (orden.serie?.toLowerCase().contains(searchText) ?? false)
      ).toList();
    }

    if (filtered.isNotEmpty) {
      switch (_groupValue) {
        case -1: // Todos
          break; // No filtrar
        case 0:
          filtered = filtered.where((orden) => orden.estado == 'PENDIENTE').toList();
          break;
        case 1:
          filtered = filtered.where((orden) => orden.estado == 'EN PROCESO').toList();
          break;
        case 2:
          filtered = filtered.where((orden) => orden.estado == 'COMPLETADO').toList();
          break;
      }
    }

    if (filtered.isNotEmpty) {
      if (_fechaDesde != null) {
        filtered = filtered.where((orden) => 
          orden.fechaDate.isAfter(_fechaDesde!) || 
          orden.fechaDate.isAtSameMomentAs(_fechaDesde!)
        ).toList();
      }

      if (_fechaHasta != null) {
        filtered = filtered.where((orden) => 
          orden.fechaDate.isBefore(_fechaHasta!) || 
          orden.fechaDate.isAtSameMomentAs(_fechaHasta!)
        ).toList();
      }
    }

    if (filtered.isNotEmpty && _selectedPrioridad != null && _selectedPrioridad!.isNotEmpty && _selectedPrioridad != 'Todas') {
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colors.primary,
          title: const Text(
            'Lista de Picking',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: IconThemeData(color: colors.onPrimary),
          actions: [
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
            // Filtros superiores
            Card(
              margin: const EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    // Fechas
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Fecha Desde',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _fechaDesde != null 
                                  ? DateFormat('dd/MM/yyyy').format(_fechaDesde!)
                                  : 'Seleccionar fecha',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Fecha Hasta',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _fechaHasta != null 
                                  ? DateFormat('dd/MM/yyyy').format(_fechaHasta!)
                                  : 'Seleccionar fecha',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    
                    // Prioridad Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedPrioridad,
                      decoration: const InputDecoration(
                        labelText: 'Prioridad',
                        border: OutlineInputBorder(),
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
                    const SizedBox(height: 10),
                    
                    // Búsqueda general
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Buscar (Tipo, Código, RUC, Documento, Serie)',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        ),
                      ),
                      onChanged: (value) => _applyFilters(),
                    ),
                  ],
                ),
              ),
            ),
            
            // Segmented Control para estados
            CupertinoSegmentedControl<int>(
              padding: const EdgeInsets.all(10),
              groupValue: _groupValue,
              borderColor: Colors.black,
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
            
            // Lista de resultados
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      key: _refreshIndicatorKey,
                      onRefresh: _refreshData,
                      child: _filteredOrdenes.isEmpty
                          ? const Center(
                              child: Text(
                                'No se encontraron órdenes con los filtros aplicados',
                                style: TextStyle(fontSize: 16),
                              ),
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
                                    borderRadius: BorderRadius.circular(5),
                                    side: const BorderSide(
                                      color: Colors.black,
                                      width: 1,
                                    ),
                                  ),
                                  elevation: 5,
                                  child: InkWell(
                                    onTap: () {
                                      Provider.of<ProductProvider>(context, listen: false).setOrdenPicking(orden);
                                      appRouter.push('/pickingInterno');
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'Doc: ${orden.numeroDocumento} ${orden.serie ?? ''}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                              const Spacer(),
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
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text('Tipo: ${orden.tipo}'),
                                          Text('Cliente: ${orden.codEntidad} - ${orden.nombre}'),
                                          Text('RUC: ${orden.ruc}'),
                                          Text('Prioridad: ${orden.prioridad}'),
                                          Text('Fecha: ${DateFormat('dd/MM/yyyy').format(orden.fechaDate)}'),
                                          Text('Líneas: ${orden.cantLineas ?? 0}'),
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
    switch (status) {
      case 'Pendiente':
        return Colors.orange;
      case 'En proceso':
        return Colors.blue;
      case 'Completado':
        return Colors.green;
      case 'Cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget buildSegment(String text) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}