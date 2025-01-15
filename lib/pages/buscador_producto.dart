// ignore_for_file: must_be_immutable

import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/client.dart';
import 'package:deposito/models/codigo_barras.dart';
import 'package:deposito/models/linea.dart';
import 'package:deposito/models/product.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/product_services.dart';
import 'package:deposito/services/qr_services.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_barcode_scanner/enum.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class BuscadorProducto extends StatefulWidget {
  const BuscadorProducto({super.key});

  @override
  State<BuscadorProducto> createState() => _BuscadorProductoState();
}

class _BuscadorProductoState extends State<BuscadorProducto> {
  List<Product> listItems = [];
  late Almacen almacen;
  late String token;
  late Client cliente;
  int offset = 0;
  final TextEditingController query = TextEditingController();
  final ScrollController scrollController = ScrollController();
  bool cargandoMas = false;
  bool cargando = false;
  bool busco = false;
  late List<Linea> lineas = [];
  bool isMobile = false;
  String barcodeFinal = '';
  TextEditingController textController = TextEditingController();
  FocusNode focoDeScanner = FocusNode();
  bool noBusqueManual = true;
  late bool visible;
  late bool tienePermiso = true;
  late bool agregarCodBarra = false;

  @override
  void initState() {
    super.initState();
    cargarDatos();
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (scrollController.position.pixels == scrollController.position.maxScrollExtent && !cargandoMas) {
      cargarMasDatos();
    }
  }

  void cargarDatos() {
    final productProvider = context.read<ProductProvider>();
    almacen = productProvider.almacen;
    token = productProvider.token;
    cliente = productProvider.client;
    setState(() {});
  }

  Future<void> cargarMasDatos() async {
    setState(() => cargandoMas = true);
    final nuevosItems = await ProductServices().getProductByName(
      context,
      query.text.trim(),
      '2',
      almacen.almacenId.toString(),
      '',
      offset.toString(),
      token,
    );
    setState(() {
      listItems.addAll(nuevosItems);
      offset += 20;
      cargandoMas = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    lineas = context.watch<ProductProvider>().lineasGenericas;
    final colores = Theme.of(context).colorScheme;
    isMobile = MediaQuery.of(context).size.shortestSide < 600;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: colores.primary,
          iconTheme: IconThemeData(color: colores.surface),
          leading: IconButton(
            onPressed: () => appRouter.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: SearchBar(
                  textInputAction: TextInputAction.search,
                  hintText: 'Buscar o escanear item...',
                  controller: query,
                  trailing: [
                    IconButton(
                      onPressed: () => query.clear(),
                      icon: Icon(Icons.clear, color: colores.onSurface),
                    )
                  ],
                  onTap: () => noBusqueManual = false,
                  onSubmitted: (value) async {
                    setState(() => cargando = true);
                    query.text = value;
                    offset = 0;
                    listItems = await ProductServices().getProductByName(
                      context,
                      query.text.trim(),
                      '2',
                      almacen.almacenId.toString(),
                      '',
                      offset.toString(),
                      token,
                    );
                    setState(() {
                      busco = true;
                      cargando = false;
                      // offset += 20;
                      noBusqueManual = false;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        body: cargando ? _buildLoadingIndicator()
        : SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: Text('Ultimo escaneado: $barcodeFinal', textAlign: TextAlign.center),
                        ),
                      ),
                      if (isMobile) _buildMobileScanner(),
                      if (!isMobile && !busco) _buildDesktopScanner(),
                      _buildProductList(),
                      if (cargandoMas) _buildLoadingIndicator(),
                    ],
                  ),
                ),
                if (listItems.isNotEmpty || !noBusqueManual)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FloatingActionButton(
                        onPressed: _resetSearch,
                        child: const Icon(Icons.delete),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text('Buscando...'),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileScanner() {
    return Column(
      children: [
        if (kIsWeb)
          IconButton(
            style: ButtonStyle(
              iconSize: const WidgetStatePropertyAll(40),
              backgroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.primary),
            ),
            onPressed: _scanBarcode,
            icon: const Icon(Icons.qr_code_scanner_outlined),
          )
        else if (!busco)
          const SizedBox(height: 100),
        if (!busco && !agregarCodBarra)
          Align(
            alignment: Alignment.center,
            child: ElevatedButton(
              style: const ButtonStyle(iconSize: WidgetStatePropertyAll(100)),
              onPressed: _scanBarcode,
              child: const Icon(Icons.qr_code_scanner_outlined),
            ),
          ),
        VisibilityDetector(
          key: const Key('scanner-field-visibility'),
          onVisibilityChanged: (info) {
            if (info.visibleFraction > 0) {
              // Solicitar el foco cuando el campo de texto sea visible
              focoDeScanner.requestFocus();
            }
          },
          child: Visibility(
            visible: false,
            maintainState: true,
            child: TextFormField(
              focusNode: focoDeScanner,
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.all(Radius.zero),
                ),
                contentPadding: EdgeInsets.all(0),
              ),
              autofocus: noBusqueManual,
              canRequestFocus: true,
              keyboardType: TextInputType.none, // Deshabilita el teclado virtual
              onChanged: (value) async {
                print('Valor del campo: $value');
                if (value.isEmpty) return; // Ignorar si el valor está vacío
                setState(() {
                  barcodeFinal = value;
                });
                final listaProductosTemporal = await ProductServices().getProductByName(
                  context,
                  '',
                  '2',
                  almacen.almacenId.toString(),
                  barcodeFinal,
                  "0",
                  token,
                );

                if (listaProductosTemporal.isNotEmpty) {
                  final productoRetorno = listaProductosTemporal[0];
                  _navigateToProductPage(productoRetorno);
                } else {
                  if(tienePermiso){
                    await agregarCodBarraEscaneado();
                  } else {
                    Carteles.showDialogs(context, 'No se pudo conseguir ningún producto con el código $barcodeFinal', false, false, false,);
                  }
                }
                // Reiniciar el estado para permitir nuevos escaneos
                setState(() {
                  textController.clear();
                  value = '';
                });

                // Volver a solicitar el foco para permitir un nuevo escaneo
                focoDeScanner.requestFocus();
              },
              controller: textController,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> agregarCodBarraEscaneado() async {
    await showDialog(
      barrierDismissible: true,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Mensaje'),
          content: Text('No se pudo conseguir ningún producto con el código $barcodeFinal\nDesea agregar el codigo escaneado?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                setState(() {
                  agregarCodBarra = true;
                });
                appRouter.pop();
              },
              child: const Text('SI'),
            ),
            TextButton(
              onPressed: () => appRouter.pop(),
              child: const Text('NO'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDesktopScanner() {
    return Column(
      children: [
        const SizedBox(height: 100),
        Align(
          alignment: Alignment.center,
          child: ElevatedButton(
            style: const ButtonStyle(iconSize: WidgetStatePropertyAll(100)),
            onPressed: _scanBarcode,
            child: const Icon(Icons.qr_code_scanner_outlined),
          ),
        ),
        VisibilityDetector(
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
      ],
    );
  }

  Widget _buildProductList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: listItems.length,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, i) {
        final item = listItems[i];
        final foto = item.imagenes[0];
        final precio = item.precioIvaIncluidoMin != item.precioIvaIncluidoMax ? '${item.precioIvaIncluidoMin} - ${item.precioIvaIncluidoMax}' : item.precioIvaIncluidoMax.toString();
        final existe = lineas.any((linea) => linea.raiz == item.raiz);

        return Row(
          children: [
            GestureDetector(
              onTap: () => _navigateToSimpleProductPage(item),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.15,
                width: MediaQuery.of(context).size.width * 0.1,
                child: Image.network(
                  foto,
                  errorBuilder: (context, error, stackTrace) => const Placeholder(child: Text('No Image')),
                ),
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: ListTile(
                onTap: () async {
                  await confirmarAgregarCodBarra(context, item);
                },
                title: Text(item.raiz),
                subtitle: Text('${item.descripcion} \nPrecio: ${item.signo}$precio    Disponibilidad: ${item.disponibleRaiz}'),
                trailing: const Icon(Icons.chevron_right, size: 35),
                tileColor: existe ? Colors.lightBlue[100] : null,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> confirmarAgregarCodBarra(BuildContext context, Product item) async {
    late List<CodigoBarras> codigos = [];
    codigos = await QrServices().getCodBarras(context, item.raiz, token);
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBd) => AlertDialog(
            title: Text('Está por asignar un nuevo código al item ${item.descripcion}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[800]),),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Se asignara el código escaneado $barcodeFinal al item ${item.descripcion}'),
                if(codigos.isNotEmpty)...[
                  const SizedBox(height: 10,),
                  const Text('Codigos ya asignados:'),
                  const SizedBox(height: 5,),
                  Expanded(
                    child: Scrollbar(
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: codigos.length,
                        itemBuilder: (context, i) {
                          var codigo = codigos[i];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(codigo.codigoBarra),
                              const SizedBox(height: 5,)
                            ],
                          );
                        },
                      ),
                    ),
                  )
                ] else ...[
                  const SizedBox(height: 10,),
                  const Text('El item no tiene codigos de barra asignados')
                ]
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await QrServices().postCB(context, item.raiz, barcodeFinal, token);
                  _navigateToProductPage(item);
                },
                child: const Text('SI'),
              ),
              TextButton(
                onPressed: () => appRouter.pop(),
                child: const Text('NO'),
              ),
            ],
          ),
        );
      }
    );
  }

  void _resetSearch() {
    Provider.of<ProductProvider>(context, listen: false).setProduct(Product.empty());
    query.clear();
    busco = false;
    focoDeScanner.requestFocus();
    noBusqueManual = true;
    listItems = [];
    setState(() {});
  }

  void _navigateToProductPage(Product product) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.setProduct(product);
    productProvider.setRaiz(product.raiz);
    appRouter.push('/paginaProducto');
  }

  void _navigateToSimpleProductPage(Product product) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.setFotos(product.imagenes);
    appRouter.push('/simpleProductPage');
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

    barcodeFinal = code.toString();
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
      _navigateToProductPage(productoRetorno);
    } else {
      Carteles.showDialogs(context, 'No se pudo conseguir ningún producto con el código $code', false, false, false);
    }
    setState(() {});
  }

  Future<void> _onBarcodeScanned([String? barcode]) async {
    print('Valor escaneado: $barcode');
    
    final listaProductosTemporal = await ProductServices().getProductByName(
      context,
      '',
      '2',
      almacen.almacenId.toString(),
      barcode.toString() ,
      "0",
      token,
    );
    if (listaProductosTemporal.isNotEmpty) {
      final productoRetorno = listaProductosTemporal[0];
      _navigateToProductPage(productoRetorno);
    } else {
      Carteles.showDialogs(context, 'No se pudo conseguir ningún producto con el código $barcode', false, false, false);
    }
  }
}