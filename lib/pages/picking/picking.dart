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

class PickingPage extends StatefulWidget {
  const PickingPage({super.key});

  @override
  State<PickingPage> createState() => _PickingPageState();
}

class _PickingPageState extends State<PickingPage> {

  List<PickingLinea> lineas = [];
  OrdenPicking ordenPicking = OrdenPicking.empty();
  PickingLinea? _selectedLine;
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
    ordenPicking = productProvider.ordenPickingInterna;
    focoDeScanner.requestFocus();
    try {
      setState(() {
        isLoading = true;
        _error = null;
      });
      
      final lines = ordenPicking.lineas;
      
      setState(() {
        lineas = lines!;
        if (lines.isNotEmpty) {
          _selectedLine = lines.first;
        }
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
          title: Text('Orden ${ordenPicking.numeroDocumento}', style: TextStyle(color: colors.onPrimary),),
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
    return Column(
      children: [
        const Placeholder(),
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
  }

  void _resetSearch() {
    focoDeScanner.requestFocus();
    setState(() {});
  }

  Future<void> _scanBarcode() async {
    //Esto es para la camara del cel
    final code = await SimpleBarcodeScanner.scanBarcode(
      context,
      lineColor: '#FFFFFF',
      cancelButtonText: 'Cancelar',
      scanType: ScanType.qr,
      isShowFlashIcon: false,
    );
    if (code == '-1') return;
    if (code != '-1') {
      try {
        // Buscar la ubicación escaneada en la lista de ubicaciones

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
    if (value.isNotEmpty) {
      try {
        
        textController.clear();
        await Future.delayed(const Duration(milliseconds: 100));
        focoDeScanner.requestFocus();
      } catch (e) {
        Carteles.showDialogs(context, 'Error al procesar el escaneo', false, false, false);
      }
    }  
  }

  Widget _buildBottomBar() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        // onPressed: _selectedLine == null ? null : () {Navigator.pushNamed(context,'/products',arguments: _selectedLine,);},
        onPressed: () {
          appRouter.push('/pickingProductosConteo');
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
  }
}