// ignore_for_file: unused_field

import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/ubicacion_almacen.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/almacen_services.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/product.dart';
import 'package:deposito/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

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

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  cargarDatos() async {
    final productProvider = context.read<ProductProvider>();
    almacen = productProvider.almacen;
    token = productProvider.token;

    listaUbicaciones = await AlmacenServices().getUbicacionDeAlmacen(context, almacen.almacenId, token);
    setState(() {});
  }
  
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
            appRouter.pop();
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
                    Provider.of<ProductProvider>(context, listen: false).setUbicacion(ubicacionSeleccionada);
                    appRouter.push('/editarInventario');
                    setState(() {});
                  },
                  items: listaUbicaciones,
                  selectedItem: ubicacionSeleccionada.almacenId == 0 ? null : ubicacionSeleccionada,
                ),
              ),
              const SizedBox(height: 20,),
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
                    border: UnderlineInputBorder(borderSide: BorderSide.none)
                  ),
                  style: const TextStyle(color: Colors.transparent),
                  autofocus: true,
                  keyboardType: TextInputType.none,
                  controller: textController,
                  onFieldSubmitted: procesarEscaneo, // Cambiado a usar onFieldSubmitted
                ),
              ),
              const Expanded(
                child: Text('Escanee una ubicación'),
              ),
              if(ubicacionSeleccionada.almacenId != 0)
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
      bottomNavigationBar: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CustomButton(
            text: 'Revisar',
            tamano: 24,
            onPressed: () async {
              appRouter.push('/revisarInventario');
            }
          )
        ],
      ),
    );
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
        // Restablecer el campo y reenfocar
        textController.clear();
        await Future.delayed(const Duration(milliseconds: 100)); // Breve pausa para evitar conflictos de enfoque
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

