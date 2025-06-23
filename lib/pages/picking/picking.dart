// ignore_for_file: must_be_immutable, use_build_context_synchronously, unused_field
import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:deposito/widgets/custom_speed_dial.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'picking_products.dart';

class PickingPage extends StatefulWidget {
  const PickingPage({super.key});

  @override
  State<PickingPage> createState() => _PickingPageState();
}

class _PickingPageState extends State<PickingPage> {
  bool isLoading = true;
  String? _error;
  late Almacen almacen;
  late String token;
  FocusNode focoDeScanner = FocusNode();
  TextEditingController textController = TextEditingController();
  late UbicacionePicking ubiSeleccionada = UbicacionePicking.empty();
  late bool camera = false;

  @override
  void initState() {
    super.initState();
    _loadLineas();
  }

  Future<void> _loadLineas() async {
    final productProvider = context.read<ProductProvider>();
    almacen = productProvider.almacen;
    token = productProvider.token;
    focoDeScanner.requestFocus();
    camera = productProvider.camera;
    try {
      setState(() {
        isLoading = true;
        _error = null;
      });
      
      // final ordenPicking = productProvider.ordenPickingInterna;
      // final lines = ordenPicking.lineas;
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        isLoading = false;
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
          iconTheme: IconThemeData(color: colors.onPrimary),
          title: Consumer<ProductProvider>(
            builder: (context, provider, child) {
              final ordenPicking = provider.ordenPickingInterna;
              final lineas = ordenPicking.lineas ?? [];
              return Text(
                'Orden ${ordenPicking.numeroDocumento} - Línea ${provider.currentLineIndex + 1}/${lineas.length}', 
                style: TextStyle(color: colors.onPrimary),
              );
            },
          ),
        ),
        body: _buildBody(),
        floatingActionButton: _buildFloatingActionButton(colors),
        bottomNavigationBar: _buildBottomBar(),
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

  Widget _buildBody() {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        final ordenPicking = provider.ordenPickingInterna;
        final lineas = ordenPicking.lineas ?? [];
        final currentLineIndex = provider.currentLineIndex;
        final selectedLine = (currentLineIndex >= 0 && currentLineIndex < lineas.length) ? lineas[currentLineIndex] : null;
        
        // Si no hay línea seleccionada o no hay ubicaciones, muestra un mensaje alternativo
        final ubicacionTexto = selectedLine?.ubicaciones.isNotEmpty == true 
            ? selectedLine!.ubicaciones[0].codUbicacion 
            : 'Ubicación no disponible';

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (provider.modoSeleccionUbicacion && lineas.isNotEmpty && selectedLine != null)
              Text(
                'Dirijase a la ubicación $ubicacionTexto', 
                style: const TextStyle(fontSize: 18),
              ),
            const SizedBox(height: 20),
            if (provider.modoSeleccionUbicacion == false && lineas.isNotEmpty && selectedLine != null)
              _buildUbicacionSelector(selectedLine),
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

  Widget _buildUbicacionSelector(PickingLinea line) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        // Get the currently selected ubicacion
        final selectedUbicacion = ubiSeleccionada;
        
        // Find if the selected ubicacion exists in the current line's ubicaciones
        final validSelectedUbicacion = selectedUbicacion.almacenUbicacionId != 0 
            ? line.ubicaciones.firstWhere(
                (u) => u.almacenUbicacionId == selectedUbicacion.almacenUbicacionId,
                orElse: () => UbicacionePicking.empty(),
              )
            : null;

        // Use null if the selected ubicacion is not in the current line's ubicaciones
        final initialValue = validSelectedUbicacion?.almacenUbicacionId != 0 
            ? null
            : null;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonFormField<UbicacionePicking>(
            value: initialValue,
            decoration: const InputDecoration(
              labelText: 'Seleccionar Ubicación',
              border: OutlineInputBorder(),
            ),
            items: line.ubicaciones.map((ubicacion) {
              return DropdownMenuItem<UbicacionePicking>(
                value: ubicacion,
                child: Text('Ubicación ${ubicacion.codUbicacion} - Stock: ${ubicacion.existenciaActual}'),
              );
            }).toList(),
            onChanged: (ubicacion) {
              if (ubicacion != null) {
                ubiSeleccionada = ubicacion;
                setState(() {});
              }
            },
          ),
        );
      },
    );
  }

  void _resetSearch() {
    focoDeScanner.requestFocus();
    textController.clear();
    setState(() {});
  }

  Future<void> _scanBarcode() async {
    final code = await SimpleBarcodeScanner.scanBarcode(
      context,
      lineColor: '#FFFFFF',
      cancelButtonText: 'Cancelar',
      scanType: ScanType.qr,
      isShowFlashIcon: false,
    );
    if (code == '-1') return;
    if (code != '-1') {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      final ordenPicking = provider.ordenPickingInterna;
      final lineas = ordenPicking.lineas ?? [];
      final currentLineIndex = provider.currentLineIndex;
    
      if (currentLineIndex >= lineas.length) return;
        try {
          final selectedLine = lineas[currentLineIndex];
          final ubicacion = selectedLine.ubicaciones.firstWhere(
            (u) => u.codUbicacion == code,
            orElse: () => UbicacionePicking.empty(),
          );
        
          if (ubicacion.almacenUbicacionId != 0) {
            provider.setUbicacionSeleccionada(ubicacion);
            provider.setCurrentLineIndex(currentLineIndex);
            Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => const PickingProducts(),
              ),
            );
          } else {
            Carteles.showDialogs(context, 'Ubicación no encontrada', false, false, false);
          }
        textController.clear();
        await Future.delayed(const Duration(milliseconds: 100));
        focoDeScanner.requestFocus();
      } catch (e) {
        Carteles.showDialogs(context, 'Error al procesar el escaneo', false, false, false);
      }
    }
    
    setState(() {});
  }

  Future<void> procesarEscaneoUbicacion(String value) async {
    if (value.isEmpty) return;
    
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final ordenPicking = provider.ordenPickingInterna;
    final lineas = ordenPicking.lineas ?? [];
    final currentLineIndex = provider.currentLineIndex;
    
    if (currentLineIndex >= lineas.length) return;
    
    try {
      final currentLine = lineas[currentLineIndex];
      
      // Si no hay ubicaciones, avanzar a la siguiente línea
      if (currentLine.ubicaciones.isEmpty) {
        _handleEmptyLocations(provider);
        return;
      }
      
      final ubicacion = currentLine.ubicaciones.firstWhere(
        (u) => u.codUbicacion == value,
        orElse: () => UbicacionePicking.empty(),
      );
      
      if (ubicacion.almacenUbicacionId != 0) {
        provider.setUbicacionSeleccionada(ubicacion);
        provider.setCurrentLineIndex(currentLineIndex);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const PickingProducts(),
          )
        );
      } else {
        Carteles.showDialogs(context, 'Ubicación no encontrada', false, false, false);
      }
      
      textController.clear();
      
    } catch (e) {
      Carteles.showDialogs(context, 'Error al procesar el escaneo', false, false, false);
    }
  }

  Widget _buildBottomBar() {
    final colors = Theme.of(context).colorScheme;
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(8),
          child: ElevatedButton(
            onPressed: () {
              final ordenPicking = provider.ordenPickingInterna;
              final currentLineIndex = provider.currentLineIndex;
              final currentLine = ordenPicking.lineas![currentLineIndex];
              
              // Si no hay ubicaciones, avanzar a la siguiente línea
              if (currentLine.ubicaciones.isEmpty) {
                _handleEmptyLocations(provider);
              } else if (ubiSeleccionada.almacenUbicacionId == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Debe seleccionar o escanear una ubicación')),
                );
              } else {
                provider.setUbicacionSeleccionada(ubiSeleccionada);
                provider.setCurrentLineIndex(provider.currentLineIndex);
                if (provider.modoSeleccionUbicacion) {
                  appRouter.push('/pickingProductos');
                } else {
                  appRouter.push('/pickingProductosConteo');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Siguiente',
              style: TextStyle(fontSize: 16, color: colors.onPrimary),
            ),
          ),
        );
      },
    );
  }

  // Nuevo método para manejar líneas sin ubicaciones
  void _handleEmptyLocations(ProductProvider provider) {
    final ordenPicking = provider.ordenPickingInterna;
    int currentLineIndex = provider.currentLineIndex;
    // bool isLastLine = currentLineIndex >= ordenPicking.lineas!.length - 1;

    // Buscar la siguiente línea con stock o que no esté completa
    int nextValidIndex = -1;
    for (int i = currentLineIndex + 1; i < ordenPicking.lineas!.length; i++) {
      final line = ordenPicking.lineas![i];
      bool hasStock = line.ubicaciones.any((ubic) => ubic.existenciaActual > 0);
      bool isComplete = line.cantidadPickeada == line.cantidadPedida;

      if (!isComplete && hasStock) {
        nextValidIndex = i;
        break;
      }
    }

    if (nextValidIndex != -1) {
      // Ir a la siguiente línea válida
      provider.setCurrentLineIndex(nextValidIndex);
      setState(() {});
    } else {
      // No hay más líneas válidas, ir al resumen
      appRouter.push('/resumenPicking');
    }
  }
}