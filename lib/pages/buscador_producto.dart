// ignore_for_file: must_be_immutable

import 'package:deposito/config/router/routes.dart';
import 'package:deposito/models/client.dart';
import 'package:deposito/models/linea.dart';
import 'package:deposito/models/product.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/product_services.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
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
  late String almacen = '';
  late String token = '';
  late Client cliente = Client.empty();
  late int offset = 0;
  final TextEditingController query = TextEditingController();
  final ScrollController scrollController = ScrollController();
  bool cargandoMas = false; // Bandera para evitar múltiples llamadas simultáneas
  bool cargando = false;
  bool activo = false;
  late String descripcion = '';
  late String raiz = '';
  bool busco = false;
  late List<Linea> lineas = [];
  bool existe = false;
  bool isMobile = false;

  late bool visible;
  String? _barcode;
  late bool noBusqueManual;
  FocusNode focoDeScanner = FocusNode();

  String barcodeFinal = '';
  String scannerResult = '';
  TextEditingController textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    noBusqueManual = true;
    cargarDatos();

    // Añadir un listener al ScrollController para detectar el final de la lista
    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent && !cargandoMas) {
        cargarMasDatos();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cargarDatos();
  }

  void cargarDatos() async {
    almacen = context.read<ProductProvider>().almacen;
    token = context.read<ProductProvider>().token;
    cliente = context.read<ProductProvider>().client;

    setState(() {});
  }

  Future<void> cargarMasDatos() async {
    setState(() {
      cargandoMas = true; // Indicar que estamos cargando más datos
    });

    List<Product> nuevosItems = await ProductServices().getProductByName(
      context,
      raiz,
      cliente.codTipoLista,
      almacen,
      descripcion, // Descripción vacía al cargar más
      offset.toString(),
      token
    );

    setState(() {
      listItems.addAll(nuevosItems); // Añadir los nuevos productos a la lista existente
      offset += 20; // Incrementar el offset para la próxima carga
      cargandoMas = false; // Indicar que ya no estamos cargando datos
    });
  }

  @override
  Widget build(BuildContext context) {
    lineas = context.watch<ProductProvider>().lineasGenericas;
    final colores = Theme.of(context).colorScheme;
    var shortestSide = MediaQuery.of(context).size.shortestSide;
    isMobile = shortestSide < 600;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: colores.primary,
          iconTheme: IconThemeData(color: colores.surface),
          leading: IconButton.filledTonal(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(colores.primary)
            ),
            onPressed: () async {
              router.go('/almacen/menu');
            },
            icon: const Icon(Icons.arrow_back,),
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
                  autoFocus: false,
                  trailing: [
                    IconButton(
                      onPressed: () {
                        query.clear();
                      },
                      icon: Icon(
                        Icons.clear,
                        color: colores.onSurface,
                      )
                    )
                  ],
                  onTap: () {
                    noBusqueManual = false;
                  },
                  onSubmitted: (value) async {
                    cargando = true;
                    setState(() {});
                    query.text = value;
                    raiz = query.text.trim();
                    offset = 0;
                    listItems = await ProductServices().getProductByName(
                      context,
                      raiz,
                      cliente.codTipoLista,
                      almacen,
                      '',
                      offset.toString(),
                      token);
                    setState(() {
                      busco = true;
                      cargando = false;
                      offset += 20;
                      noBusqueManual = false;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        body: !cargando
            ? SafeArea(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      controller: scrollController, // Controlador del scroll
                      child: Column(children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                              child: Text(
                            'Ultimo escaneado: $barcodeFinal',
                            textAlign: TextAlign.center,
                          )),
                        ),
                        if (isMobile) ...[
                          if (kIsWeb) ...[
                            IconButton(
                              style: ButtonStyle(
                                iconSize: const WidgetStatePropertyAll(40),
                                alignment: Alignment.center,
                                backgroundColor: WidgetStatePropertyAll(colores.primary)
                              ),
                              onPressed: () async {
                                Product productoRetorno;
                                List<Product> listaProductosTemporal;
                                var res = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SimpleBarcodeScannerPage(),
                                  ),
                                );
                                if (res == null) {
                                  print("El scanner se cerro o no se tiene permisos de cámara");
                                }
                                if (res is String) {
                                  barcodeFinal = res;
                                  if (barcodeFinal != '-1') {
                                    listaProductosTemporal = await ProductServices().getProductByName(
                                      context,
                                      '',
                                      cliente.codTipoLista,
                                      almacen,
                                      barcodeFinal,
                                      "0",
                                      token,
                                    );
                                    if (listaProductosTemporal.isNotEmpty) {
                                      productoRetorno = listaProductosTemporal[0];
                                      Provider.of<ProductProvider>(context, listen: false).setProduct(productoRetorno);
                                      router.go('/buscadorProducto/paginaProducto');
                                      setState(() {});
                                    } else {
                                      Carteles.showDialogs(context, 'No se pudo conseguir ningun producto con el código $barcodeFinal', false, false, false);
                                    }
                                  }
                                }
                              },
                              icon: const Icon(Icons.qr_code_scanner_outlined),
                            ),
                          ] else if (!busco) ...[
                            //Container(color: Colors.green, width: 200, height: 200,),
                            const SizedBox(height: 100,),
                            Align(
                              alignment: Alignment.center,
                              child: ElevatedButton(
                                style: const ButtonStyle(
                                  iconSize: WidgetStatePropertyAll(100),
                                ),
                                onPressed: readQRCode,
                                child: const Icon(Icons.qr_code_scanner_outlined),
                              ),
                            ),
                          ]
                        ] else if (!busco)...[
                          const SizedBox(height: 100,),
                          Align(
                            alignment: Alignment.center,
                              child: ElevatedButton(
                                style: const ButtonStyle(
                                  iconSize: WidgetStatePropertyAll(100),
                                ),
                                onPressed: readQRCode,
                                child: const Icon(Icons.qr_code_scanner_outlined),
                              ),
                            ),

                          ///ESTO ES TEMPORALLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL
                          VisibilityDetector(
                            onVisibilityChanged: (VisibilityInfo info) {
                              visible = info.visibleFraction > 0;
                            },
                            key: const Key('visible-detector-key'),
                            child: BarcodeKeyboardListener(
                              bufferDuration: const Duration(milliseconds: 200),
                              onBarcodeScanned: (barcode) async {
                                if (!visible) return;
                                print(barcode);
                                setState(() {
                                  _barcode = barcode;
                                });
                                if (_barcode != null) {
                                  Product productoRetorno;
                                  List<Product> listaProductosTemporal;
                                  String code = await FlutterBarcodeScanner.scanBarcode('#FFFFFF', 'Cancelar', false, ScanMode.QR);
                                  print('el codigo escaneado es $code');
                                  if (code == '') {
                                    return null;
                                  } else {
                                    listaProductosTemporal = await ProductServices().getProductByName(
                                      context,
                                      '',
                                      cliente.codTipoLista,
                                      almacen,
                                      code,
                                      "0",
                                      token,
                                    );
                                    barcodeFinal = code;
                                    if (listaProductosTemporal.isNotEmpty) {
                                      productoRetorno = listaProductosTemporal[0];
                                      Provider.of<ProductProvider>(context, listen: false).setProduct(productoRetorno);
                                      router.go('/buscadorProducto/paginaProducto');
                                      setState(() {});
                                    } else {
                                      Carteles.showDialogs(context, 'No se pudo conseguir ningun producto con el código $code', false, false, false);
                                    }
                                  }
                                }
                              },
                              child: const Text(
                                '',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              )
                            )
                          )
                        ],
                        Visibility(
                          visible: false,
                          maintainState: true,
                          child: TextFormField(
                            focusNode: focoDeScanner,
                            cursorColor: Colors.white,
                            decoration: InputDecoration(
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: colores.surface), // Cambia el color a rojo
                                borderRadius: const BorderRadius.all(Radius.zero)
                              ),
                              contentPadding: const EdgeInsets.all(0)
                            ),
                            autofocus: noBusqueManual,
                            canRequestFocus: true,
                            keyboardType: TextInputType.none, // Deshabilita el teclado virtual
                            onChanged: (value) async {
                              Product productoRetorno;
                              List<Product> listaProductosTemporal;
                              print('objeto escaneado $value');
                              barcodeFinal = value;
                              listaProductosTemporal = await ProductServices().getProductByName(
                                context,
                                '',
                                cliente.codTipoLista,
                                almacen,
                                barcodeFinal,
                                "0",
                                token,
                              );
                              if (listaProductosTemporal.isNotEmpty) {
                                productoRetorno = listaProductosTemporal[0];
                                irAProductPage(context, productoRetorno);
                                setState(() {
                                  textController.clear(); // Asume que tienes un TextEditingController llamado _controller
                                });
                              } else {
                                Carteles.showDialogs(context, 'No se pudo conseguir ningun producto con el código $barcodeFinal', false, false, false);
                              }
                              // Guarda el resultado del escaneo

                              // Resetea el campo de texto
                            },
                            controller: textController, // Asume que tienes un TextEditingController llamado _controller
                          ),
                        ),
                        if (!busco || listItems.isNotEmpty) ...[
                          ListView.builder(
                              shrinkWrap: true,
                              itemCount: listItems.length,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, i) {
                                var item = listItems[i];
                                var foto = item.imagenes[0];
                                var precio = '';
                                existe = false; // Reiniciar la variable 'existe' para cada item

                                // Verificar si el itemId existe en la lista de 'lineas'
                                for (var linea in lineas) {
                                  if (linea.raiz == item.raiz) {
                                    existe = true; // Si se encuentra el itemId en lineas, marcar 'existe' como true
                                    break; // No es necesario seguir buscando, ya encontramos el itemId
                                  }
                                }

                                if (item.precioIvaIncluidoMin != item.precioIvaIncluidoMax) {
                                  precio = '${item.precioIvaIncluidoMin} - ${item.precioIvaIncluidoMax}';
                                } else {
                                  precio = item.precioIvaIncluidoMax.toString();
                                }

                                return Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Provider.of<ProductProvider>(context, listen: false).setRaiz(item.raiz);
                                        router.go('/buscadorProducto/paginaProducto/simpleProductPage');
                                      },
                                      child: SizedBox(
                                        height: MediaQuery.of(context).size.height * 0.15,
                                        width: MediaQuery.of(context).size.width * 0.1,
                                        child: Image.network(
                                          foto,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Placeholder(
                                              child: Text('No Image'),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.9,
                                      child: ListTile(
                                        onTap: () {
                                          FocusScope.of(context).unfocus();
                                          irAProductPage(context, item);
                                        },
                                        title: Text(item.raiz),
                                        subtitle: Text('${item.descripcion} \nPrecio: ${item.signo}$precio    Disponibilidad: ${item.disponibleRaiz}'),
                                        trailing: const Icon(
                                          Icons.chevron_right,
                                          size: 35,
                                        ),
                                        // Si 'existe' es true, pintar el ListTile de azul claro
                                        tileColor: existe ? Colors.lightBlue[100] : null,
                                      ),
                                    ),
                                  ],
                                );
                              }),
                        ] else ...[
                          if (listItems.isEmpty && busco) ...[
                            const Text(
                              'No se encontró su busqueda. Intentelo nuevamente',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300)
                            )
                          ],
                        ],
                        if (cargandoMas)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                      ]),
                    ),
                    if (listItems.isNotEmpty || !noBusqueManual)
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: FloatingActionButton(
                            child: const Icon(Icons.delete),
                            onPressed: () {
                              Provider.of<ProductProvider>(context, listen: false).setProduct(Product.empty());
                              query.clear();
                              busco = false;
                              focoDeScanner.requestFocus();
                              noBusqueManual = true;
                              listItems = [];
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              )
            : const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(
                      height: 10,
                    ),
                    Text('Buscando...')
                  ],
                )),
              ),
      ),
    );
  }

  void irAProductPage(BuildContext context, Product productoRetorno) {
    Provider.of<ProductProvider>(context, listen: false).setProduct(productoRetorno);
    Provider.of<ProductProvider>(context, listen: false).setRaiz(productoRetorno.raiz);
    router.go('/buscadorProducto/paginaProducto');
  }

  readQRCode() async {
    Product productoRetorno;
    List<Product> listaProductosTemporal;
    String code = await FlutterBarcodeScanner.scanBarcode('#FFFFFF', 'Cancelar', false, ScanMode.QR);
    print('el codigo escaneado es $code');
    if (code == '-1') {
      return null;
    } else {
      barcodeFinal = code;
      listaProductosTemporal = await ProductServices().getProductByName(
        context,
        '',
        cliente.codTipoLista,
        almacen,
        code,
        "0",
        token,
      );
      if (listaProductosTemporal.isNotEmpty) {
        productoRetorno = listaProductosTemporal[0];
        Provider.of<ProductProvider>(context, listen: false).setProduct(productoRetorno);
        router.go('/buscadorProducto/paginaProducto');
      } else {
        Carteles.showDialogs(context, 'No se pudo conseguir ningun producto con el código $code', false, false, false);
      }
      setState(() {});
    }
  }
}
