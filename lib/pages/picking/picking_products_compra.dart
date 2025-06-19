import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/models/product.dart';
import 'package:deposito/models/ubicacion_almacen.dart';
import 'package:deposito/services/product_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:provider/provider.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/picking_services.dart';
import 'package:visibility_detector/visibility_detector.dart';

class PickingProductsEntrada extends StatefulWidget {
  const PickingProductsEntrada({super.key});

  @override
  PickingProductsEntradaState createState() => PickingProductsEntradaState();
}

class PickingProductsEntradaState extends State<PickingProductsEntrada> {
  bool _isLoading = true;
  String? _error;
  final Map<int, TextEditingController> _quantityControllers = {};
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  ScaffoldMessengerState? _scaffoldMessenger;
  FocusNode focoDeScanner = FocusNode();
  TextEditingController textController = TextEditingController();
  late UbicacionAlmacen ubicacionSeleccionada = UbicacionAlmacen.empty();
  late bool camera = false;

  @override
  void initState() {
    super.initState();
    _loadProductsForOrder();
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

  Future<void> _loadProductsForOrder() async {
    try {
      setState(() {
        focoDeScanner.requestFocus();
        _isLoading = true;
        _error = null;
      });

      final provider = Provider.of<ProductProvider>(context, listen: false);
      final ordenPicking = provider.ordenPickingInterna;
      ubicacionSeleccionada = provider.ubicacion;
      camera = provider.camera;

      if (ordenPicking.lineas == null || ordenPicking.lineas!.isEmpty) {
        setState(() {
          _error = 'No hay líneas para procesar';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        for (int i = 0; i < ordenPicking.lineas!.length; i++) {
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

  void _incrementProductQuantity(int index) {
    // final provider = Provider.of<ProductProvider>(context, listen: false);
    // final line = provider.ordenPickingInterna.lineas![index];
    final currentQuantity = int.tryParse(_quantityControllers[index]?.text ?? '0') ?? 0;
    
    setState(() {
      _quantityControllers[index]?.text = (currentQuantity + 1).toString();
    });
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
    final newQuantity = int.tryParse(value) ?? 0;
    if (newQuantity >= 0) {
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

  bool _allProductsPickead() {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final ordenPicking = provider.ordenPickingInterna;
    
    for (int i = 0; i < ordenPicking.lineas!.length; i++) {
      // final line = ordenPicking.lineas![i];
      final picked = int.tryParse(_quantityControllers[i]?.text ?? '0') ?? 0;
      if (picked <= 0) return false;
    }
    
    return true;
  }

  Future<void> _processOrderCompletion() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Guardar las líneas procesadas en el provider
      _saveProcessedOrder();
      
      // Navegar directamente al resumen
      final provider = Provider.of<ProductProvider>(context, listen: false);
      provider.setLineasPicking(provider.ordenPickingInterna.lineas ?? []);
      provider.clearUbicacionSeleccionada();
      
      Navigator.of(context).pop(); // Cerrar el diálogo de progreso
      
      // Navegar al resumen
      appRouter.push('/resumenPicking');
      
    } catch (e) {
      Navigator.of(context).pop(); // Cerrar el diálogo de progreso en caso de error
      _showSingleSnackBar('Error: ${e.toString()}', backgroundColor: Colors.red);
    }
  }

  _saveProcessedOrder() {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final ordenPicking = provider.ordenPickingInterna;
    
    for (int i = 0; i < ordenPicking.lineas!.length; i++) {
      final picked = int.tryParse(_quantityControllers[i]?.text ?? '0') ?? 0;
      
      final updatedLine = PickingLinea(
        pickLineaId: ordenPicking.lineas![i].pickLineaId,
        pickId: ordenPicking.lineas![i].pickId,
        lineaId: ordenPicking.lineas![i].lineaId,
        itemId: ordenPicking.lineas![i].itemId,
        cantidadPedida: ordenPicking.lineas![i].cantidadPedida,
        cantidadPickeada: picked,
        tipoLineaAdicional: ordenPicking.lineas![i].tipoLineaAdicional,
        lineaIdOriginal: ordenPicking.lineas![i].lineaIdOriginal,
        codItem: ordenPicking.lineas![i].codItem,
        descripcion: ordenPicking.lineas![i].descripcion,
        ubicaciones: List.from(ordenPicking.lineas![i].ubicaciones),
      );
      
      provider.updateLineaPicking(i, updatedLine);
      ordenPicking.lineas![i] = updatedLine;
    }
  }

  void _showMissingProductsDialog() {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final ordenPicking = provider.ordenPickingInterna;
    List<String> missingProducts = [];
    
    for (int i = 0; i < ordenPicking.lineas!.length; i++) {
      final picked = int.tryParse(_quantityControllers[i]?.text ?? '0') ?? 0;
      if (picked <= 0) {
        missingProducts.add(ordenPicking.lineas![i].descripcion);
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Productos faltantes'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Los siguientes productos no tienen cantidad asignada:'),
              const SizedBox(height: 8),
              ...missingProducts.map((product) => Text('- $product')),
              const SizedBox(height: 16),
              const Text('¿Deseas continuar de todos modos?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _processOrderCompletion();
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  double _calculateProgress(PickingLinea line, int index) {
    final picked = int.tryParse(_quantityControllers[index]?.text ?? '0') ?? 0;
    return picked / line.cantidadPedida;
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
                'Orden ${provider.ordenPickingInterna.numeroDocumento}',
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
              onPressed: _loadProductsForOrder,
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

        return Column(
          children: [
            Expanded(
              child: _buildProductList(ordenPicking),
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

  Widget _buildProductList(OrdenPicking ordenPicking) {
    return ListView.builder(
      itemCount: ordenPicking.lineas!.length,
      itemBuilder: (context, index) {
        final line = ordenPicking.lineas![index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
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
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _calculateProgress(line, index),
                  backgroundColor: Colors.grey[300],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${int.tryParse(_quantityControllers[index]?.text ?? '0')} / ${line.cantidadPedida}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: (int.tryParse(_quantityControllers[index]?.text ?? '0') ?? 0) > 0 ? 
                          Colors.green : Colors.blue,
                      ),
                    ),
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
      },
    );
  }

  Future<void> procesarEscaneoUbicacion(String value) async {
    if (value.isEmpty) return;
    late List<Product> productos = [];
    final provider = Provider.of<ProductProvider>(context, listen: false);
    
    try {

      productos = await ProductServices().getProductByName(
        context, '', '2', 
        provider.almacen.almacenId.toString(), 
        value,
        '0', 
        provider.token
      );
      
      if (productos.isNotEmpty) {
        final producto = productos[0];
        bool productoEncontrado = false;
        
        // Buscar el producto en las líneas de picking
        for (int i = 0; i < provider.ordenPickingInterna.lineas!.length; i++) {
          final line = provider.ordenPickingInterna.lineas![i];
          if (producto.raiz == line.codItem) {
            _incrementProductQuantity(i);
            productoEncontrado = true;
            
            // Hacer PATCH inmediatamente después de incrementar
            await _patchSingleLine(i, line, provider);
            break;
          }
        }
        
        if (!productoEncontrado) {
          _showSingleSnackBar(
            'Producto no encontrado en la orden: $value',
            backgroundColor: Colors.red
          );
        }
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

  Future<void> _patchSingleLine(int index, PickingLinea line, ProductProvider provider) async {
    try {
      final pickingServices = PickingServices();
      final cantidad = int.tryParse(_quantityControllers[index]?.text ?? '0') ?? 0;
      
      await pickingServices.patchPicking(
        context,
        line.pickId,
        line.codItem,
        provider.ubicacion.almacenUbicacionId,
        cantidad,
        line.pickLineaId,
        provider.token
      );
      
      // Actualizar la línea en el provider
      final updatedLine = PickingLinea(
        pickLineaId: line.pickLineaId,
        pickId: line.pickId,
        lineaId: line.lineaId,
        itemId: line.itemId,
        cantidadPedida: line.cantidadPedida,
        cantidadPickeada: cantidad,
        tipoLineaAdicional: line.tipoLineaAdicional,
        lineaIdOriginal: line.lineaIdOriginal,
        codItem: line.codItem,
        descripcion: line.descripcion,
        ubicaciones: List.from(line.ubicaciones),
      );
      
      provider.updateLineaPicking(index, updatedLine);
      
    } catch (e) {
      print('Error en patchSingleLine: $e');
      _showSingleSnackBar(
        'Error al actualizar la línea',
        backgroundColor: Colors.red
      );
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

      productos = await ProductServices().getProductByName(
        context, '', '2', 
        provider.almacen.almacenId.toString(), 
        barcodeScanRes.toString(), '0', 
        provider.token
      );
      
      if (productos.isNotEmpty) {
        final producto = productos[0];
        bool productoEncontrado = false;
        
        // Buscar el producto en las líneas de picking
        for (int i = 0; i < provider.ordenPickingInterna.lineas!.length; i++) {
          final line = provider.ordenPickingInterna.lineas![i];
          if (producto.raiz == line.codItem) {
            _incrementProductQuantity(i);
            productoEncontrado = true;

            await _patchSingleLine(i, line, provider);
            break;
          }
        }
        
        if (!productoEncontrado) {
          _showSingleSnackBar(
            'Producto no encontrado en la orden: $barcodeScanRes',
            backgroundColor: Colors.red
          );
        }
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

  Widget _buildBottomBar() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: colors.primary,
              ),
              child: Text(
                'Cambiar ubicación',
                style: TextStyle(fontSize: 16, color: colors.onPrimary),
              ),
            ),
          ),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_allProductsPickead()) {
                  _processOrderCompletion();
                } else {
                  _showMissingProductsDialog();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: colors.primary,
              ),
              child: Text(
                'Finalizar Recepción',
                style: TextStyle(fontSize: 16, color: colors.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(ColorScheme colors) {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: colors.primary,
      foregroundColor: Colors.white,
      children: [
        if(camera)
        SpeedDialChild(
          child: const Icon(Icons.qr_code_scanner_outlined),
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          label: 'Escanear',
          onTap: _scanBarcode,
        ),
        SpeedDialChild(
          child: const Icon(Icons.restore),
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          label: 'Reiniciar',
          onTap: _resetSearch,
        ),
      ],
    );
  }

  void _resetSearch() {
    textController.clear();
    focoDeScanner.requestFocus();
    setState(() {});
  }
}