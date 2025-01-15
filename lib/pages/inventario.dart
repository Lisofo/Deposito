// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/product2.dart';
import 'package:deposito/models/product.dart';
import 'package:deposito/widgets/custom_button.dart';
import 'package:deposito/widgets/custom_form_dropdown.dart';
import 'package:simple_barcode_scanner/enum.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class InventarioPage extends StatefulWidget {
  const InventarioPage({super.key});

  @override
  State<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  List listaGondolas = [
    'Gondola 1',
    'Gondola 2',
    'Gondola 3',
    'Gondola 4',
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
  
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(child: scaffoldScannerSearch(context, colors));
  }

  Scaffold  scaffoldScannerSearch(BuildContext context, ColorScheme colors) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inventario',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton.filledTonal(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(colors.primary)
          ),
          onPressed: () async {
            appRouter.go('/almacen/menu');
          },
          icon: const Icon(Icons.arrow_back,),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        backgroundColor: colors.primary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomDropdownFormMenu(
                hint: 'Seleccione Gondola',
                onChanged: (value) {setState(() {});},
                items: listaGondolas.map((e) {
                  return DropdownMenuItem(
                    value: e,
                    child: Text(e)
                  );
                }).toList(),
              ),
              const SizedBox(height: 20,),
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
                          Text('Stock: ${item.cantidadPedida.toString()}'),
                          Text('Cantidad a agregar: ${item.cantidadPickeada.toString()}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () async {
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
                            onPressed: () {
                              productosMostrar.removeAt(i);
                              setState(() {});
                            },
                            icon: const Icon(Icons.delete)
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
            ],
          ),
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
                arrancarContador = false;
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
              text: 'Finalizar', 
              onPressed: () async {
                for (var producto in productosMostrar) {
                  producto.cantidadPedida = producto.cantidadPickeada;
                }
                setState(() {});
              }
            )
        ],
      ),
    );
  }
}