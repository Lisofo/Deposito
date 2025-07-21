// ignore_for_file: unused_field

import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/ubicacion_almacen.dart';
import 'package:deposito/pages/Inventario/editar_inventario.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/almacen_services.dart';
import 'package:deposito/widgets/cargando.dart';
import 'package:deposito/widgets/custom_speed_dial.dart';
import 'package:deposito/widgets/escaner_pda.dart';
import 'package:deposito/widgets/ubicacion_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/product.dart';
import 'package:deposito/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

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
    final productProvider = context.watch<ProductProvider>();
  
    // Si hay una ubicación guardada en el provider, usarla como seleccionada inicialmente
    if (productProvider.ubicacion.almacenUbicacionId != 0 && 
        ubicacionSeleccionada.almacenId == 0) {
      ubicacionSeleccionada = productProvider.ubicacion;
    }
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
                  enabled: productProvider.ubicacion.almacenUbicacionId == 0, // This will disable the dropdown completely
                  hintText: 'Seleccione una ubicacion',
                ),
                const SizedBox(height: 20,),
                EscanerPDA(
                  onScan: procesarEscaneo,
                  focusNode: focoDeScanner,
                  controller: textController
                ),
                const Expanded(
                  child: Text('Escanee o seleccione una ubicación'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
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
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CustomButton(
              text: 'Revisar',
              tamano: 24,
              onPressed: () async {
                appRouter.push('/revisarInventario');
              }
            ),
            if (context.read<ProductProvider>().ubicacion.almacenUbicacionId != 0)
              CustomButton(
                text: 'Siguiente',
                tamano: 24,
                onPressed: () async {
                  appRouter.push('/editarInventario');
                }
              ),
          ],
        ),
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
        
        // Verificar que la ubicación escaneada coincida con la seleccionada (si hay una)
        if (ubicacionSeleccionada.almacenId != 0 && ubicacionEncontrada.codUbicacion != ubicacionSeleccionada.codUbicacion) {
          await error('La ubicación escaneada no coincide con la seleccionada');
          return;
        }

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
        textController.clear();
        await Future.delayed(const Duration(milliseconds: 100));
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

