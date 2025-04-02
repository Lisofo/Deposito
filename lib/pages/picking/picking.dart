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

  late Product productoSeleccionado = Product.empty();
  List<Product> historial = [];
  String ticket = '';
  List<String> tickets = [];
  String? _barcode;
  String result = '';
  late bool visible;
  List<Product> product = [];
  String token = '';
  final TextEditingController cantidadController = TextEditingController();
  final TextEditingController ubicacionController = TextEditingController();
  List<dynamic> productosBuscados = [];
  bool estoyBuscando = true;

  List<Product2> productosMostrar = [
    Product2(nombre: 'Flores', cantidadPedida: 14, ubicacion: 'Gondola 12', cantidadPickeada: 0),
    Product2(nombre: 'Colores', cantidadPedida: 52, ubicacion: 'Gondola 2', cantidadPickeada: 0),
    Product2(nombre: 'Azucar', cantidadPedida: 32, ubicacion: 'Gondola 5', cantidadPickeada: 0),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(child: scaffoldScannerSearch(context, colors));
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
        elevation: 0,
        backgroundColor: colors.primary,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
                        Text('Cantidad a agregar: ${item.cantidadPedida} \nUbicacion: ${item.ubicacion}'),
                        Text('Cantidad Pickeada: ${item.cantidadPickeada}'),
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
            Stack(
              children: [
                Image.asset(
                  'images/planoDeposito.jpg',
                  fit: BoxFit.fill,
                ),
                // Marcador para "Chatarra" - ajusta las coordenadas left/top según necesites
                Positioned(
                  left: 130,  // Ajusta este valor según la posición horizontal
                  top: 320,   // Ajusta este valor según la posición vertical
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '📍 Chatarra',  // Puedes usar un icono o texto
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
                var res = await SimpleBarcodeScanner.scanBarcode(context, lineColor: '#FFFFFF', cancelButtonText: 'Cancelar', scanType: ScanType.qr, isShowFlashIcon: false);
                if (res is String) {
                  result = res;
                  if (result != '-1') {
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
