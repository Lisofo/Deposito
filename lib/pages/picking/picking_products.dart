// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/models/product.dart';
import 'package:deposito/services/product_services.dart';
import 'package:deposito/widgets/custom_speed_dial.dart';
import 'package:deposito/widgets/escaner_pda.dart';
import 'package:flutter/material.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:provider/provider.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/picking_services.dart';
import 'resumen_picking.dart';

class PickingProducts extends StatefulWidget {
  const PickingProducts({super.key});

  @override
  PickingProductsState createState() => PickingProductsState();
}

class PickingProductsState extends State<PickingProducts> {
  bool _isLoading = true;
  String? _error;
  final TextEditingController _quantityController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  ScaffoldMessengerState? _scaffoldMessenger;
  FocusNode focoDeScanner = FocusNode();
  TextEditingController textController = TextEditingController();
  late bool camera = false;
  int _previousQuantity = 0;
  bool _isPatching = false;

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
    _quantityController.dispose();
    textController.dispose();
    focoDeScanner.dispose();
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
        _quantityController.text = currentLine.cantidadPickeada.toString();
        _previousQuantity = currentLine.cantidadPickeada;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _actualizarExistenciasEnTodasLasLineas(
    ProductProvider provider,
    int itemAlmacenUbicacionId,
    int nuevaExistencia
  ) {
    provider.ordenPickingInterna.lineas?.forEach((linea) {
      for (var ubicacion in linea.ubicaciones) {
        if (ubicacion.itemAlmacenUbicacionId == itemAlmacenUbicacionId) {
          ubicacion.existenciaActual = nuevaExistencia;
        }
      }
    });

    for (var linea in provider.lineasPicking) {
      for (var ubicacion in linea.ubicaciones) {
        if (ubicacion.itemAlmacenUbicacionId == itemAlmacenUbicacionId) {
          ubicacion.existenciaActual = nuevaExistencia;
        }
      }
    }

    if (provider.ubicacionSeleccionada?.itemAlmacenUbicacionId == itemAlmacenUbicacionId) {
      provider.ubicacionSeleccionada?.existenciaActual = nuevaExistencia;
    }

    provider.notifyListeners();
  }

  void _incrementProductQuantity() async {
    if (_isPatching) return;
    
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final currentLine = provider.ordenPickingInterna.lineas![provider.currentLineIndex];
    final currentQuantity = int.tryParse(_quantityController.text) ?? 0;
    
    if (currentQuantity < currentLine.cantidadPedida) {
      setState(() {
        _quantityController.text = (currentQuantity + 1).toString();
      });
      
      final success = await _patchCurrentLine();
      if (!success) {
        _showSingleSnackBar('Error al actualizar la cantidad', backgroundColor: Colors.red);
        setState(() {
          _quantityController.text = currentLine.cantidadPickeada.toString();
        });
      }
    } else {
      _showSingleSnackBar(
        'Ya has alcanzado la cantidad máxima para este producto',
        backgroundColor: Colors.orange
      );
    }
  }

  void _decrementProductQuantity() async {
    if (_isPatching) return;
    
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final currentLine = provider.ordenPickingInterna.lineas![provider.currentLineIndex];
    final currentQuantity = int.tryParse(_quantityController.text) ?? 0;
    if (currentQuantity > 0) {
      setState(() {
        _quantityController.text = (currentQuantity - 1).toString();
      });
      
      final success = await _patchCurrentLine();
      if (!success) {
        _showSingleSnackBar('Error al actualizar la cantidad', backgroundColor: Colors.red);
        setState(() {
          _quantityController.text = currentLine.cantidadPickeada.toString();
        });
      }
    }
  }

  void _updateProductQuantity(String value) async {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final currentLine = provider.ordenPickingInterna.lineas![provider.currentLineIndex];
    final newQuantity = int.tryParse(value) ?? 0;
    
    if (newQuantity >= 0 && newQuantity <= currentLine.cantidadPedida) {
      setState(() {
        _quantityController.text = value;
      });
      
      if (focoDeScanner.hasFocus) {
        final success = await _patchCurrentLine();
        if (!success) {
          _showSingleSnackBar('Error al actualizar la cantidad', backgroundColor: Colors.red);
          setState(() {
            _quantityController.text = currentLine.cantidadPickeada.toString();
          });
        }
      }
    } else if (value.isNotEmpty) {
      _quantityController.text = '0';
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
    final totalPicked = int.tryParse(_quantityController.text) ?? 0;
    
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
      
      Navigator.of(context).pop();
      
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
          final nextLineIndex = provider.currentLineIndex + 1;
          final nextLine = provider.ordenPickingInterna.lineas![nextLineIndex];
          
          if (nextLine.ubicaciones.isNotEmpty) {
            provider.setCurrentLineIndex(nextLineIndex);
            appRouter.pushReplacement('/pickingProductos');
          } else {
            _handleLineWithoutLocations(provider);
          }
        } else {
          Navigator.of(context).popUntil((route) => route.settings.name == '/pickingInterno');
          appRouter.pushReplacement('/pickingInterno');
        }
      }
    } catch (e) {
      Navigator.of(context).pop();
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
    final totalPicked = int.tryParse(_quantityController.text) ?? 0;
    
    final updatedLine = PickingLinea(
      pickLineaId: currentLine.pickLineaId,
      pickId: currentLine.pickId,
      lineaId: currentLine.lineaId,
      itemId: currentLine.itemId,
      cantidadPedida: currentLine.cantidadPedida,
      cantidadPickeada: totalPicked,
      cantidadVerificada: currentLine.cantidadVerificada,
      tipoLineaAdicional: currentLine.tipoLineaAdicional,
      lineaIdOriginal: currentLine.lineaIdOriginal,
      codItem: currentLine.codItem,
      descripcion: currentLine.descripcion,
      fotosUrl: currentLine.fotosUrl,
      ubicaciones: List.from(currentLine.ubicaciones),
    );
    
    provider.updateLineaPicking(provider.currentLineIndex, updatedLine);
    provider.ordenPickingInterna.lineas![provider.currentLineIndex] = updatedLine;
  }

  void _showMissingProductsDialog(bool isLastLine) {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final currentLine = provider.ordenPickingInterna.lineas![provider.currentLineIndex];
    final totalPicked = int.tryParse(_quantityController.text) ?? 0;
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
    int totalPicked = int.tryParse(_quantityController.text) ?? 0;
    return totalPicked / line.cantidadPedida;
  }

  Future<bool> _patchCurrentLine() async {
    if (_isPatching) return false;

    setState(() {
      _isPatching = true;
    });

    final provider = Provider.of<ProductProvider>(context, listen: false);
    final pickingServices = PickingServices();
    final token = provider.token;
    final currentLine = provider.ordenPickingInterna.lineas![provider.currentLineIndex];
    final ubicacionSeleccionada = provider.ubicacionSeleccionada!;

    try {
      final newQuantity = int.tryParse(_quantityController.text) ?? 0;
      final diferencia = newQuantity - _previousQuantity;
      
      final response = await pickingServices.patchPicking(
        context,
        currentLine.pickId,
        currentLine.codItem,
        ubicacionSeleccionada.almacenUbicacionId,
        currentLine.pickLineaId,
        token,
        diferencia: diferencia,
      );

      // Solo actualizamos currentLine.cantidadPickeada con la respuesta del servidor
      // pero mantenemos el incremento de 1 en la interfaz
      currentLine.cantidadPickeada = response['cantidadPickeada'];
      _previousQuantity = currentLine.cantidadPickeada;

      final updatedOrder = await pickingServices.getLineasOrder(
        context, 
        currentLine.pickId, 
        provider.almacen.almacenId, 
        token
      );
      
      provider.setOrdenPickingInterna(updatedOrder);

      final nuevaExistencia = response['ubicaciones']
          .firstWhere((u) => u['almacenUbicacionId'] == ubicacionSeleccionada.almacenUbicacionId)
          ['existenciaActual'];

      _actualizarExistenciasEnTodasLasLineas(
        provider,
        ubicacionSeleccionada.itemAlmacenUbicacionId,
        nuevaExistencia
      );

      _saveProcessedLine();

      return true;
    } catch (e) {
      print('Error en patchCurrentLine: $e');
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
                'Línea ${provider.currentLineIndex + 1} de ${provider.ordenPickingInterna.lineas?.length ?? 0}', 
                style: TextStyle(color: colors.onPrimary),
              );
            },
          ),
          backgroundColor: colors.primary,
          iconTheme: IconThemeData(color: colors.onPrimary),
          actions: [
            Consumer<ProductProvider>(
              builder: (context, provider, _) {
                final currentLine = provider.ordenPickingInterna.lineas?[provider.currentLineIndex];
                final hasPhoto = currentLine?.fotosUrl != null && currentLine!.fotosUrl.isNotEmpty;
                
                return IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: hasPhoto ? () => _showProductPhotoPopup(currentLine.fotosUrl) : null,
                );
              },
            ),
          ],
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

  Widget _buildProductInfo(PickingLinea line) {
    return Card(
      color: _allProductsPickeadInLine() ? Colors.green.shade500 : (line.cantidadPickeada < line.cantidadPedida && line.cantidadPickeada > 0) ? Colors.yellow.shade300 : Colors.white,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Columna de información del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    line.descripcion,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Código: ${line.codItem}'),
                  const SizedBox(height: 16),
                  
                  // LinearProgressIndicator con constraints explícitas
                  Container(
                    width: double.infinity, // O un valor fijo si prefieres
                    constraints: const BoxConstraints(minHeight: 4, maxHeight: 8),
                    child: LinearProgressIndicator(
                      value: _calculateProgress(line),
                      backgroundColor: Colors.grey[300],
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${int.tryParse(_quantityController.text) ?? 0} / ${line.cantidadPedida}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _allProductsPickeadInLine() ? Colors.black : Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            
            // Imagen del producto
            GestureDetector(
              onTap: () => _navigateToSimpleProductPage(line),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 120,
                  height: 120,
                  margin: const EdgeInsets.only(left: 12),
                  child: Image.network(
                    line.fotosUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.inventory_2, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSimpleProductPage(PickingLinea linea) {    
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    productProvider.setRaiz(linea.codItem);
    appRouter.push('/simpleProductPage'); 
  }

  Future<void> procesarEscaneoUbicacion(String value) async {
    if (_isPatching || value.isEmpty) return;
    
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
        // Incrementamos directamente en 1 sin esperar la respuesta del patch
        setState(() {
          final currentQuantity = int.tryParse(_quantityController.text) ?? 0;
          _quantityController.text = (currentQuantity + 1).toString();
        });
        
        // Ejecutamos el patch en segundo plano
        _patchCurrentLine().then((success) {
          if (!success) {
            _showSingleSnackBar('Error al registrar el producto', backgroundColor: Colors.red);
            // Si falla, restauramos el valor anterior
            setState(() {
              _quantityController.text = (int.tryParse(_quantityController.text) ?? 0 - 1).toString();
            });
          } else {
            _showSingleSnackBar('Producto registrado correctamente');
          }
        });
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

      final currentLine = provider.ordenPickingInterna.lineas![provider.currentLineIndex];
      productos = await ProductServices().getProductByName(context, '', '2', provider.almacen.almacenId.toString(), barcodeScanRes.toString(), '0', provider.token);
      final producto = productos[0];
      bool mismoProducto = producto.raiz == currentLine.codItem;

      if(provider.ubicacionSeleccionada?.existenciaActual == 0) return;

      if (mismoProducto) {
        // Incrementamos directamente en 1 sin esperar la respuesta del patch
        setState(() {
          final currentQuantity = int.tryParse(_quantityController.text) ?? 0;
          _quantityController.text = (currentQuantity + 1).toString();
        });
        
        // Ejecutamos el patch en segundo plano
        _patchCurrentLine().then((success) {
          if (!success) {
            _showSingleSnackBar('Error al registrar el producto', backgroundColor: Colors.red);
            // Si falla, restauramos el valor anterior
            setState(() {
              _quantityController.text = (int.tryParse(_quantityController.text) ?? 0 - 1).toString();
            });
          } else {
            _showSingleSnackBar('Producto registrado correctamente');
          }
        });
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
              _buildLocationListItem(ubicacion, line),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationListItem(UbicacionePicking ubicacion, PickingLinea line) {
    return Card(
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
                      onPressed: (ubicacion.existenciaActual == 0 || _isPatching) 
                          ? null 
                          : _decrementProductQuantity,
                    ),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        enabled: (ubicacion.existenciaActual == 0 || _isPatching) ? false : true,
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: _updateProductQuantity,
                        onEditingComplete: () async {
                          if (_isPatching) return;
                          
                          final provider = Provider.of<ProductProvider>(context, listen: false);
                          final currentLine = provider.ordenPickingInterna.lineas![provider.currentLineIndex];
                          final newQuantity = int.tryParse(_quantityController.text) ?? 0;
                          
                          if (newQuantity != currentLine.cantidadPickeada) {
                            final success = await _patchCurrentLine();
                            if (!success) {
                              _showSingleSnackBar('Error al actualizar la cantidad', backgroundColor: Colors.red);
                              setState(() {
                                _quantityController.text = currentLine.cantidadPickeada.toString();
                              });
                            }
                          }
                          FocusScope.of(context).requestFocus(focoDeScanner);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: (ubicacion.existenciaActual == 0 || _isPatching) ? null : _incrementProductQuantity,
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

  void _showProductPhotoPopup(String imageUrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),  
          child: Column(
            children: [
              AppBar(
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Center(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 100),
                            Text('No se pudo cargar la imagen'),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}