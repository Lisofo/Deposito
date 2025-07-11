import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/item_consulta.dart';
import 'package:deposito/models/ubicacion_almacen.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/almacen_services.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:deposito/widgets/custom_speed_dial.dart';
import 'package:deposito/widgets/escaner_pda.dart';
import 'package:deposito/widgets/ubicacion_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class ConsultaUbicacionesPage extends StatefulWidget {
  const ConsultaUbicacionesPage({super.key});

  @override
  State<ConsultaUbicacionesPage> createState() => _ConsultaUbicacionesPageState();
}

class _ConsultaUbicacionesPageState extends State<ConsultaUbicacionesPage> {
  late Almacen almacen;
  late String token;
  List<UbicacionAlmacen> listaUbicaciones = [];
  late UbicacionAlmacen ubicacionOrigen = UbicacionAlmacen.empty();
  TextEditingController textController = TextEditingController();
  FocusNode focoDeScanner = FocusNode();
  late String valorUbicacion = '';
  late List<ItemConsulta> listaItems = [];
  late List<Variante> variantes = [];
  late bool camera = false;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    final productProvider = context.read<ProductProvider>();
    almacen = productProvider.almacen;
    token = productProvider.token;
    camera = productProvider.camera;
    focoDeScanner.requestFocus();
    await cargarListaUsuarios(productProvider); 
    setState(() {});
  }

  Future<void> cargarListaUsuarios(ProductProvider productProvider) async {
    final listaUser = await AlmacenServices().getUbicacionDeAlmacen(context, almacen.almacenId, token, visualizacion: 'U');
    if(listaUser.isNotEmpty) {
      listaUbicaciones = [...productProvider.listaDeUbicacionesXAlmacen, ...listaUser];
    } else {
      listaUbicaciones = [...productProvider.listaDeUbicacionesXAlmacen,];
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.read<ProductProvider>().menuTitle,
          style: const TextStyle(color: Colors.white),
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
            UbicacionDropdown(
              listaUbicaciones: listaUbicaciones, 
              selectedItem: ubicacionOrigen.almacenId == 0 ? null : ubicacionOrigen,
              onChanged: (value) async {
                ubicacionOrigen = value!;
                listaItems = await AlmacenServices().getItemXUbicacion(context, almacen.almacenId, ubicacionOrigen.almacenUbicacionId, token);
                variantes.clear();
                for (var item in listaItems) {
                  variantes.addAll(item.variantes);
                }
                setState(() {});
              },
              hintText: 'Seleccione ubicación',
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
            EscanerPDA(
              onScan: procesarEscaneoProducto,
              focusNode: focoDeScanner,
              controller: textController
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomSpeedDialChild(
            icon: Icons.restore,
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            label: 'Reiniciar',
            onTap: _resetSearch,
          ),
          if (camera) ...[
            CustomSpeedDialChild(
              icon: Icons.qr_code_scanner_outlined,
              label: 'Escanear',
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              onTap: _scanBarcode,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  void _resetSearch() {
    ubicacionOrigen = UbicacionAlmacen.empty();
    variantes = [];
    focoDeScanner.requestFocus();
    setState(() {});
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
      try {
        // Buscar la ubicación escaneada en la lista de ubicaciones
        UbicacionAlmacen? ubicacionEscaneada = listaUbicaciones.firstWhere(
          (ubicacion) => ubicacion.codUbicacion == code,
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
    
    setState(() {});
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