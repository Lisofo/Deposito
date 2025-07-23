// ignore_for_file: unused_field

import 'package:deposito/config/router/pages.dart';
import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/ubicacion_almacen.dart';
import 'package:deposito/widgets/custom_speed_dial.dart';
import 'package:deposito/widgets/escaner_pda.dart';
import 'package:deposito/widgets/ubicacion_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class PickingCompra extends StatefulWidget {
  const PickingCompra({super.key});

  @override
  State<PickingCompra> createState() => _PickingCompraState();
}

class _PickingCompraState extends State<PickingCompra> {
  bool isLoading = true;
  String? _error;
  late Almacen almacen;
  late String token;
  FocusNode focoDeScanner = FocusNode();
  TextEditingController textController = TextEditingController();
  List<UbicacionAlmacen> listaUbicaciones = [];
  late UbicacionAlmacen ubicacionSeleccionada = UbicacionAlmacen.empty();
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
    camera = productProvider.camera;
    focoDeScanner.requestFocus();
    try {
      setState(() {
        isLoading = true;
        _error = null;
      });
      listaUbicaciones = [...productProvider.listaDeUbicacionesXAlmacen];
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
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: colors.primary,
          title: Consumer<ProductProvider>(
            builder: (context, provider, child) {
              final ordenPicking = provider.ordenPickingInterna;
              // final lineas = ordenPicking.lineas ?? [];
              return Text(
                'Orden ${ordenPicking.numeroDocumento}', //- Línea ${provider.currentLineIndex + 1}/${lineas.length}', 
                style: TextStyle(color: colors.onPrimary),
              );
            }, 
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.settings.name == '/pickingInterno');
              final router = GoRouter.of(context);
              router.pushReplacement('/pickingInterno');
            },
          ),
        ),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomBar(),
        floatingActionButton: _buildFloatingActionButton(colors),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        // final ordenPicking = provider.ordenPickingInterna;
        // final lineas = ordenPicking.lineas ?? [];
        // final currentLineIndex = provider.currentLineIndex;
        // final selectedLine = currentLineIndex < lineas.length ? lineas[currentLineIndex] : null;
        
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              UbicacionDropdown(
                listaUbicaciones: listaUbicaciones,
                selectedItem: ubicacionSeleccionada.almacenId == 0 ? null : ubicacionSeleccionada,
                onChanged: (value) {
                  if (value != null) {
                    ubicacionSeleccionada = value;
                    textController.clear();
                    focoDeScanner.requestFocus();
                    Provider.of<ProductProvider>(context, listen: false).setUbicacion(ubicacionSeleccionada);
                    setState(() {});
                  }
                },
                hintText: 'Seleccione una ubicacion',
                onPopupDismissed: () {
                  // Solo hacer focus si no se seleccionó nada
                  if (ubicacionSeleccionada.almacenId == 0) {
                    focoDeScanner.requestFocus();
                  }
                },
              ),
              EscanerPDA(
                onScan: procesarEscaneoUbicacion,
                focusNode: focoDeScanner,
                controller: textController
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    final colors = Theme.of(context).colorScheme;
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        return Container(
          color: Colors.grey.shade200,
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              if (ubicacionSeleccionada.almacenId != 0) {
                provider.setUbicacion(ubicacionSeleccionada);
                appRouter.push('/pickingProductosCompra');
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
    ubicacionSeleccionada = UbicacionAlmacen.empty();
    textController.clear();
    focoDeScanner.requestFocus();
    setState(() {});
  }

  Future<void> _scanBarcode() async {
    if (!mounted) return;
    
    // Desenfoca antes de abrir el escáner para evitar problemas
    focoDeScanner.unfocus();
    
    final code = await SimpleBarcodeScanner.scanBarcode(
      context,
      lineColor: '#FFFFFF',
      cancelButtonText: 'Cancelar',
      scanType: ScanType.qr,
      isShowFlashIcon: false,
    );

    textController.clear();
    focoDeScanner.requestFocus();

    if (!mounted || code == '-1') return;

    var codeTrimmed = code!.trim();
    await procesarEscaneoUbicacion(codeTrimmed); 
  }

  procesarEscaneoUbicacion(String value) async {
    if (value.isNotEmpty) {
      print('Valor escaneado: $value');
      try {
        // Buscar la ubicación correspondiente al código escaneado
        final ubicacionEncontrada = listaUbicaciones.firstWhere(
          (element) => element.codUbicacion == value || element.descripcion.contains(value),
        );
        Provider.of<ProductProvider>(context, listen: false).setUbicacion(ubicacionEncontrada);
        setState(() {
          ubicacionSeleccionada = ubicacionEncontrada;
        });
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const PickingProductsEntrada(),
          )
        );
        // print('Ubicación seleccionada: ${ubicacionEncontrada.descripcion}');
      } catch (e) {
        textController.clear();
        await Future.delayed(const Duration(milliseconds: 100)); // Breve pausa para evitar conflictos de enfoque
        focoDeScanner.requestFocus();
        await error(value);
        print('Ubicación no encontrada: $value');
      } finally {
        // Restablecer el campo y reenfocar
        textController.clear();
        await Future.delayed(const Duration(milliseconds: 100)); // Breve pausa para evitar conflictos de enfoque
        focoDeScanner.requestFocus();
      }
    }
  }

  error(String value) async {
    await showDialog(
      context: context, 
      builder: (context) {
        return AlertDialog(
          title: const Text("Mensaje"),
          content: Text('La ubicacion $value no existe o no ha sido encontrada'),
          actions: [
            TextButton(
              onPressed: () {
                appRouter.pop();
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }
}