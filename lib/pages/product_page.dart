// ignore_for_file: must_be_immutable, unused_local_variable, unnecessary_new, unrelated_type_equality_checks
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/client.dart';
import 'package:deposito/models/producto_deposito.dart';
import 'package:deposito/services/product_services.dart';
import 'package:flutter/material.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:provider/provider.dart';

class ProductPage extends StatefulWidget {
  static const String name = 'product_page';
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  late List<Variante>? _variantes = [];
  late String raiz = '';
  late Almacen almacen = Almacen.empty();
  late String token = '';
  late Client cliente = Client.empty();
  late num cantidadTotal = 0;
  late double montoTotal = 0.0;
  ProductoDeposito productoSeleccionado = ProductoDeposito.empty();
  ProductoDeposito productoNuevo = ProductoDeposito.empty();
  bool buscando = true;
  final ScrollController listController = ScrollController();
  late ScaffoldMessengerState scaffoldMessenger;
  late List<Almacene> almacenes = [];
  late Almacene? almacenSeleccionado = Almacene.empty(); // Almacén seleccionado
  late List<dynamic> ubicaciones = []; // Ubicaciones del almacén seleccionado

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  @override
  void dispose() {
    scaffoldMessenger.clearSnackBars();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  cargarDatos() async {
    setState(() {
      buscando = true;
      _variantes = [];
    });

    almacen = context.read<ProductProvider>().almacen;
    token = context.read<ProductProvider>().token;
    cliente = context.read<ProductProvider>().client;
    raiz = context.read<ProductProvider>().raiz;

    productoSeleccionado = context.read<ProductProvider>().productoDeposito;

    productoNuevo = await ProductServices().getProductoDeposito(context, raiz, token);

    _variantes = productoNuevo.variantes;

    setState(() {
      buscando = false;
    });
  }

  // Método para manejar la selección de un almacén
  void seleccionarAlmacen(Almacene almacen) {
    setState(() {
      almacenSeleccionado = almacen;
      ubicaciones = almacen.ubicaciones;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            productoNuevo.raiz,
            style: TextStyle(
              color: colores.onPrimary,
            ),
          ),
          backgroundColor: colores.primary,
          iconTheme: IconThemeData(
            color: colores.surface,
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              middleBody(),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: ListView.separated(
                  controller: listController,
                  itemCount: _variantes!.length,
                  itemBuilder: (context, i) {
                    var item = _variantes![i];
                    var stockAlmacen = item.almacenes.firstWhere((Almacene alamacen) => alamacen.almacenId == almacen.almacenId).stockAlmacen;
                    return ListTile(
                      title: Text(item.codItem),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stock Total: ${item.stockTotal}',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Stock del Almacen ${almacen.descripcion}: $stockAlmacen',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 10),
                          const Text('Modelos:'),
                          const SizedBox(height: 10),
                          Text(
                            productoNuevo.modelos,
                            textAlign: TextAlign.start,
                          ),
                          const SizedBox(height: 10),
                          const Text('Almacenes:'),
                          // Scroll horizontal para los almacenes
                          SizedBox(
                            height: 100, // Altura fija para el contenedor de almacenes
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: item.almacenes.length,
                              itemBuilder: (context, index) {
                                var almacen = item.almacenes[index];
                                return GestureDetector(
                                  onTap: () {
                                    seleccionarAlmacen(almacen);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.all(8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          almacen.descAlmacen,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Stock: ${almacen.stockAlmacen}'),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Mostrar ubicaciones del almacén seleccionado
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return const Divider();
                  },
                ),
              ),
              if (almacenSeleccionado != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Ubicaciones del almacen ${almacenSeleccionado!.descAlmacen}:',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (ubicaciones.isEmpty)
                    const Text(
                      'Ubicación vacía',
                      style: TextStyle(fontSize: 16),
                    ),
                  if (ubicaciones.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: false,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ubicaciones.length,
                      itemBuilder: (context, index) {
                        var ubicacion = ubicaciones[index];
                        return ListTile(
                          title: Text(
                            ubicacion.toString(),
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget middleBody() {
    final colores = Theme.of(context).colorScheme;

    return buscando
        ? const Center(child: CircularProgressIndicator())
        : _variantes!.isEmpty || _variantes == null
            ? const Center(
                child: Text('El Producto no existe', style: TextStyle(fontSize: 24)),
              )
            : Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: Text(
                          productoNuevo.descripcion,
                          style: const TextStyle(fontSize: 24),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
  }
}