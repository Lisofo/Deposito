import 'package:deposito/search/product_search_delegate.dart';
import 'package:deposito/widgets/ubicacion_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/ubicacion_almacen.dart';
import 'package:deposito/models/product.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/almacen_services.dart';
import 'package:deposito/services/product_services.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:deposito/widgets/custom_button.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:visibility_detector/visibility_detector.dart';

class TransferenciaAlmacenPage extends StatefulWidget {
  const TransferenciaAlmacenPage({super.key});

  @override
  State<TransferenciaAlmacenPage> createState() => _TransferenciaAlmacenPageState();
}

class _TransferenciaAlmacenPageState extends State<TransferenciaAlmacenPage> {
  late Almacen almacen;
  late String token;
  late UbicacionAlmacen ubicacionOrigen = UbicacionAlmacen.empty();
  TextEditingController textController = TextEditingController();
  FocusNode focoDeScanner = FocusNode();
  final _almacenServices = AlmacenServices();
  List<ProductoAAgregar> productosEscaneados = []; // Lista de ProductoAAgregar
  List<UbicacionAlmacen> listaUbicaciones = [];
  bool ubicacionEscaneada = false; // Controla si la ubicación ya fue escaneada
  late String valorUbicacion = '';
  List<Product> historial = [];
  late Product selectedProduct = Product.empty();

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  cargarDatos() async {
    final productProvider = context.read<ProductProvider>();
    almacen = productProvider.almacen;
    token = productProvider.token;
    listaUbicaciones = await _almacenServices.getUbicacionDeAlmacen(context, almacen.almacenId, token);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Transferencia - Origen',
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton.filledTonal(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(colors.primary),
            ),
            onPressed: () async {
              appRouter.pop();
            },
            icon: const Icon(Icons.arrow_back),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          backgroundColor: colors.primary,
          actions: [
            IconButton(
              onPressed: () async {
                await agregarDesdeDelegate(context);
              },
              icon: const Icon(Icons.search)
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Escaneo de ubicación de origen
              UbicacionDropdown(
                listaUbicaciones: listaUbicaciones,
                selectedItem: ubicacionOrigen.almacenId == 0 ? null : ubicacionOrigen,
                onChanged: (value) {
                  setState(() {
                    ubicacionOrigen = value!;
                    ubicacionEscaneada = true;
                  });
                },
                enabled: productosEscaneados.isNotEmpty ? false : true,
                hintText: 'Seleccione ubicación de origen',
              ),
              // Escaneo de productos (solo si la ubicación ya fue escaneada)
              const SizedBox(height: 20),
              // Lista de productos escaneados (solo si la ubicación ya fue escaneada)
              if (ubicacionEscaneada)
                Expanded(
                  child: ListView.builder(
                    itemCount: productosEscaneados.length,
                    itemBuilder: (context, index) {
                      final productoAAgregar = productosEscaneados[index];
                      return ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(productoAAgregar.productoAgregado.raiz),
                            Text(productoAAgregar.productoAgregado.descripcion),
                          ],
                        ),
                        subtitle: Text('Cantidad: ${productoAAgregar.cantidad}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editarCantidad(context, productoAAgregar),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  productosEscaneados.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
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
                  onFieldSubmitted: procesarEscaneoProducto,
                ),
              ),
              // Botón para continuar a la siguiente pantalla (solo si la ubicación ya fue escaneada)
              if (ubicacionEscaneada)
                CustomButton(
                  text: 'Continuar',
                  onPressed: () {
                    if (ubicacionOrigen.almacenId == 0 || productosEscaneados.isEmpty) {
                      Carteles.showDialogs(context, 'Complete todos los campos para continuar', false, false, false);
                      return;
                    }
                    // Pasar los argumentos a la siguiente pantalla
                    appRouter.push('/transferencia-destino', extra: {
                      'ubicacionOrigen': ubicacionOrigen,
                      'productosEscaneados': productosEscaneados,
                    });
                  },
                ),
              
            ],
          ),
        ),
        floatingActionButton: SpeedDial(
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
        ),
      ),
    );
  }

  void _resetSearch() {
    ubicacionOrigen = UbicacionAlmacen.empty();
    productosEscaneados = [];
    ubicacionEscaneada = false;
    focoDeScanner.requestFocus();
    setState(() {});
  }

  Future<void> agregarDesdeDelegate(BuildContext context) async {
    final producto = await showSearch(
      context: context,
      delegate: ProductSearchDelegate('Buscar producto', historial)
    );
    
    if (producto != null) {
      // Verificar si el producto ya está en la lista
      final productoExistente = productosEscaneados.firstWhere(
        (p) => p.productoAgregado.raiz == producto.raiz,
        orElse: () => ProductoAAgregar(productoAgregado: Product.empty(), cantidad: 0),
      );
  
      if (productoExistente.productoAgregado.raiz != '') {
        // Si el producto ya está en la lista, incrementar la cantidad
        productoExistente.cantidad += 1;
      } else {
        // Si el producto no está en la lista, agregarlo con cantidad 1
        productosEscaneados.add(ProductoAAgregar(productoAgregado: producto, cantidad: 1));
      }
  
      setState(() {
        selectedProduct = producto;
      });
  
      // Opcional: Limpiar el campo de texto y solicitar el foco nuevamente
      textController.clear();
      await Future.delayed(const Duration(milliseconds: 100));
      focoDeScanner.requestFocus();
    } else {
      setState(() {
        selectedProduct = Product.empty();
      });
    }
  }

  Future<void> procesarEscaneoProducto(String value) async {
    if (value.isNotEmpty) {
      if (!ubicacionEscaneada) {
        // Si la ubicación no ha sido escaneada, procesar como ubicación
        try {
          final ubicacionEncontrada = listaUbicaciones.firstWhere((element) => element.codUbicacion == value);
          setState(() {
            ubicacionOrigen = ubicacionEncontrada;
            valorUbicacion = ubicacionEncontrada.codUbicacion;
            ubicacionEscaneada = true; // Marca la ubicación como escaneada
          });
          textController.clear();
          await Future.delayed(const Duration(milliseconds: 100));
          focoDeScanner.requestFocus();
        } catch (e) {
          Carteles.showDialogs(context, 'Ubicación no encontrada', false, false, false);
        }
      } else {
        // Si la ubicación ya fue escaneada, procesar como producto
        final productos = await ProductServices().getProductByName(context, '', '2', almacen.almacenId.toString(), value, '0', token);
        if (productos.isNotEmpty) {
          final producto = productos[0];
          // Verificar si el producto ya está en la lista
          final productoExistente = productosEscaneados.firstWhere(
            (p) => p.productoAgregado.raiz == producto.raiz,
            orElse: () => ProductoAAgregar(productoAgregado: Product.empty(), cantidad: 0),
          );
          if (productoExistente.productoAgregado.raiz != '') {
            // Si el producto ya está en la lista, incrementar la cantidad
            productoExistente.cantidad += 1;
          } else {
            // Si el producto no está en la lista, agregarlo con cantidad 1
            productosEscaneados.add(ProductoAAgregar(productoAgregado: producto, cantidad: 1));
          }
          setState(() {});
          textController.clear();
          await Future.delayed(const Duration(milliseconds: 100));
          focoDeScanner.requestFocus();
        } else {
          Carteles.showDialogs(context, 'Producto no encontrado', false, false, false);
        }
      }
    }
  }

  Future<void> _editarCantidad(BuildContext context, ProductoAAgregar productoAAgregar) async {
    final cantidadController = TextEditingController(text: productoAAgregar.cantidad.toString());
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Editar cantidad"),
          content: TextField(
            controller: cantidadController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Cantidad'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final nuevaCantidad = int.tryParse(cantidadController.text) ?? 1;
                if (nuevaCantidad > 0) {
                  setState(() {
                    productoAAgregar.cantidad = nuevaCantidad;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
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
      if (!ubicacionEscaneada) {
        // Si la ubicación no ha sido escaneada, procesar como ubicación
        try {
          final ubicacionEncontrada = listaUbicaciones.firstWhere((element) => element.codUbicacion == code);
          setState(() {
            ubicacionOrigen = ubicacionEncontrada;
            valorUbicacion = ubicacionEncontrada.codUbicacion;
            ubicacionEscaneada = true; // Marca la ubicación como escaneada
          });
          textController.clear();
          await Future.delayed(const Duration(milliseconds: 100));
          focoDeScanner.requestFocus();
        } catch (e) {
          Carteles.showDialogs(context, 'Ubicación no encontrada', false, false, false);
        }
      } else {
        // Si la ubicación ya fue escaneada, procesar como producto
        final productos = await ProductServices().getProductByName(context, '', '2', almacen.almacenId.toString(), code.toString(), '0', token);
        if (productos.isNotEmpty) {
          final producto = productos[0];
          // Verificar si el producto ya está en la lista
          final productoExistente = productosEscaneados.firstWhere(
            (p) => p.productoAgregado.raiz == producto.raiz,
            orElse: () => ProductoAAgregar(productoAgregado: Product.empty(), cantidad: 0),
          );
          if (productoExistente.productoAgregado.raiz != '') {
            // Si el producto ya está en la lista, incrementar la cantidad
            productoExistente.cantidad += 1;
          } else {
            // Si el producto no está en la lista, agregarlo con cantidad 1
            productosEscaneados.add(ProductoAAgregar(productoAgregado: producto, cantidad: 1));
          }
          setState(() {});
          textController.clear();
          await Future.delayed(const Duration(milliseconds: 100));
          focoDeScanner.requestFocus();
        } else {
          Carteles.showDialogs(context, 'Producto no encontrado', false, false, false);
        }
      }
    }
    
    setState(() {});
  }
}

class ProductoAAgregar {
  late Product productoAgregado;
  late int cantidad;

  ProductoAAgregar({
    required this.productoAgregado,
    this.cantidad = 1, // Por defecto, la cantidad es 1
  });
}