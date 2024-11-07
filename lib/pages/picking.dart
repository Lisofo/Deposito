// ignore_for_file: must_be_immutable, use_build_context_synchronously, unused_field
import 'package:flutter/material.dart';
import 'package:deposito/models/product.dart';
import 'package:deposito/models/product2.dart';
import 'package:deposito/widgets/custom_button.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class PickingPage extends StatefulWidget {
  static const String name = 'agregar_pedido';
  const PickingPage({super.key});

  @override
  State<PickingPage> createState() => _PickingPageState();
}

class _PickingPageState extends State<PickingPage> {
  List listItems = [
    'AH-5838',
    'AH-2311',
    'AH-4444',
    'AD-1234',
  ];
  late Product productoSeleccionado = Product.empty();
  List<Product> historial = [];
  String ticket = '';
  List<String> tickets = [];
  String? _barcode;
  String result = '';
  late bool visible;
  List<Product> product = [];
  int duracion = 30;
  bool arrancarContador = false;
  String token = '';
  List<Product> productosOffline = [];
  List<dynamic> productoScanner = [];
  List<dynamic> productoScannerVariante = [];
//   String modo = Config.MODO;
  final String _previousQuery = '';
  final TextEditingController cantidadController = TextEditingController();
  final TextEditingController ubicacionController = TextEditingController();

  List<dynamic> productosBuscados = [];
  bool estoyBuscando = true;

  List<Product2> productosMostrar = [
    Product2(nombre: 'Flores', cantidadPedida: 14, ubicacion: 'Gondola 12', cantidadPickeada: 0),
    Product2(nombre: 'Colores', cantidadPedida: 52, ubicacion: 'Gondola 2', cantidadPickeada: 0),
    Product2(nombre: 'Azucar', cantidadPedida: 32, ubicacion: 'Gondola 5', cantidadPickeada: 0),
  ];
  
//   readQRCode() async {
//     String code = await FlutterBarcodeScanner.scanBarcode(
//         '#FFFFFF', 'Cancelar', false, ScanMode.QR);
//     context.read<ItemProvider>().setItem(code);
//     final prodPP =
//         product.firstWhere((element) => element.raiz == code, orElse: () {
//       return Product.empty();
//     });
//     context.read<ItemProvider>().setProduct(prodPP);
//     arrancarContador = false;
//     appRouter.push('/product_page');
//   }

  @override
  Widget build(BuildContext context) {
//   _previousQuery = context.read<ItemProvider>().query;
//   if(estoyBuscando){
//     arrancarContador = false;
//   }else{
//     arrancarContador = true;
//   }
//   print('pase Por build');
    final colors = Theme.of(context).colorScheme;
//   if (modo == 'T'){
//     return IdleDetector(
//       idleTime: const Duration(seconds: 30),
//       onIdle: (){
//         print('llegoIdle');
//         print(arrancarContador);
//         if(arrancarContador) {
//           appRouter.push('/video_screen');
//         }
//       },
//       child: ScaffoldScannerSearch(context, colors)
//     );
//   }else {
    return SafeArea(child: scaffoldScannerSearch(context, colors));
//}
  }

  Scaffold  scaffoldScannerSearch(BuildContext context, ColorScheme colors) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Picking',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        // title:  InkWell(
        //   child: const Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        //     children: [

        //       Text('Buscar Item',style: TextStyle(fontSize: 35, color: Colors.white), ),

        //       Icon(Icons.search,color: Colors.white,)
        //     ],
        //   ),
        //   onTap: () async {
        //     estoyBuscando = true;
        //     arrancarContador = false;
        //       final producto = await showSearch(
        //         context: context,
        //        );
        //       if (producto != null) {

        //         List<dynamic> listaProductosBuscados =  await ProductServices().getProductsOfflineFinal(_previousQuery);
        //         setState(() {
        //           productoSeleccionado = producto;
        //           final int productoExiste = historial
        //               .indexWhere((element) => element.raiz == producto.raiz);
        //           if (productoExiste == -1) {
        //             productosBuscados = listaProductosBuscados;
        //             historial.insert(0, producto);
        //           }
        //           context.read<ItemProvider>().setItem(producto.raiz);
        //           context.read<ItemProvider>().setProduct(producto);
        //           arrancarContador = false;
        //           appRouter.push('/product_page');

        //         });
        //       }

        //   },
        // ),
        elevation: 0,
        backgroundColor: colors.primary,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //   if (modo == 'T') ... [
            //     Center(
            //     child: Column(
            //       mainAxisSize: MainAxisSize.min,
            //       children: [
            //         const Text('En caso de usar el lector:',
            //           style: TextStyle(
            //             fontSize: 25
            //           ),
            //         ),
            //         const SizedBox(
            //           height: 20
            //         ),
            //         Container(
            //           child: VisibilityDetector(
            //             onVisibilityChanged: (VisibilityInfo info){
            //               visible = info.visibleFraction > 0;
            //             },
            //             key: const Key('visible-detector-key'),
            //             child: BarcodeKeyboardListener(
            //               bufferDuration: const Duration(milliseconds: 200),
            //               onBarcodeScanned: (barcode) async{
            //                 if(!visible) return;
            //                 print(barcode);
            //                 setState(() {
            //                   _barcode = barcode;
            //                 });
            //                 if (_barcode != null){
            //                   productoScanner = await ProductServices().getProductsOfflineFinal(barcode);
            //                   context.read<ItemProvider>().setProduct(productoScanner[0]);
            //                   context.read<ItemProvider>().setItem(productoScanner[0].raiz);
            //                   historial.insert(0, productoScanner[0]);
            //                   arrancarContador = false;
            //                   appRouter.push('/product_page');
            //                 }
            //               },
            //               child: const Column(
            //                 mainAxisAlignment: MainAxisAlignment.center,
            //                 crossAxisAlignment: CrossAxisAlignment.center,
            //                 children: <Widget>[
            //                   Text(
            //                     'Acerque producto al lector',
            //                     style: TextStyle(
            //                       fontSize: 30,
            //                       color: Colors.black,
            //                       decoration: TextDecoration.underline
            //                     )
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           ),
            //         )
            //       ],
            //     ),
            //   ),
            //   ]else ... [
            //],
            const SizedBox(
              height: 20,
            ),
            Expanded(
              flex: 1,
              child: ListView.separated(
                itemCount: productosMostrar.length,
                itemBuilder: (context, i) {
                  var item = productosMostrar[i];
                  return ListTile(
                    title: Text(item.nombre),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cantidad a agregar: ${item.cantidadPedida.toString()} \nUbicacion: ${item.ubicacion}'),
                        Text('Cantidad Pickeada: ${item.cantidadPickeada.toString()}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: item.isDisabled ? null : () async {
                            ubicacionController.text = item.ubicacion;
                            cantidadController.text = item.cantidadPickeada.toString();
                            await showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Editar Datos'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextFormField(
                                        decoration: const InputDecoration(label: Text('Cantidad pickeada')),
                                        controller: cantidadController,
                                      ),
                                      TextFormField(
                                        decoration: const InputDecoration(label: Text('Ubicacion')),
                                        controller: ubicacionController,
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Cancelar')
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        item.cantidadPickeada = int.tryParse(cantidadController.text)!;
                                        item.ubicacion = ubicacionController.text;
                                        Navigator.of(context).pop();
                                        cantidadController.clear();
                                        ubicacionController.clear();
                                        setState(() {});
                                      },
                                      child: const Text('Confirmar')
                                    )
                                  ],
                                );
                              }
                            );
                          },
                          icon: const Icon(Icons.edit)
                        ),
                        IconButton(
                          onPressed: item.isDisabled ? null : () {
                            productosMostrar.removeAt(i);
                            setState(() {});
                          },
                          icon: const Icon(Icons.delete)
                        ),
                        IconButton(
                          onPressed: () {
                            item.isDisabled = !item.isDisabled;
                            setState(() {});
                          },
                          icon: const Icon(Icons.disabled_by_default)
                        ),
                      ],
                    ),
                    //subtitle: Text(producto.raiz.toString(), style: const TextStyle(fontSize: 14),),
                    //   trailing: SizedBox(
                    //     width: MediaQuery.of(context).size.width/5,
                    //     child: Row(
                    //       mainAxisAlignment: MainAxisAlignment.end,
                    //       children: [
                    //         Text(producto.precioVentaActual.toString(), style: const TextStyle(fontSize: 14),),
                    //         const Icon(Icons.chevron_right)
                    //       ],
                    //     ),
                    //   ),
                    // onTap: () {
                    //   // context.read<ItemProvider>().setProduct(producto);
                    //   // context.read<ItemProvider>().setItem(producto.raiz);
                    //   // arrancarContador = false;
                    //   // appRouter.push('/product_page');
                    // },
                  );
                }, 
                separatorBuilder: (BuildContext context, int index) { 
                  return const Divider(
                    indent: 16,
                    endIndent: 16,
                  ); 
                },
              ),
            ),
            //   if(modo == 'T')...[
            //     Container(
            //     alignment: Alignment.bottomCenter,
            //     child: const Text('Toque la Pantalla al finalizar el uso', style: TextStyle(fontSize: 24)),
            //     ),
            //     const SizedBox(height: 30,)
            //   ]
          ],
        ),
      ),
      bottomNavigationBar: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            iconSize: 40,
              onPressed: () async {
                var res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SimpleBarcodeScannerPage(),
                  ),
                );
                arrancarContador = false;
                if (res is String) {
                  result = res;
                  if (result != '-1') {
                    //   productoScanner = await ProductServices().getProductsOfflineFinal(result);
                    //   context.read<ItemProvider>().setProduct(productoScanner[0]);
                    //   context.read<ItemProvider>().setItem(productoScanner[0].raiz);
                    //   historial.insert(0, productoScanner[0]);
                    //   arrancarContador = false;
                    //   appRouter.push('/product_page');
                    var productoAgregado = Product2.empty();
                    productoAgregado.nombre = result;
                    List<Product2> existeElProducto = productosMostrar.where((producto) => (producto.nombre == productoAgregado.nombre)).toList();
                    if (existeElProducto.isEmpty){
                      productoAgregado.cantidadPedida = 0;
                      productoAgregado.cantidadPickeada = 1;
                      productoAgregado.ubicacion = 'Gondola x';
                      productosMostrar.add(productoAgregado);
                    } else {
                      existeElProducto[0].cantidadPickeada++;
                    }
                    
                    
                    // await showDialog(
                    //     context: context,
                    //     builder: (context) {
                    //       return AlertDialog(
                    //         title: const Text('Cantidad del producto'),
                    //         content: Column(
                    //           mainAxisSize: MainAxisSize.min,
                    //           children: [
                    //             TextFormField(
                    //               decoration: const InputDecoration(label: Text('Cantidad')),
                    //               controller: cantidadController,
                    //             ),
                    //             TextFormField(
                    //               decoration: const InputDecoration(label: Text('Ubicacion')),
                    //               controller: ubicacionController,
                    //             ),
                    //           ],
                    //         ),
                    //         actions: [
                    //           TextButton(
                    //             onPressed: () {
                    //               Navigator.of(context).pop();
                    //             },
                    //             child: const Text('Cancelar')
                    //           ),
                    //           TextButton(
                    //             onPressed: () {
                    //               productoAgregado.cantidadPickeada = int.tryParse(cantidadController.text)!;
                    //               productoAgregado.ubicacion = ubicacionController.text;
                    //               Navigator.of(context).pop();
                    //               cantidadController.clear();
                    //               ubicacionController.clear();
                    //               setState(() {});
                    //             },
                    //             child: const Text('Confirmar')
                    //           )
                    //         ],
                    //       );
                    //     }
                    // );
          
                    
                  }
                }
                setState(() {});
              },
              icon: const Icon(Icons.qr_code_2)
            ),
            CustomButton(
              tamano: 24,
              text: 'Confirmar', 
              onPressed: () async {
                bool hayError = false;
                for (var producto in productosMostrar){
                  if (producto.cantidadPedida < producto.cantidadPickeada){
                    hayError = true;
                  }
                }
                if (hayError){
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hay más productos pickeados que pedidos, revise el picking.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            )
        ],
      ),
    );
  }
}
