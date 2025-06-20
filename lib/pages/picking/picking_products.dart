// picking_products.dart (cambios completos)

import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/models/product.dart';
import 'package:deposito/services/product_services.dart';
import 'package:deposito/widgets/custom_speed_dial.dart';
import 'package:flutter/material.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:provider/provider.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/picking_services.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'resumen_picking.dart';

class PickingProducts extends StatefulWidget {
  const PickingProducts({super.key});

  @override
  PickingProductsState createState() => PickingProductsState();
}

class PickingProductsState extends State<PickingProducts> {
  bool _isLoading = true;
  String? _error;
  final Map<int, TextEditingController> _quantityControllers = {};
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  ScaffoldMessengerState? _scaffoldMessenger;
  FocusNode focoDeScanner = FocusNode();
  TextEditingController textController = TextEditingController();
  late bool camera = false;

  @override
  void initState() {
    super.initState();
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
        focoDeScanner.requestFocus();
        _isLoading = true;
        _error = null;
      });

      final provider = Provider.of<ProductProvider>(context, listen: false);
      final ordenPicking = provider.ordenPickingInterna;
      camera = provider.camera;
      if (ordenPicking.lineas == null || ordenPicking.lineas!.isEmpty) {
        setState(() {
          _error = 'No hay líneas para procesar';
          _isLoading = false;
        });
        return;
      }

      final currentLineIndex = provider.currentLineIndex;
      final currentLine = ordenPicking.lineas![currentLineIndex];

      setState(() {
        for (int i = 0; i < currentLine.ubicaciones.length; i++) {
          _quantityControllers[i] = TextEditingController(text: currentLine.cantidadPickeada.toString());
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

  Future<bool> _patchCurrentLine() async {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final pickingServices = PickingServices();
    final token = provider.token;
    final currentLine = provider.ordenPickingInterna.lineas![provider.currentLineIndex];
    final ubicacionSeleccionada = provider.ubicacionSeleccionada!;

    try {
      // 1. Ejecutar el PATCH y obtener la respuesta
      final response = await pickingServices.patchPicking(
        context,
        currentLine.pickId,
        currentLine.codItem,
        ubicacionSeleccionada.almacenUbicacionId,
        currentLine.cantidadPickeada,
        currentLine.pickLineaId,
        token
      );

      // 2. Extraer la nueva existenciaActual de la respuesta
      final nuevaExistencia = response['ubicaciones']
          .firstWhere((u) => u['almacenUbicacionId'] == ubicacionSeleccionada.almacenUbicacionId)
          ['existenciaActual'];

      // 3. Actualizar TODAS las ubicaciones con el mismo itemAlmacenUbicacionId
      _actualizarExistenciasEnTodasLasLineas(
        provider,
        ubicacionSeleccionada.itemAlmacenUbicacionId,
        nuevaExistencia
      );

      return true;
    } catch (e) {
      print('Error en patchCurrentLine: $e');
      return false;
    }
  }

  void _actualizarExistenciasEnTodasLasLineas(
    ProductProvider provider,
    int itemAlmacenUbicacionId,
    int nuevaExistencia
  ) {
    // Actualizar en ordenPickingInterna
    provider.ordenPickingInterna.lineas?.forEach((linea) {
      for (var ubicacion in linea.ubicaciones) {
        if (ubicacion.itemAlmacenUbicacionId == itemAlmacenUbicacionId) {
          ubicacion.existenciaActual = nuevaExistencia;
        }
      }
    });

    // Actualizar en lineasPicking
    for (var linea in provider.lineasPicking) {
      for (var ubicacion in linea.ubicaciones) {
        if (ubicacion.itemAlmacenUbicacionId == itemAlmacenUbicacionId) {
          ubicacion.existenciaActual = nuevaExistencia;
        }
      }
    }

    // Actualizar la ubicación seleccionada si corresponde
    if (provider.ubicacionSeleccionada?.itemAlmacenUbicacionId == itemAlmacenUbicacionId) {
      provider.ubicacionSeleccionada?.existenciaActual = nuevaExistencia;
    }

    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    provider.notifyListeners();
  }

  void _incrementProductQuantity(int index) {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final currentLine = provider.ordenPickingInterna.lineas![provider.currentLineIndex];
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
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final currentLine = provider.ordenPickingInterna.lineas![provider.currentLineIndex];
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
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final currentLine = provider.ordenPickingInterna.lineas![provider.currentLineIndex];
    int totalPicked = 0;
    
    for (int i = 0; i < currentLine.ubicaciones.length; i++) {
      totalPicked += int.tryParse(_quantityControllers[i]?.text ?? '0') ?? 0;
    }
    
    return totalPicked == currentLine.cantidadPedida;
  }

  bool _hasMoreLines() {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    return provider.currentLineIndex < provider.ordenPickingInterna.lineas!.length - 1;
  }

  Future<bool> _completeCurrentLine() async {
    try {
      _saveProcessedLine();
      return await _patchCurrentLine();
    } catch (e) {
      print('Error completando línea: $e');
      return false;
    }
  }

  Future<void> _processLineCompletion(bool isLastLine) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await _completeCurrentLine();
      
      Navigator.of(context).pop(); // Cerrar el diálogo de progreso
      
      if (!success) {
        _showSingleSnackBar('Error al actualizar la línea', backgroundColor: Colors.red);
        return;
      }

      final provider = Provider.of<ProductProvider>(context, listen: false);
      provider.clearUbicacionSeleccionada();

      if (isLastLine) {
        _navigateToSummary();
      } else {
        if (provider.modoSeleccionUbicacion) {
          // Modo automático
          final nextLineIndex = provider.currentLineIndex + 1;
          final nextLine = provider.ordenPickingInterna.lineas![nextLineIndex];
          
          if (nextLine.ubicaciones.isNotEmpty) {
            provider.setCurrentLineIndex(nextLineIndex);
            appRouter.pushReplacement('/pickingProductos');
          } else {
            _handleLineWithoutLocations(provider);
          }
        } else {
          // Modo manual - volver a pickingInterno
          Navigator.of(context).popUntil((route) => route.settings.name == '/pickingInterno');
          appRouter.pushReplacement('/pickingInterno');
        }
      }
    } catch (e) {
      Navigator.of(context).pop(); // Cerrar el diálogo de progreso en caso de error
      _showSingleSnackBar('Error: ${e.toString()}', backgroundColor: Colors.red);
    }
  }

  void _handleLineWithoutLocations(ProductProvider provider) {
    final nextLineIndex = provider.currentLineIndex + 1;
    final isLastLine = nextLineIndex >= provider.ordenPickingInterna.lineas!.length - 1;
    
    if (isLastLine) {
      _navigateToSummary();
    } else {
      provider.setCurrentLineIndex(nextLineIndex);
      Navigator.of(context).popUntil((route) => route.settings.name == '/pickingInterno');
      appRouter.pushReplacement('/pickingInterno');
    }
  }

  void _navigateToSummary() {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final ordenPicking = provider.ordenPickingInterna;
    
    for (int i = 0; i < ordenPicking.lineas!.length; i++) {
      if (i >= provider.lineasPicking.length) {
        provider.lineasPicking.add(ordenPicking.lineas![i]);
      }
    }
    
    provider.clearUbicacionSeleccionada();
    provider.setCurrentLineIndex(0);
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SummaryScreen(processedLines: provider.lineasPicking),
      )
    );
  }

  _saveProcessedLine() {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final currentLine = provider.ordenPickingInterna.lineas![provider.currentLineIndex];
    int totalPicked = 0;
    
    for (int i = 0; i < currentLine.ubicaciones.length; i++) {
      final picked = int.tryParse(_quantityControllers[i]?.text ?? '0') ?? 0;
      totalPicked += picked;
    }
    
    final updatedLine = PickingLinea(
      pickLineaId: currentLine.pickLineaId,
      pickId: currentLine.pickId,
      lineaId: currentLine.lineaId,
      itemId: currentLine.itemId,
      cantidadPedida: currentLine.cantidadPedida,
      cantidadPickeada: totalPicked,
      tipoLineaAdicional: currentLine.tipoLineaAdicional,
      lineaIdOriginal: currentLine.lineaIdOriginal,
      codItem: currentLine.codItem,
      descripcion: currentLine.descripcion,
      ubicaciones: List.from(currentLine.ubicaciones),
    );
    
    provider.updateLineaPicking(provider.currentLineIndex, updatedLine);
    provider.ordenPickingInterna.lineas![provider.currentLineIndex] = updatedLine;
  }

  void _showMissingProductsDialog(bool isLastLine) {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final currentLine = provider.ordenPickingInterna.lineas![provider.currentLineIndex];
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
                _processLineCompletion(isLastLine && provider.modoSeleccionUbicacion);
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Consumer<ProductProvider>(
            builder: (context, provider, child) {
              return Text(
                'Línea ${provider.currentLineIndex + 1} de ${provider.ordenPickingInterna.lineas?.length ?? 0}', 
                style: TextStyle(color: colors.onPrimary),
              );
            },
          ),
          backgroundColor: colors.primary,
          iconTheme: IconThemeData(color: colors.onPrimary),
        ),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomBar(),
        floatingActionButton: _buildFloatingActionButton(colors)
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

    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        final ordenPicking = provider.ordenPickingInterna;
        if (ordenPicking.lineas == null || ordenPicking.lineas!.isEmpty) {
          return const Center(
            child: Text('No hay productos para procesar'),
          );
        }
        final currentLineIndex = provider.currentLineIndex;
        // Validar índice
        if (currentLineIndex < 0 || currentLineIndex >= ordenPicking.lineas!.length) {
          return const Center(child: Text('Error: Índice de línea inválido'));
        }
        final currentLine = ordenPicking.lineas![currentLineIndex];

        return Column(
          children: [
            Expanded(
              child: _buildProductInfo(currentLine),
            ),
            Expanded(
              child: _buildLocationList(currentLine),
            ),
            VisibilityDetector(
              key: const Key('scanner-field-visibility'),
              onVisibilityChanged: (info) {
                if (info.visibleFraction > 0) {
                  focoDeScanner.requestFocus();
                }
              },
              child: TextFormField(
                focusNode: focoDeScanner,
                cursorColor: Colors.transparent,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(borderSide: BorderSide.none),
                ),
                style: const TextStyle(color: Colors.transparent),
                autofocus: true,
                keyboardType: TextInputType.none,
                controller: textController,
                onFieldSubmitted: procesarEscaneoUbicacion,
              ),
            ),
          ],
        );
      },
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
                fontSize: 16,
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

  Future<void> procesarEscaneoUbicacion(String value) async {
    if (value.isEmpty) return;
    late List<Product> productos = [];
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final ordenPicking = provider.ordenPickingInterna;
    final lineas = ordenPicking.lineas ?? [];
    final currentLineIndex = provider.currentLineIndex;
    
    if (currentLineIndex >= lineas.length) return;
    try {
      var trimmedValue = value.trim();
      final currentLine = provider.ordenPickingInterna.lineas![provider.currentLineIndex];
      productos = await ProductServices().getProductByName(context, '', '2', provider.almacen.almacenId.toString(), trimmedValue, '0', provider.token);
      final producto = productos[0];
      bool mismoProducto = producto.raiz == currentLine.codItem;
      
      if(provider.ubicacionSeleccionada?.existenciaActual == 0) return;

      if (mismoProducto) {
        _incrementProductQuantity(0);
        
      } else {
        _showSingleSnackBar(
          'Producto no encontrado: $value',
          backgroundColor: Colors.red
        );
      }
      textController.clear();
      focoDeScanner.requestFocus();
    } catch (e) {
      print('Error al escanear: $e');
      textController.clear();
      focoDeScanner.requestFocus();
    }
  }

  Future<void> _scanBarcode() async {
    late List<Product> productos = [];
    final provider = Provider.of<ProductProvider>(context, listen: false);
    try {
      String? barcodeScanRes = await SimpleBarcodeScanner.scanBarcode(
        context,
        lineColor: '#ff6666',
        cancelButtonText: 'Cancelar',
        isShowFlashIcon: true,
        scanType: ScanType.barcode,
      );

      if (barcodeScanRes == '-1') return;

      final currentLine = provider.ordenPickingInterna.lineas![provider.currentLineIndex];
      productos = await ProductServices().getProductByName(context, '', '2', provider.almacen.almacenId.toString(), barcodeScanRes.toString(), '0', provider.token);
      final producto = productos[0];
      bool mismoProducto = producto.raiz == currentLine.codItem;

      if(provider.ubicacionSeleccionada?.existenciaActual == 0) return;

      if (mismoProducto) {
        _incrementProductQuantity(0);
        
      } else {
        _showSingleSnackBar(
          'Producto no encontrado: $barcodeScanRes',
          backgroundColor: Colors.red
        );
      }
      focoDeScanner.requestFocus();
    } catch (e) {
      print('Error al escanear: $e');
      focoDeScanner.requestFocus();
    }
  }

  Widget _buildLocationList(PickingLinea line) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        final ubicacion = provider.ubicacionSeleccionada;
        
        if (ubicacion == null) {
          return const Center(child: Text('No hay ubicación seleccionada'));
        }

        // Mostrar advertencia si no hay stock
        if (ubicacion.existenciaActual == 0) {
          return const Center(
            child: Text(
              '⚠️ Ubicación sin stock disponible',
              style: TextStyle(color: Colors.red, fontSize: 18),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ubicación seleccionada', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              _buildLocationListItem(ubicacion, 0, line),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationListItem(UbicacionePicking ubicacion, int index, PickingLinea line) {
    print(ubicacion.existenciaActual);
    print(line.cantidadPedida);

    return Card(
      // margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ubicación: ${ubicacion.codUbicacion}',
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
                      onPressed: ubicacion.existenciaActual == 0 ? null : () => _decrementProductQuantity(index),
                    ),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        enabled: ubicacion.existenciaActual == 0 ? false : true,
                        controller: _quantityControllers[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: ubicacion.existenciaActual == 0 ? null : (value) => _updateProductQuantity(index, value), 
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: ubicacion.existenciaActual == 0 ? null : () => _incrementProductQuantity(index),
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
    final colors = Theme.of(context).colorScheme;
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        final bool isLastLine = !_hasMoreLines();
        final bool mostrarFinalizar = isLastLine && provider.modoSeleccionUbicacion;
        
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_allProductsPickeadInLine()) {
                      _processLineCompletion(mostrarFinalizar);
                    } else {
                      _showMissingProductsDialog(mostrarFinalizar);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: mostrarFinalizar ? Colors.green : colors.primary,
                  ),
                  child: Text(
                    mostrarFinalizar ? 'Finalizar' : 'Siguiente Línea',
                    style: TextStyle(fontSize: 16, color: colors.onPrimary),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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

  void _resetSearch() {
    textController.clear();
    focoDeScanner.requestFocus();
    setState(() {});
  }
}