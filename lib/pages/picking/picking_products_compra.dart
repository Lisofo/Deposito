import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/models/product.dart';
import 'package:deposito/models/ubicacion_almacen.dart';
import 'package:deposito/models/ubicacion_picking.dart';
import 'package:deposito/services/product_services.dart';
import 'package:deposito/widgets/custom_speed_dial.dart';
import 'package:deposito/widgets/escaner_pda.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:provider/provider.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/picking_services.dart';

class PickingProductsEntrada extends StatefulWidget {
  const PickingProductsEntrada({super.key});

  @override
  PickingProductsEntradaState createState() => PickingProductsEntradaState();
}

class PickingProductsEntradaState extends State<PickingProductsEntrada> {
  bool _isLoading = true;
  String? _error;
  final Map<int, TextEditingController> _quantityControllers = {};
  final Map<int, int> _previousQuantities = {};
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  ScaffoldMessengerState? _scaffoldMessenger;
  FocusNode focoDeScanner = FocusNode();
  TextEditingController textController = TextEditingController();
  late UbicacionAlmacen ubicacionSeleccionada = UbicacionAlmacen.empty();
  late bool camera = false;
  bool _isPatching = false;

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
    focoDeScanner.dispose();
    textController.dispose();
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
          _quantityControllers[i] = TextEditingController(
            text: ordenPicking.lineas![i].cantidadPickeada.toString()
          );
          _previousQuantities[i] = ordenPicking.lineas![i].cantidadPickeada;
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

  void _incrementProductQuantity(int index) async {
    if (_isPatching) return;
    
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final currentLine = provider.ordenPickingInterna.lineas![index];
    final currentQuantity = int.tryParse(_quantityControllers[index]?.text ?? '0') ?? 0;
    
    if (currentQuantity < currentLine.cantidadPedida) {
      setState(() {
        _quantityControllers[index]?.text = (currentQuantity + 1).toString();
      });
      
      final success = await _patchSingleLine(index, currentQuantity + 1);
      if (!success) {
        _showSingleSnackBar('Error al actualizar la cantidad', backgroundColor: Colors.red);
        setState(() {
          _quantityControllers[index]?.text = currentLine.cantidadPickeada.toString();
        });
      }
    } else {
      _showSingleSnackBar(
        'Ya has alcanzado la cantidad máxima para este producto',
        backgroundColor: Colors.orange
      );
    }
  }

  void _decrementProductQuantity(int index) async {
    if (_isPatching) return;
    
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final currentLine = provider.ordenPickingInterna.lineas![index];
    final currentQuantity = int.tryParse(_quantityControllers[index]?.text ?? '0') ?? 0;
    if (currentQuantity > 0) {
      setState(() {
        _quantityControllers[index]?.text = (currentQuantity - 1).toString();
      });
      
      final success = await _patchSingleLine(index, currentQuantity - 1);
      if (!success) {
        _showSingleSnackBar('Error al actualizar la cantidad', backgroundColor: Colors.red);
        setState(() {
          _quantityControllers[index]?.text = currentLine.cantidadPickeada.toString();
        });
      }
    }
  }

  void _updateProductQuantity(int index, String value) async {
    if (_isPatching) return;
    
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final currentLine = provider.ordenPickingInterna.lineas![index];
    final newQuantity = int.tryParse(value) ?? 0;
    
    if (newQuantity >= 0 && newQuantity <= currentLine.cantidadPedida) {
      setState(() {
        _quantityControllers[index]?.text = value;
      });
      
      if (focoDeScanner.hasFocus) {
        final success = await _patchSingleLine(index, newQuantity);
        if (!success) {
          _showSingleSnackBar('Error al actualizar la cantidad', backgroundColor: Colors.red);
          setState(() {
            _quantityControllers[index]?.text = _previousQuantities[index].toString();
          });
        }
      }
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
      _saveProcessedOrder();
      
      final provider = Provider.of<ProductProvider>(context, listen: false);
      provider.setLineasPicking(provider.ordenPickingInterna.lineas ?? []);
      provider.clearUbicacionSeleccionada();
      
      Navigator.of(context).pop();
      appRouter.push('/resumenPicking');
      
    } catch (e) {
      Navigator.of(context).pop();
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
        fotosUrl: ordenPicking.lineas![i].fotosUrl,
        ubicaciones: List.from(ordenPicking.lineas![i].ubicaciones),
      );
      
      provider.updateLineaPicking(i, updatedLine);
      ordenPicking.lineas![i] = updatedLine;
      _previousQuantities[i] = picked;
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

  Future<bool> _patchSingleLine(int index, int newQuantity) async {
    if (_isPatching) return false;

    setState(() {
      _isPatching = true;
    });

    try {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      final pickingServices = PickingServices();
      final line = provider.ordenPickingInterna.lineas![index];
      final diferencia = newQuantity - (_previousQuantities[index] ?? 0);
      
      final response = await pickingServices.patchPicking(
        context,
        line.pickId,
        line.codItem,
        provider.ubicacion.almacenUbicacionId,
        line.pickLineaId,
        provider.token,
        diferencia: diferencia,
      );

      // Actualizar con la respuesta del servidor
      final cantidadPickeadaActualizada = response['cantidadPickeada'];
      
      // Actualizar la línea localmente
      final updatedLine = PickingLinea(
        pickLineaId: line.pickLineaId,
        pickId: line.pickId,
        lineaId: line.lineaId,
        itemId: line.itemId,
        cantidadPedida: line.cantidadPedida,
        cantidadPickeada: cantidadPickeadaActualizada,
        tipoLineaAdicional: line.tipoLineaAdicional,
        lineaIdOriginal: line.lineaIdOriginal,
        codItem: line.codItem,
        descripcion: line.descripcion,
        fotosUrl: line.fotosUrl,
        ubicaciones: List.from(line.ubicaciones),
      );
      
      // Actualizar en el provider y en el estado local
      provider.updateLineaPicking(index, updatedLine);
      provider.ordenPickingInterna.lineas![index] = updatedLine;
      _previousQuantities[index] = cantidadPickeadaActualizada;
      
      // Registrar la ubicación donde se guardó
      final ubicacionPicking = UbicacionPicking(
        codUbicacion: provider.ubicacion.codUbicacion,
        cantidadPickeada: diferencia,
        existenciaActual: response['existenciaActual'] ?? 0,
      );
      
      provider.agregarUbicacionPicking(line.pickLineaId, ubicacionPicking);

      // Actualizar el controlador de texto para reflejar el cambio
      if (_quantityControllers[index]?.text != cantidadPickeadaActualizada.toString()) {
        _quantityControllers[index]?.text = cantidadPickeadaActualizada.toString();
      }

      return true;
    } catch (e) {
      print('Error en patchSingleLine: $e');
      return false;
    } finally {
      setState(() {
        _isPatching = false;
      });
    }
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
            EscanerPDA(
              onScan: procesarEscaneoUbicacion,
              focusNode: focoDeScanner,
              controller: textController
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
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      '${int.tryParse(_quantityControllers[index]?.text ?? '0') ?? 0} / ${line.cantidadPedida}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: (int.tryParse(_quantityControllers[index]?.text ?? '0') ?? 0) > 0 ? 
                          Colors.green : Colors.blue,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _isPatching ? null : () => _decrementProductQuantity(index),
                        ),
                        SizedBox(
                          width: 60,
                          child: AbsorbPointer(
                            absorbing: _isPatching,
                            child: TextField(
                              controller: _quantityControllers[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              enabled: !_isPatching,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                              ),
                              onChanged: (value) => _updateProductQuantity(index, value),
                              onEditingComplete: () async {
                                if (_isPatching) return;
                                
                                final newQuantity = int.tryParse(_quantityControllers[index]?.text ?? '0') ?? 0;
                                if (newQuantity != _previousQuantities[index]) {
                                  final success = await _patchSingleLine(index, newQuantity);
                                  if (!success) {
                                    setState(() {
                                      _quantityControllers[index]?.text = _previousQuantities[index].toString();
                                    });
                                  }
                                }
                                FocusScope.of(context).requestFocus(focoDeScanner);
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _isPatching ? null : () => _incrementProductQuantity(index),
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
    if (_isPatching || value.isEmpty) return;
    
    late List<Product> productos = [];
    final provider = Provider.of<ProductProvider>(context, listen: false);
    
    try {
      var trimmedValue = value.trim();
      productos = await ProductServices().getProductByName(
        context, '', '2', 
        provider.almacen.almacenId.toString(), 
        trimmedValue, '0', 
        provider.token
      );
      
      if (productos.isNotEmpty) {
        final producto = productos[0];
        bool productoEncontrado = false;
        
        for (int i = 0; i < provider.ordenPickingInterna.lineas!.length; i++) {
          final line = provider.ordenPickingInterna.lineas![i];
          if (producto.raiz == line.codItem) {
            final currentQuantity = int.tryParse(_quantityControllers[i]?.text ?? '0') ?? 0;
            final newQuantity = currentQuantity + 1;
            
            setState(() {
              _quantityControllers[i]?.text = newQuantity.toString();
            });
            
            final success = await _patchSingleLine(i, newQuantity);
            if (!success) {
              _showSingleSnackBar('Error al registrar el producto', backgroundColor: Colors.red);
              setState(() {
                _quantityControllers[i]?.text = currentQuantity.toString();
              });
            } else {
              _showSingleSnackBar('Producto registrado correctamente');
            }

            productoEncontrado = true;
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

  Future<void> _scanBarcode() async {
    if (_isPatching) return;
    
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
        
        for (int i = 0; i < provider.ordenPickingInterna.lineas!.length; i++) {
          final line = provider.ordenPickingInterna.lineas![i];
          if (producto.raiz == line.codItem) {
            final currentQuantity = int.tryParse(_quantityControllers[i]?.text ?? '0') ?? 0;
            final newQuantity = currentQuantity + 1;
            
            setState(() {
              _quantityControllers[i]?.text = newQuantity.toString();
            });
            
            final success = await _patchSingleLine(i, newQuantity);
            if (!success) {
              _showSingleSnackBar('Error al registrar el producto', backgroundColor: Colors.red);
              setState(() {
                _quantityControllers[i]?.text = currentQuantity.toString();
              });
            } else {
              _showSingleSnackBar('Producto registrado correctamente');
            }

            productoEncontrado = true;
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