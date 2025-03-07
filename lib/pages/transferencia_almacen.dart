import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
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
  List<Product> productosEscaneados = [];
  List<UbicacionAlmacen> listaUbicaciones = [];
  bool ubicacionEscaneada = false; // Controla si la ubicación ya fue escaneada

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
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Escaneo de ubicación de origen
              if (!ubicacionEscaneada) // Solo muestra si la ubicación no ha sido escaneada
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownSearch<UbicacionAlmacen>(
                    dropdownDecoratorProps: const DropDownDecoratorProps(
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.center,
                      dropdownSearchDecoration: InputDecoration(
                        hintText: 'Seleccione ubicación de origen',
                        alignLabelWithHint: true,
                        border: InputBorder.none,
                      ),
                    ),
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      searchDelay: Duration.zero,
                    ),
                    onChanged: (value) {
                      setState(() {
                        ubicacionOrigen = value!;
                        ubicacionEscaneada = true; // Marca la ubicación como escaneada
                      });
                    },
                    items: listaUbicaciones,
                    selectedItem: ubicacionOrigen.almacenId == 0 ? null : ubicacionOrigen,
                  ),
                ),
              const SizedBox(height: 20),
              // Escaneo de productos (solo si la ubicación ya fue escaneada)
              if (ubicacionEscaneada)
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
              const SizedBox(height: 20),
              // Lista de productos escaneados (solo si la ubicación ya fue escaneada)
              if (ubicacionEscaneada)
                Expanded(
                  child: ListView.builder(
                    itemCount: productosEscaneados.length,
                    itemBuilder: (context, index) {
                      final producto = productosEscaneados[index];
                      return ListTile(
                        title: Text(producto.descripcion),
                        subtitle: Text('Código: ${producto.raiz}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              productosEscaneados.removeAt(index);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              // Botón para continuar a la siguiente pantalla (solo si la ubicación ya fue escaneada)
              if (ubicacionEscaneada)
                CustomButton(
                  text: 'Continuar',
                  onPressed: () {
                    if (ubicacionOrigen.almacenId == 0 || productosEscaneados.isEmpty) {
                      Carteles.showDialogs(context, 'Complete todos los campos para continuar', false, true, false);
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
      ),
    );
  }

  Future<void> procesarEscaneoProducto(String value) async {
    if (value.isNotEmpty) {
      print('el valor es $value');
      if (!ubicacionEscaneada) {
        // Si la ubicación no ha sido escaneada, procesar como ubicación
        try {
          final ubicacionEncontrada = listaUbicaciones.firstWhere(
            (element) => element.codUbicacion == value || element.descripcion.contains(value),
          );
          ubicacionOrigen = ubicacionEncontrada;
          print(ubicacionOrigen.descripcion);
          ubicacionEscaneada = true; // Marca la ubicación como escaneada
          setState(() {});
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
          setState(() {
            productosEscaneados.add(producto);
          });
          textController.clear();
          await Future.delayed(const Duration(milliseconds: 100));
          focoDeScanner.requestFocus();
        } else {
          Carteles.showDialogs(context, 'Producto no encontrado', false, false, false);
        }
      }
    }
  }
}