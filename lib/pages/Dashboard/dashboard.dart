import 'dart:async';
import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/models/bulto.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/picking_services.dart';
import 'package:deposito/services/entrega_services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final PickingServices _pickingServices = PickingServices();
  final EntregaServices _entregaServices = EntregaServices();
  DateTime _selectedDate = DateTime.now();
  List<OrdenPicking> _ordenes = [];
  List<Bulto> _bultos = [];
  bool _isLoading = true;

  // Timer para recarga automática
  Timer? _autoRefreshTimer;

  // Estadísticas
  int _totalOrders = 0;
  int _releasedForPick = 0;
  int _inPick = 0;
  int _packed = 0;
  int _inPack = 0;
  // ignore: prefer_final_fields
  int _incompleto = 0;
  int _embalaje = 0;

  // Estadísticas bultos
  int _totalBultos = 0;
  int _cerrados = 0;
  int _retirados = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoRefreshTimer();
  }

  @override
  void dispose() {
    // Cancelar el timer cuando el widget se destruya
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  // Método para iniciar el timer de recarga automática
  void _startAutoRefreshTimer() {
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (mounted) {
        _loadData();
      }
    });
  }

  // Método para reiniciar el timer (opcional)
  void _restartAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _startAutoRefreshTimer();
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
      tipo: 'V, TS',
    );

    // Cargar bultos
    final bultosResult = await _entregaServices.getBultos(
      context,
      token,
      fechaDateDesde: startDate.toString(),
      fechaDateHasta: endDate.toString(),
    );

    if ((result != null && _pickingServices.statusCode == 1)) {
      setState(() {
        _ordenes = result ?? [];
        _bultos = bultosResult.where((bulto) => bulto.tipoBultoId != 4).toList();
        _calculateStats();
        _calculateBultosStats();
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
    _packed = _ordenes.where((orden) => (orden.estado == 'PREPARADO' || orden.estado == 'PAPEL')).length;
    _inPack = _ordenes.where((orden) => orden.estado == 'ENTREGADO').length;
    _embalaje = _ordenes.where((orden) => orden.estado == 'EMBALAJE').length;
    // _incompleto = _ordenes.where((orden) => orden.porcentajeCompletado < 100 && orden.estado != 'PREPARADO').length;
  }

  void _calculateBultosStats() {
    _totalBultos = _bultos.length;
    _cerrados = _bultos.where((bulto) => bulto.estado == 'CERRADO').length;
    _retirados = _bultos.where((bulto) => bulto.estado == 'RETIRADO').length;
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

  // Método auxiliar para determinar el tamaño de los cards según el ancho de pantalla
  double _getCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth > 1200) {
      return 180;
    } else if (screenWidth > 800) {
      return 160;
    } else if (screenWidth > 600) {
      return 140;
    } else {
      return (screenWidth - 48) / 2; // 48 = padding (16*2) + spacing (8*2)
    }
  }

  double _getCardHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth > 1200) {
      return 140;
    } else if (screenWidth > 800) {
      return 130;
    } else if (screenWidth > 600) {
      return 120;
    } else {
      return 110;
    }
  }

  Widget _buildStatCard(String title, int value, Color color, IconData icon, BuildContext context) {
    final cardWidth = _getCardWidth(context);
    final cardHeight = _getCardHeight(context);
    
    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(12),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: _getIconSize(context)),
              ),
              const SizedBox(height: 6),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: _getValueFontSize(context),
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: _getLabelFontSize(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getIconSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 800) return 20;
    if (screenWidth > 600) return 18;
    return 16;
  }

  double _getValueFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 800) return 24;
    if (screenWidth > 600) return 20;
    return 18;
  }

  double _getLabelFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 800) return 14;
    if (screenWidth > 600) return 12;
    return 10;
  }

  Widget _buildStatusRow(String status, int count, Color color, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: _getDotSize(context),
            height: _getDotSize(context),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              status,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: _getStatusFontSize(context),
              ),
            ),
          ),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: _getStatusCountFontSize(context),
                ),
          ),
        ],
      ),
    );
  }

  double _getDotSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) return 12;
    return 10;
  }

  double _getStatusFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) return 14;
    return 12;
  }

  double _getStatusCountFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) return 16;
    return 14;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Definir breakpoints para diseño responsive
    final bool isLargeScreen = screenWidth > 1000;
    final bool isMediumScreen = screenWidth > 600;
    final bool isSmallScreen = screenWidth <= 600;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        iconTheme: IconThemeData(color: colors.onPrimary),
        title: Row(
          children: [
            Text(
              context.read<ProductProvider>().menuTitle,
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.w600,
                color: colors.onPrimary,
              ),
            ),
            const SizedBox(width: 8),
            // Indicador visual del auto-refresh (opcional)
            Icon(
              Icons.autorenew,
              size: 16,
              color: colors.onPrimary.withValues(alpha: 0.7),
            ),
          ],
        ),
        backgroundColor: colors.primary,
        actions: [
          IconButton(
            onPressed: () {
              _loadData();
              _restartAutoRefreshTimer(); // Reiniciar el timer al refrescar manualmente
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con selector de fecha - Mejorado para responsive
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
                      child: isSmallScreen 
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Resumen del Día',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(_selectedDate),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurface.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
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
                                ),
                              ],
                            )
                          : Row(
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
                  const SizedBox(height: 20),
                  
                  // Estadísticas principales - Siempre con Wrap
                  Center(
                    child: Wrap(
                      spacing: isSmallScreen ? 8 : 12,
                      runSpacing: isSmallScreen ? 8 : 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildStatCard('Total', _totalOrders, colors.primary, Icons.list_alt, context),
                        _buildStatCard('Pendientes', _releasedForPick, Colors.orange, Icons.schedule, context),
                        _buildStatCard('En Proceso', _inPick, Colors.blue, Icons.play_arrow, context),
                        _buildStatCard('Preparados', _packed, Colors.green, Icons.check_circle, context),
                        _buildStatCard('Embalaje', _embalaje, Colors.yellow, Icons.inventory_2, context),
                        _buildStatCard('Empaquetados', _inPack, Colors.purple, Icons.inventory_outlined, context),
                        // _buildStatCard('Incompletos', _incompleto, Colors.red, Icons.error, context),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Contenido principal - Diseños diferentes según tamaño de pantalla
                  if (isLargeScreen) 
                    _buildLargeScreenLayout(context, colors)
                  else if (isMediumScreen)
                    _buildMediumScreenLayout(context, colors)
                  else
                    _buildSmallScreenLayout(context, colors),
                  
                  const SizedBox(height: 20),
                  
                  // Pickers Activos - Responsive
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isSmallScreen 
                            ? screenWidth * 0.9 
                            : isMediumScreen 
                                ? screenWidth * 0.7 
                                : screenWidth * 0.6,
                      ),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people, color: colors.primary, size: _getIconSize(context)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Pickers Activos',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 16 : 18,
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
                                        padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.play_arrow, 
                                            color: Colors.blue, 
                                            size: isSmallScreen ? 20 : 24),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'En Proceso',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontSize: isSmallScreen ? 10 : 12,
                                        ),
                                      ),
                                      Text(
                                        _inPick.toString(),
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                          fontSize: isSmallScreen ? 18 : 24,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.check_circle, 
                                            color: Colors.green, 
                                            size: isSmallScreen ? 20 : 24),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Preparados',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontSize: isSmallScreen ? 10 : 12,
                                        ),
                                      ),
                                      Text(
                                        _packed.toString(),
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                          fontSize: isSmallScreen ? 18 : 24,
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
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildLargeScreenLayout(BuildContext context, ColorScheme colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Detalles de estado de órdenes
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
                        'Detalles de Estado - Órdenes',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Column(
                    children: [
                      _buildStatusRow('Pendientes', _releasedForPick, Colors.orange, context),
                      _buildStatusRow('En Proceso', _inPick, Colors.blue, context),
                      _buildStatusRow('Preparados', _packed, Colors.green, context),
                      _buildStatusRow('Embalaje', _embalaje, Colors.yellow, context),
                      _buildStatusRow('Empaquetados', _inPack, Colors.purple, context),
                      // _buildStatusRow('Incompletos', _incompleto, Colors.red, context),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Estadísticas de bultos
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
                      Icon(Icons.inventory, color: colors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Estadísticas de Bultos',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildStatCard('Total Bultos', _totalBultos, colors.primary, Icons.inventory, context),
                        _buildStatCard('Cerrados', _cerrados, Colors.purple, Icons.lock, context),
                        _buildStatCard('Retirados', _retirados, Colors.green, Icons.check_circle_outline, context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediumScreenLayout(BuildContext context, ColorScheme colors) {
    return Column(
      children: [
        // Detalles de estado de órdenes
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
                      'Detalles de Estado - Órdenes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    _buildStatusRow('Pendientes', _releasedForPick, Colors.orange, context),
                    _buildStatusRow('En Proceso', _inPick, Colors.blue, context),
                    _buildStatusRow('Preparados', _packed, Colors.green, context),
                    _buildStatusRow('Embalaje', _embalaje, Colors.yellow, context),
                    _buildStatusRow('Empaquetados', _inPack, Colors.purple, context),
                    // _buildStatusRow('Incompletos', _incompleto, Colors.red, context),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Estadísticas de bultos
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
                    Icon(Icons.inventory, color: colors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Estadísticas de Bultos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildStatCard('Total Bultos', _totalBultos, colors.primary, Icons.inventory, context),
                      _buildStatCard('Cerrados', _cerrados, Colors.purple, Icons.lock, context),
                      _buildStatCard('Retirados', _retirados, Colors.green, Icons.check_circle_outline, context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallScreenLayout(BuildContext context, ColorScheme colors) {
    return Column(
      children: [
        // Detalles de estado de órdenes
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bar_chart, color: colors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Detalles de Estado - Órdenes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    _buildStatusRow('Pendientes', _releasedForPick, Colors.orange, context),
                    _buildStatusRow('En Proceso', _inPick, Colors.blue, context),
                    _buildStatusRow('Preparados', _packed, Colors.green, context),
                    _buildStatusRow('Embalaje', _embalaje, Colors.yellow, context),
                    _buildStatusRow('Empaquetados', _inPack, Colors.purple, context),
                    // _buildStatusRow('Incompletos', _incompleto, Colors.red, context),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Estadísticas de bultos
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory, color: colors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Estadísticas de Bultos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildStatCard('Total Bultos', _totalBultos, colors.primary, Icons.inventory, context),
                      _buildStatCard('Cerrados', _cerrados, Colors.purple, Icons.lock, context),
                      _buildStatCard('Retirados', _retirados, Colors.green, Icons.check_circle_outline, context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}