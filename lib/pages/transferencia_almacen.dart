import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/ubicacion_almacen.dart';
import 'package:deposito/services/almacen_services.dart';
import 'package:deposito/widgets/custom_form_field.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/product.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/product_services.dart';
import 'package:deposito/widgets/carteles.dart';

class TransferenciaAlmacenPage extends StatefulWidget {
  const TransferenciaAlmacenPage({super.key});

  @override
  State<TransferenciaAlmacenPage> createState() => _TransferenciaAlmacenPageState();
}

class _TransferenciaAlmacenPageState extends State<TransferenciaAlmacenPage> {
  String barcodeFinal = '';
  late String token;
  late bool tienePermiso = true;
  late Almacen almacen;
  bool _escaneoActivo = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _cantidadTransferirController = TextEditingController();
  List<UbicacionAlmacen> listaUbicaciones = [];
  late UbicacionAlmacen ubicacionSeleccionada = UbicacionAlmacen.empty();

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cantidadTransferirController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print("didChangeDependencies llamado");
    _escaneoActivo = false; // Asegura que no se active automáticamente
  }

  void cargarDatos() async {
    final productProvider = context.read<ProductProvider>();
    almacen = productProvider.almacen;
    token = productProvider.token;
    listaUbicaciones = await AlmacenServices().getUbicacionDeAlmacen(context, almacen.almacenId, token);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colores.primary,
        iconTheme: IconThemeData(color: colores.surface),
        leading: IconButton(
          onPressed: () => appRouter.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text('Escanee un producto', style: TextStyle(color: colores.onPrimary),),
        actions: [
          IconButton(
            onPressed: () async {
              await manualSearch(context);
            },
            icon: const Icon(Icons.search)
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text('Último escaneado: $barcodeFinal', textAlign: TextAlign.center),
              ),
            ),

            Expanded(
              child: VisibilityDetector(
                key: const Key('visible-detector-key'),
                onVisibilityChanged: (info) {
                  if (info.visibleFraction > 0) {
                    _onBarcodeScanned();
                  }
                },
                child: BarcodeKeyboardListener(
                  bufferDuration: const Duration(milliseconds: 200),
                  onBarcodeScanned: (barcode) => _onBarcodeScanned(barcode),
                  child: const Text('', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _scanBarcode();
        },
        child: const Icon(Icons.qr_code_scanner_outlined),
      ),
    );
  }

  Future<void> transferir(BuildContext context, Product producto) async {
    _cantidadTransferirController.clear();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Transferir ${producto.descripcion}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextFormField(
                hint: 'Cantidad a transferir',
                controller: _cantidadTransferirController,
              ),
              const SizedBox(height: 10,),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownSearch(
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    dropdownSearchDecoration: InputDecoration(
                      hintText: 'Seleccione una ubicacion',
                      alignLabelWithHint: true,
                      border: InputBorder.none,
                    ),
                  ),
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                    searchDelay: Duration.zero,
                  ),
                  onChanged: (value) {
                    ubicacionSeleccionada = value;
                    setState(() {});
                  },
                  items: listaUbicaciones,
                  selectedItem: ubicacionSeleccionada.almacenId == 0 ? null : ubicacionSeleccionada,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                appRouter.pop();
              },
              child: const Text('Cerrar'),
            ),
            TextButton(
              onPressed: () async {
                appRouter.pop();
              },
              child: const Text('Transferir'),
            ),
          ],
        );
      }
    );
  }

  Future<void> manualSearch(BuildContext context) async {
    _searchController.clear();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Buscar'),
          content: CustomTextFormField(
            maxLines: 1,
            hint: 'Buscar código de barras',
            controller: _searchController,
          ),
          actions: [
            TextButton(
              onPressed: () {
                appRouter.pop();
              },
              child: const Text('Cerrar'),
            ),
            TextButton(
              onPressed: () async {
                String barcode = _searchController.text;
                final listaProductosTemporal = await ProductServices().getProductByName(
                  context,
                  '',
                  '2',
                  almacen.almacenId.toString(),
                  barcode,
                  "0",
                  token,
                );

                if (listaProductosTemporal.isNotEmpty) {
                  final productoRetorno = listaProductosTemporal[0];
                } else {
                  Carteles.showDialogs(context, 'No se pudo conseguir ningún producto con el código $barcode', false, false, false);
                }
              },
              child: const Text('Buscar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onBarcodeScanned([String? barcode]) async {
    print('Valor escaneado: $barcode');

    final listaProductosTemporal = await ProductServices().getProductByName(
      context,
      '',
      '2',
      Provider.of<ProductProvider>(context, listen: false).almacen.almacenId.toString(),
      barcode.toString(),
      "0",
      token,
    );

    if (listaProductosTemporal.isNotEmpty) {
      final productoRetorno = listaProductosTemporal[0];
    } else {
      Carteles.showDialogs(context, 'No se pudo conseguir ningún producto con el código $barcode', false, false, false);
    }
  }

  Future<void> _scanBarcode() async {
    print('Intentando escanear: $_escaneoActivo');
    if (_escaneoActivo) return;
    _escaneoActivo = true;

    String? code = await SimpleBarcodeScanner.scanBarcode(
      context,
      lineColor: '#FFFFFF',
      cancelButtonText: 'Cancelar',
      isShowFlashIcon: false,
      delayMillis: 1000,
    );

    if (code == '-1') {
      _escaneoActivo = false; // Restablecer la variable si se cancela el escaneo
      return;
    }

    setState(() {
      barcodeFinal = code.toString();
    });

    final listaProductosTemporal = await ProductServices().getProductByName(
      context,
      '',
      '2',
      almacen.almacenId.toString(),
      code.toString(),
      "0",
      token,
    );

    if (listaProductosTemporal.isNotEmpty) {
      final productoRetorno = listaProductosTemporal[0];
    } else {
      Carteles.showDialogs(
        context,
        'No se pudo conseguir ningún producto con el código $barcodeFinal',
        false,
        false,
        false,
      );
    }

    _escaneoActivo = false; // Permitir otro escaneo después de la navegación
  }
}