import 'package:deposito/models/orden_picking.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:provider/provider.dart';
import 'package:deposito/provider/product_provider.dart';

class PickingProducts extends StatefulWidget {
  const PickingProducts({super.key});

  @override
  PickingProductsState createState() => PickingProductsState();
}

class PickingProductsState extends State<PickingProducts> {
  bool _isLoading = true;
  String? _error;
  int _currentLineIndex = 0;
  final List<PickingLinea> _processedLines = [];
  final Map<int, TextEditingController> _quantityControllers = {};
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  ScaffoldMessengerState? _scaffoldMessenger;
  late OrdenPicking _ordenPicking;

  @override
  void initState() {
    super.initState();
    _ordenPicking = context.read<ProductProvider>().ordenPickingInterna;
    _loadProductsForCurrentLine();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProductsForCurrentLine() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (_ordenPicking.lineas == null || _ordenPicking.lineas!.isEmpty) {
        setState(() {
          _error = 'No hay líneas para procesar';
          _isLoading = false;
        });
        return;
      }

      final currentLine = _ordenPicking.lineas![_currentLineIndex];

      setState(() {
        // Inicializar controladores para cada ubicación del producto
        for (int i = 0; i < currentLine.ubicaciones.length; i++) {
          _quantityControllers[i] = TextEditingController(text: '0');
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _scanBarcode() async {
    try {
      String? barcodeScanRes = await SimpleBarcodeScanner.scanBarcode(
        context,
        lineColor: '#ff6666',
        cancelButtonText: 'Cancelar',
        isShowFlashIcon: true,
        scanType: ScanType.barcode,
      );

      if (barcodeScanRes == '-1') return;

      final currentLine = _ordenPicking.lineas![_currentLineIndex];
      
      if (currentLine.codItem == barcodeScanRes) {
        _incrementProductQuantity(0); // Incrementa la primera ubicación por defecto
      } else {
        _showSingleSnackBar(
          'Producto no encontrado: $barcodeScanRes',
          backgroundColor: Colors.red
        );
      }
    } catch (e) {
      print('Error al escanear: $e');
    }
  }

  void _incrementProductQuantity(int index) {
    final currentLine = _ordenPicking.lineas![_currentLineIndex];
    final currentLocation = currentLine.ubicaciones[index];
    final currentQuantity = int.tryParse(_quantityControllers[index]?.text ?? '0') ?? 0;
    
    if (currentQuantity < currentLine.cantidadPedida) {
      setState(() {
        _quantityControllers[index]?.text = (currentQuantity + 1).toString();
      });
    } else {
      _showSingleSnackBar(
        'Ya has alcanzado la cantidad máxima para este producto',
        backgroundColor: Colors.orange
      );
    }
  }

  void _decrementProductQuantity(int index) {
    final currentQuantity = int.tryParse(_quantityControllers[index]?.text ?? '0') ?? 0;
    if (currentQuantity > 0) {
      setState(() {
        _quantityControllers[index]?.text = (currentQuantity - 1).toString();
      });
    }
  }

  void _updateProductQuantity(int index, String value) {
    final currentLine = _ordenPicking.lineas![_currentLineIndex];
    final newQuantity = int.tryParse(value) ?? 0;
    if (newQuantity >= 0 && newQuantity <= currentLine.cantidadPedida) {
      setState(() {
        _quantityControllers[index]?.text = value;
      });
    } else if (value.isNotEmpty) {
      _quantityControllers[index]?.text = '0';
    }
  }

  void _showSingleSnackBar(String message, {Color backgroundColor = Colors.green}) {
    _scaffoldMessenger?.hideCurrentSnackBar();
    _scaffoldMessenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      )
    );
  }

  bool _allProductsPickeadInLine() {
    final currentLine = _ordenPicking.lineas![_currentLineIndex];
    int totalPicked = 0;
    
    for (int i = 0; i < currentLine.ubicaciones.length; i++) {
      totalPicked += int.tryParse(_quantityControllers[i]?.text ?? '0') ?? 0;
    }
    
    return totalPicked == currentLine.cantidadPedida;
  }

  bool _hasMoreLines() {
    return _currentLineIndex < _ordenPicking.lineas!.length - 1;
  }

  void _moveToNextLine() {
    _saveProcessedLine();
    if (_hasMoreLines()) {
      setState(() {
        _currentLineIndex++;
        _quantityControllers.clear();
      });
      _loadProductsForCurrentLine();
    } else {
      _finishProcess();
    }
  }

  void _saveProcessedLine() {
    final currentLine = _ordenPicking.lineas![_currentLineIndex];
    // Actualizar las cantidades pickeadas en cada ubicación
    for (int i = 0; i < currentLine.ubicaciones.length; i++) {
      currentLine.ubicaciones[i].existenciaActual = int.tryParse(_quantityControllers[i]?.text ?? '0') ?? 0;
    }
    
    _processedLines.add(currentLine);
  }

  void _finishProcess() {
    if (_ordenPicking.lineas != null && _ordenPicking.lineas!.isNotEmpty) {
      _saveProcessedLine();
    }
    
    // Navegar al resumen con las líneas procesadas
    context.push(
      '/resumenPicking',
      extra: _processedLines,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text('Línea ${_currentLineIndex + 1} de ${_ordenPicking.lineas?.length ?? 0}', style: TextStyle(color: colors.onPrimary),),
          backgroundColor: colors.primary,
          iconTheme: IconThemeData(color: colors.onPrimary),
        ),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomBar(),
        floatingActionButton: FloatingActionButton(
          onPressed: _scanBarcode,
          tooltip: 'Escanear producto',
          child: const Icon(Icons.qr_code_scanner),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProductsForCurrentLine,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_ordenPicking.lineas == null || _ordenPicking.lineas!.isEmpty) {
      return const Center(
        child: Text('No hay productos para procesar'),
      );
    }

    final currentLine = _ordenPicking.lineas![_currentLineIndex];

    return Column(
      children: [
        Expanded(
          child: _buildProductInfo(currentLine),
        ),
        Expanded(
          child: _buildLocationList(currentLine),
        ),
      ],
    );
  }

  Widget _buildProductInfo(PickingLinea line) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              line.descripcion,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Código: ${line.codItem}'),
            Text('ID: ${line.itemId}'),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _calculateProgress(line),
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(height: 8),
            Text(
              '${_calculateTotalPicked(line)} / ${line.cantidadPedida}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _allProductsPickeadInLine() ? Colors.green : Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateProgress(PickingLinea line) {
    int totalPicked = _calculateTotalPicked(line);
    return totalPicked / line.cantidadPedida;
  }

  int _calculateTotalPicked(PickingLinea line) {
    int total = 0;
    for (int i = 0; i < line.ubicaciones.length; i++) {
      total += int.tryParse(_quantityControllers[i]?.text ?? '0') ?? 0;
    }
    return total;
  }

  Widget _buildLocationList(PickingLinea line) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ubicaciones disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: line.ubicaciones.length,
              itemBuilder: (context, index) {
                return _buildLocationListItem(line.ubicaciones[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationListItem(Ubicacione ubicacion, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ubicación ID: ${ubicacion.almacenUbicacionId}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Existencia: ${ubicacion.existenciaActual}'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () => _decrementProductQuantity(index),
                    ),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: _quantityControllers[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: (value) => _updateProductQuantity(index, value),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _incrementProductQuantity(index),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final bool isLastLine = !_hasMoreLines();
    final colors = Theme.of(context).colorScheme;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_allProductsPickeadInLine()) {
                  isLastLine ? _finishProcess() : _moveToNextLine();
                } else {
                  _showMissingProductsDialog(isLastLine);
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isLastLine ? Colors.green : colors.primary,
              ),
              child: Text(
                isLastLine ? 'Finalizar' : 'Siguiente Línea',
                style: TextStyle(fontSize: 16, color: colors.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMissingProductsDialog(bool isLastLine) {
    final currentLine = _ordenPicking.lineas![_currentLineIndex];
    final totalPicked = _calculateTotalPicked(currentLine);
    final missing = currentLine.cantidadPedida - totalPicked;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Productos faltantes'),
          content: Text('Faltan $missing unidades de ${currentLine.descripcion}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                isLastLine ? _finishProcess() : _moveToNextLine();
              },
              child: Text(isLastLine ? 'Finalizar' : 'Siguiente'),
            ),
          ],
        );
      },
    );
  }
}