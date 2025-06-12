// ignore_for_file: must_be_immutable, use_build_context_synchronously, unused_field
import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
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
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: colors.primary,
      foregroundColor: Colors.white,
      children: [
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

  Widget _buildBody() {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        final ordenPicking = provider.ordenPickingInterna;
        final lineas = ordenPicking.lineas ?? [];
        final currentLineIndex = provider.currentLineIndex;
        final selectedLine = currentLineIndex < lineas.length ? lineas[currentLineIndex] : null;
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Dirijase a la ubicación ${selectedLine!.ubicaciones[0].codUbicacion}', 
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            if (provider.modoSeleccionUbicacion == false && lineas.isNotEmpty)
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
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonFormField<UbicacionePicking>(
            value: provider.ubicacionSeleccionada,
            decoration: const InputDecoration(
              labelText: 'Seleccionar Ubicación',
              border: OutlineInputBorder(),
            ),
            items: line.ubicaciones.map((ubicacion) {
              return DropdownMenuItem<UbicacionePicking>(
                value: ubicacion,
                child: Text('Ubicación ${ubicacion.codUbicacion}'),
              );
            }).toList(),
            onChanged: (ubicacion) {
              if (ubicacion != null) {
                provider.setUbicacionSeleccionada(ubicacion);
              }
            },
          ),
        );
      },
    );
  }

  void _resetSearch() {
    focoDeScanner.requestFocus();
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
      final selectedLine = lineas[currentLineIndex];
      final ubicacion = selectedLine.ubicaciones.firstWhere(
        (u) => u.codUbicacion == value,
        orElse: () => UbicacionePicking.empty(),
      );
      
      if (ubicacion.almacenUbicacionId != 0) {
        provider.setUbicacionSeleccionada(ubicacion);
        provider.setCurrentLineIndex(currentLineIndex);
        MaterialPageRoute(
          builder: (context) => const PickingProducts(),
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

  Widget _buildBottomBar() {
    final colors = Theme.of(context).colorScheme;
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              if (provider.ubicacionSeleccionada != null) {
                provider.setCurrentLineIndex(provider.currentLineIndex);
                if (provider.modoSeleccionUbicacion) {
                  // En modo selección, ir directamente a pickingProducts
                  appRouter.push('/pickingProductos');
                } else {
                  appRouter.push('/pickingProductosConteo');
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Debe seleccionar o escanear una ubicación')),
                );
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
}