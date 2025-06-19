// ignore_for_file: unused_field

import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/ubicacion_almacen.dart';
import 'package:deposito/pages/Inventario/editar_inventario.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/almacen_services.dart';
import 'package:deposito/widgets/cargando.dart';
import 'package:deposito/widgets/ubicacion_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/product.dart';
import 'package:deposito/widgets/custom_button.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:visibility_detector/visibility_detector.dart';

class InventarioPage extends StatefulWidget {
  const InventarioPage({super.key});

  @override
  State<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  List<UbicacionAlmacen> listaUbicaciones = [];
  late Product productoSeleccionado = Product.empty();
  String ticket = '';
  String? _barcode;
  String result = '';
  late bool visible;
  late Almacen almacen;
  late String token;
  TextEditingController textController = TextEditingController();
  FocusNode focoDeScanner = FocusNode();
  final _almacenServices = AlmacenServices();  
  late UbicacionAlmacen ubicacionSeleccionada = UbicacionAlmacen.empty();
  List<dynamic> productosBuscados = [];
  bool estoyBuscando = true;
  late bool camera = false;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  @override
  void dispose() {
    // Cancelar cualquier foco o listener
    focoDeScanner.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Esto asegura que cuando volvemos a esta página, el foco se restablezca correctamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        focoDeScanner.requestFocus();
      }
    });
  }

  Future<void> cargarDatos() async {
    final productProvider = context.read<ProductProvider>();
    almacen = productProvider.almacen;
    token = productProvider.token;
    camera = productProvider.camera;
  }
  
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(child: scaffoldScannerSearch(context, colors));
  }

  Scaffold  scaffoldScannerSearch(BuildContext context, ColorScheme colors) {
    final productProvider = context.read<ProductProvider>();
    listaUbicaciones = productProvider.listaDeUbicacionesXAlmacen;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.read<ProductProvider>().menuTitle,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton.filledTonal(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(colors.primary)
          ),
          onPressed: () async {
            appRouter.pop();
          },
          icon: const Icon(Icons.arrow_back,),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        backgroundColor: colors.primary,
      ),
      body: SafeArea(
        child: LoadingReloadWidget(
          loadDataFunction: cargarDatos,
          loadingMessage: 'Cargando inventario...',
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                UbicacionDropdown(
                  listaUbicaciones: listaUbicaciones, 
                  selectedItem: ubicacionSeleccionada.almacenId == 0 ? null : ubicacionSeleccionada,
                  onChanged: (value) {
                    ubicacionSeleccionada = value!;
                    Provider.of<ProductProvider>(context, listen: false).setUbicacion(ubicacionSeleccionada);
                    appRouter.push('/editarInventario');
                    setState(() {});
                  },
                  hintText: 'Seleccione una ubicacion',
                ),
                const SizedBox(height: 20,),
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
                      border: UnderlineInputBorder(borderSide: BorderSide.none)
                    ),
                    style: const TextStyle(color: Colors.transparent),
                    autofocus: true,
                    keyboardType: TextInputType.none,
                    controller: textController,
                    onFieldSubmitted: procesarEscaneo, // Cambiado a usar onFieldSubmitted
                  ),
                ),
                const Expanded(
                  child: Text('Escanee una ubicación'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: SpeedDial(
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
            onTap: _scanBarcode
          ),
          SpeedDialChild(
            child: const Icon(Icons.restore),
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            label: 'Reiniciar',
            onTap: _resetSearch,
          ),
        ],
      ),
      bottomNavigationBar: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CustomButton(
            text: 'Revisar',
            tamano: 24,
            onPressed: () async {
              appRouter.push('/revisarInventario');
            }
          )
        ],
      ),
    );
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

    if (!mounted || code == '-1') return;

    var codeTrimmed = code!.trim();
    try {
      final ubicacionEncontrada = listaUbicaciones.firstWhere(
        (element) => element.codUbicacion == codeTrimmed || element.descripcion.contains(codeTrimmed),
        orElse: () => UbicacionAlmacen.empty(),
      );
      
      if (ubicacionEncontrada.almacenId == 0) {
        if (mounted) {
          await error(codeTrimmed);
        }
        return;
      }

      if (!mounted) return;

      // Cancelar cualquier foco o proceso pendiente
      focoDeScanner.unfocus();
      textController.clear();
      
      // Actualizar el estado y navegar
      if (mounted) {
        Provider.of<ProductProvider>(context, listen: false).setUbicacion(ubicacionEncontrada);
        setState(() {
          ubicacionSeleccionada = ubicacionEncontrada;
        });
        
        // Utiliza await para asegurarse de que la navegación se complete
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const EditarInventario(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        await error(codeTrimmed);
      }
      print('Ubicación no encontrada: $codeTrimmed');
    }
  }


  void _resetSearch() {
    ubicacionSeleccionada = UbicacionAlmacen.empty();
    focoDeScanner.requestFocus();
    setState(() {});
  }

  procesarEscaneo(String value) async {
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
        appRouter.push('/editarInventario');
        print('Ubicación seleccionada: ${ubicacionEncontrada.descripcion}');
      } catch (e) {
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

