import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/client.dart';
import 'package:deposito/models/items_x_ubicacion.dart';
import 'package:deposito/models/product.dart';
import 'package:deposito/models/producto_deposito.dart';
import 'package:deposito/models/ubicacion_almacen.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/provider/ubicacion_provider.dart';
import 'package:deposito/services/almacen_services.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:deposito/widgets/custom_button.dart';
import 'package:deposito/widgets/custom_form_field.dart';
import 'package:deposito/widgets/escaner_pda.dart';
import 'package:deposito/widgets/ubicacion_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AgregarUbicaciones extends StatefulWidget {
  const AgregarUbicaciones({super.key});

  @override
  State<AgregarUbicaciones> createState() => _AgregarUbicacionesState();
}

class _AgregarUbicacionesState extends State<AgregarUbicaciones> {
  late List<UbicacionAlmacen> ubicaciones = [];
  late String token = '';
  late Client cliente = Client.empty();
  late String raiz = '';
  late Almacene almacen = Almacene.empty();
  bool buscando = true;
  Product productoSeleccionado = Product.empty();
  late UbicacionAlmacen ubicacionSeleccionada = UbicacionAlmacen.empty();
  TextEditingController textController = TextEditingController();
  TextEditingController cantMinController = TextEditingController();
  TextEditingController cantMaxController = TextEditingController();
  FocusNode focoDeScanner = FocusNode();
  bool noBusqueManual = true;
  final _almacenServices = AlmacenServices();

  @override
  void initState() {
    super.initState();
    focoDeScanner.requestFocus();
    cargarDatos();
  }

  cargarDatos() async {
    almacen = context.read<ProductProvider>().almacene;
    token = context.read<ProductProvider>().token;
    cliente = context.read<ProductProvider>().client;
    raiz = context.read<ProductProvider>().raiz;
    productoSeleccionado = context.read<ProductProvider>().product;

    ubicaciones = await AlmacenServices().getUbicacionDeAlmacen(context, almacen.almacenId, token);

    setState(() {
      buscando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final ubicacionProvider = Provider.of<UbicacionProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Agregar ubicación',
          style: TextStyle(color: colores.onPrimary),
        ),
        backgroundColor: colores.primary,
        iconTheme: IconThemeData(color: colores.surface),
      ),
      body: buscando ? const Center(child: CircularProgressIndicator())
      : Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: UbicacionDropdown(
                listaUbicaciones: ubicaciones, 
                selectedItem: ubicacionSeleccionada,
                onChanged: (value) {
                  setState(() {
                    ubicacionSeleccionada = value!;
                  });
                },
                hintText: 'Seleccione una ubicacion',
              ),
            ),
            const Text('Cantidad mínima'),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CustomTextFormField(
                controller: cantMinController,
                hint: 'Ingrese cantidad mínima',
                maxLines: 1,
                keyboard: const TextInputType.numberWithOptions(),
              ),
            ),
            const Text('Cantidad máxima'),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CustomTextFormField(
                controller: cantMaxController,
                hint: 'Ingrese cantidad máxima',
                maxLines: 1,
                keyboard: const TextInputType.numberWithOptions(),
              ),
            ),
            Center(
              child: CustomButton(
                disabled: ubicacionSeleccionada.almacenId != 0 ? false : true,
                tamano: 24,
                text: 'Agregar +',
                onPressed: ubicacionSeleccionada.almacenId == 0 ? null : () async {
                  int min = cantMinController.text == '' ? 0 : int.parse(cantMinController.text);
                  int max = cantMaxController.text == '' ? 0 : int.parse(cantMaxController.text);
                  if(min > max) {
                    return Carteles.showDialogs(context, 'Revise la cantidad de minimos y maximos', false, false, false);
                  }
                  int? statusCode;
                  await _almacenServices.postUbicacionItemEnAlmacen(
                    context, 
                    productoSeleccionado.raiz,
                    ubicacionSeleccionada.codUbicacion,
                    almacen.almacenId, 
                    min,
                    max,
                    token
                  );
                  statusCode = await _almacenServices.getStatusCode();
                  await _almacenServices.resetStatusCode();
                  if(statusCode == 1) {
                    // Agregar la nueva ubicación al provider
                    ubicacionProvider.agregarUbicacion(Ubicacione(
                      almacenUbicacionId: ubicacionSeleccionada.almacenUbicacionId,
                      codUbicacion: ubicacionSeleccionada.codUbicacion,
                      descUbicacion: ubicacionSeleccionada.descripcion,
                      existenciaActualUbi: 0,
                      capacidad: 0,
                      orden: 0,
                    ));
                    // Agregar el nuevo ítem al provider
                    ubicacionProvider.agregarItemXUbicacion(ItemsPorUbicacion(
                      itemAlmacenUbicacionId: 0, // Este valor debería ser el ID generado por el servidor
                      itemId: 0,
                      almacenUbicacionId: ubicacionSeleccionada.almacenUbicacionId,
                      existenciaActual: 0,
                      existenciaMaxima: max,
                      existenciaMinima: min,
                      almacenId: almacen.almacenId,
                      capacidad: 0,
                      orden: 0,
                      fechaBaja: null,
                      codUbicacion: ubicacionSeleccionada.codUbicacion,
                      descripcion: ubicacionSeleccionada.descripcion,
                    ));
                    Carteles.showDialogs(context, 'Ubicacion agregada correctamente', true, false, false);
                  }
                }
              ),
            ),
            EscanerPDA(
              onScan: procesarEscaneo,
              focusNode: focoDeScanner,
              controller: textController
            ),
          ],
        ),
    );
  }

  procesarEscaneo(String value) async {
    if (value.isNotEmpty) {
      print('Valor escaneado: $value');
      try {
        // Buscar la ubicación correspondiente al código escaneado
        final ubicacionEncontrada = ubicaciones.firstWhere(
          (element) => element.codUbicacion == value || element.descripcion.contains(value),
        );
        setState(() {
          ubicacionSeleccionada = ubicacionEncontrada;
        });
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