import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/picking_services.dart';
import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final PickingServices _pickingServices = PickingServices();
  DateTime _selectedDate = DateTime.now();
  List<OrdenPicking> _ordenes = [];
  bool _isLoading = true;

  // Estadísticas
  int _totalOrders = 0;
  int _releasedForPick = 0;
  int _inPick = 0;
  int _packed = 0;
  int _inPack = 0;
  int _incompleto = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final token = context.read<ProductProvider>().token;
    final almacenId = context.read<ProductProvider>().almacen.almacenId;

    // Ajustar las fechas para el día seleccionado (desde las 00:00 hasta las 23:59)
    DateTime startDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0, 0);
    DateTime endDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    final result = await _pickingServices.getOrdenesPicking(
      context,
      almacenId,
      token,
      fechaDateDesde: startDate,
      fechaDateHasta: endDate,
    );

    if (result != null && _pickingServices.statusCode == 1) {
      setState(() {
        _ordenes = result;
        _calculateStats();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateStats() {
    _totalOrders = _ordenes.length;
    _releasedForPick = _ordenes.where((orden) => orden.estado == 'PENDIENTE').length;
    _inPick = _ordenes.where((orden) => orden.estado == 'EN PROCESO').length;
    _packed = _ordenes.where((orden) => orden.estado == 'PREPARADO').length;
    _incompleto = _ordenes.where((orden) => orden.porcentajeCompletado < 100 && orden.estado != 'PREPARADO').length;
    _inPack = _ordenes.where((orden) => orden.estado == 'EMPAQUETADO' && orden.porcentajeCompletado >= 0).length;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Theme.of(context).scaffoldBackgroundColor,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ), 
            dialogTheme: DialogThemeData(backgroundColor: Theme.of(context).scaffoldBackgroundColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  List<Map<String, dynamic>> getChartData() {
    return [
      {'status': 'Pendiente', 'value': _releasedForPick, 'color': Colors.orange},
      {'status': 'En Proceso', 'value': _inPick, 'color': Colors.blue},
      {'status': 'Preparado', 'value': _packed, 'color': Colors.green},
      {'status': 'Incompleto', 'value': _incompleto, 'color': Colors.red},
    ];
  }

  Widget _buildStatCard(String title, int value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: isLargeScreen ? 180 : 160, // Ancho fijo para Wrap
        height: isLargeScreen ? 140 : 130, // Altura fija
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String status, int count, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              status,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  // Variable para controlar el tamaño de pantalla
  late bool isLargeScreen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Determinar si es una pantalla grande
    isLargeScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        iconTheme: IconThemeData(color: colors.onPrimary),
        title: Text(
          context.read<ProductProvider>().menuTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.onPrimary,
          ),
        ),
        backgroundColor: colors.primary,
        actions: [
          IconButton(
            onPressed: () => _loadData(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con selector de fecha
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.primary.withValues(alpha: 0.05),
                            colors.primary.withValues(alpha: 0.02),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Resumen del Día',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(_selectedDate),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                          FilledButton.icon(
                            onPressed: () => _selectDate(context),
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: const Text('Cambiar fecha'),
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Wrap de estadísticas principales con tamaño fijo
                  Center(
                    child: Wrap(
                      spacing: 12, // Espacio horizontal entre elementos
                      runSpacing: 12, // Espacio vertical entre líneas
                      alignment: WrapAlignment.center,
                      children: [
                        _buildStatCard('Total', _totalOrders, colors.primary, Icons.list_alt),
                        _buildStatCard('Pendientes', _releasedForPick, Colors.orange, Icons.schedule),
                        _buildStatCard('En Proceso', _inPick, Colors.blue, Icons.play_arrow),
                        _buildStatCard('Preparados', _packed, Colors.green, Icons.check_circle),
                        _buildStatCard('Empaquetados', _inPack, Colors.purple, Icons.inventory_2),
                        _buildStatCard('Incompletos', _incompleto, Colors.red, Icons.error),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isLargeScreen) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Detalles de estado
                        Expanded(
                          flex: 1,
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.bar_chart, color: colors.primary, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Detalles de Estado',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),
                                  Column(
                                    children: [
                                      _buildStatusRow('Pendientes', _releasedForPick, Colors.orange),
                                      _buildStatusRow('En Proceso', _inPick, Colors.blue),
                                      _buildStatusRow('Preparados', _packed, Colors.green),
                                      _buildStatusRow('Empaquetados', _inPack, Colors.purple),
                                      _buildStatusRow('Incompletos', _incompleto, Colors.red),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Gráfico
                        Expanded(
                          flex: 2,
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.pie_chart, color: colors.primary, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Distribución de Órdenes',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 180, // Altura fija para el gráfico
                                    child: Chart(
                                      data: getChartData(),
                                      variables: {
                                        'status': Variable(
                                          accessor: (Map map) => map['status'] as String,
                                        ),
                                        'value': Variable(
                                          accessor: (Map map) => map['value'] as num,
                                        ),
                                      },
                                      marks: [
                                        IntervalMark(
                                          color: ColorEncode(
                                            variable: 'status',
                                            values: getChartData().map((e) => e['color'] as Color).toList(),
                                          ),
                                        )
                                      ],
                                      axes: [
                                        Defaults.horizontalAxis,
                                        Defaults.verticalAxis,
                                      ],
                                      coord: RectCoord(
                                        transposed: screenWidth < 400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Pickers activos en pantalla grande
                    Center(
                      child: SizedBox(
                        width: screenWidth * 0.6, // Ancho controlado
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.people, color: colors.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Pickers Activos',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.play_arrow, color: Colors.blue, size: 24),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'En Proceso',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                        Text(
                                          _inPick.toString(),
                                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Completados',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                        Text(
                                          _packed.toString(),
                                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Diseño original para pantallas pequeñas
                    // Detalles de estado
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.bar_chart, color: colors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Detalles de Estado',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Column(
                              children: [
                                _buildStatusRow('Pendientes', _releasedForPick, Colors.orange),
                                _buildStatusRow('En Proceso', _inPick, Colors.blue),
                                _buildStatusRow('Preparados', _packed, Colors.green),
                                _buildStatusRow('Empaquetados', _inPack, Colors.purple),
                                _buildStatusRow('Incompletos', _incompleto, Colors.red),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Gráfico
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.pie_chart, color: colors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Distribución de Órdenes',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: isLandscape ? 250 : 300,
                              child: Chart(
                                data: getChartData(),
                                variables: {
                                  'status': Variable(
                                    accessor: (Map map) => map['status'] as String,
                                  ),
                                  'value': Variable(
                                    accessor: (Map map) => map['value'] as num,
                                  ),
                                },
                                marks: [
                                  IntervalMark(
                                    color: ColorEncode(
                                      variable: 'status',
                                      values: getChartData().map((e) => e['color'] as Color).toList(),
                                    ),
                                  )
                                ],
                                axes: [
                                  Defaults.horizontalAxis,
                                  Defaults.verticalAxis,
                                ],
                                coord: RectCoord(
                                  transposed: screenWidth < 400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Pickers activos
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.people, color: colors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Pedidos Activos',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.play_arrow, color: Colors.blue, size: 24),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'En Proceso',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    Text(
                                      _inPick.toString(),
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Completados',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    Text(
                                      _packed.toString(),
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
    );
  }
}