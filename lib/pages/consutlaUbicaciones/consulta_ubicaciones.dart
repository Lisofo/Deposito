import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/item_consulta.dart';
import 'package:deposito/models/ubicacion_almacen.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/almacen_services.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ConsultaUbicacionesPage extends StatefulWidget {
  const ConsultaUbicacionesPage({super.key});

  @override
  State<ConsultaUbicacionesPage> createState() => _ConsultaUbicacionesPageState();
}

class _ConsultaUbicacionesPageState extends State<ConsultaUbicacionesPage> {
  late Almacen almacen;
  late String token;
  final _almacenServices = AlmacenServices();
  List<UbicacionAlmacen> listaUbicaciones = [];
  late UbicacionAlmacen ubicacionOrigen = UbicacionAlmacen.empty();
  TextEditingController textController = TextEditingController();
  FocusNode focoDeScanner = FocusNode();
  late String valorUbicacion = '';
  late List<ItemConsulta> listaItems = [];
  late List<Variante> variantes = [];

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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Consulta',
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
                    hintText: 'Seleccione ubicación',
                    alignLabelWithHint: true,
                    border: InputBorder.none,
                  ),
                ),
                popupProps: const PopupProps.menu(
                  showSearchBox: true,
                  searchDelay: Duration.zero,
                ),
                onChanged: (value) async {
                  ubicacionOrigen = value!;
                  listaItems = await AlmacenServices().getItemXUbicacion(context, almacen.almacenId, ubicacionOrigen.almacenUbicacionId, token);
                  variantes.clear();
                  for (var item in listaItems) {
                    variantes.addAll(item.variantes);
                  }
                  setState(() {});
                },
                items: listaUbicaciones,
                selectedItem: ubicacionOrigen.almacenId == 0 ? null : ubicacionOrigen,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: variantes.length,
                itemBuilder: (context, i) {
                  var item = listaItems[i];
                  var variante = variantes[i];
                  return ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.raiz),
                        Text(item.descripcion),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Existencia actual: ${variante.existenciaActualUbi}'),
                        Text('Existencia mínima: ${variante.existenciaMinimaUbi} - Existencia máxima: ${variante.existenciaMaximaUbi}'),
                      ],
                    ),
                  );
                }
              )
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
          ],
        ),
      ),
    );
  }

  Future<void> procesarEscaneoProducto(String value) async {
    if (value.isNotEmpty) {
      try {
        // Buscar la ubicación escaneada en la lista de ubicaciones
        UbicacionAlmacen? ubicacionEscaneada = listaUbicaciones.firstWhere(
          (ubicacion) => ubicacion.codUbicacion == value,
          orElse: () => UbicacionAlmacen.empty(),
        );

        if (ubicacionEscaneada.almacenUbicacionId != 0) {
          // Si se encuentra la ubicación, actualizar el estado y cargar los productos
          setState(() {
            ubicacionOrigen = ubicacionEscaneada;
          });
          listaItems = await AlmacenServices().getItemXUbicacion(context, almacen.almacenId, ubicacionOrigen.almacenUbicacionId, token);
          variantes.clear();
          for (var item in listaItems) {
            variantes.addAll(item.variantes);
          }
          setState(() {});
        } else {
          // Si no se encuentra la ubicación, mostrar un mensaje de error
          Carteles.showDialogs(context, 'Ubicación no encontrada', false, false, false);
        }

        textController.clear();
        await Future.delayed(const Duration(milliseconds: 100));
        focoDeScanner.requestFocus();
      } catch (e) {
        Carteles.showDialogs(context, 'Error al procesar el escaneo', false, false, false);
      }
    }  
  }
}