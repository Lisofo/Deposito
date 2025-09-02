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
import 'package:shared_preferences/shared_preferences.dart';
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
  late List<Variante> variantesFiltradas = [];
  late bool camera = false;
  late bool stock = false;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final productProvider = context.read<ProductProvider>();
    almacen = productProvider.almacen;
    token = productProvider.token;
    camera = productProvider.camera;
    stock = prefs.getBool('conExistencias') ?? false;
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

  void filtrarVariantes() {
    if (stock) {
      variantesFiltradas = variantes.where((variante) => variante.stockAlmacen > 0).toList();
    } else {
      variantesFiltradas = List.from(variantes);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    filtrarVariantes();
    
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
      body: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width < 600 ? MediaQuery.of(context).size.width * 0.7 : MediaQuery.of(context).size.width * 0.5,
                child: UbicacionDropdown(
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
              ),
              const SizedBox(width: 10,),
              CustomSpeedDialChild(
                icon: Icons.restore,
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                label: 'Reiniciar',
                onTap: _resetSearch,
              ),
            ],
          ),          
          // Fila del Switch por encima del ListView
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Switch(
                  value: stock,
                  onChanged: (value) {
                    setState(() {
                      stock = value;
                      _saveValue(value);
                    });
                  }
                ),
                const SizedBox(width: 8),
                const Text(
                  'Solo con existencias',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Expanded(
            child: variantesFiltradas.isEmpty
                ? const Center(child: Text('No hay productos para mostrar'))
                : ListView.builder(
                    itemCount: variantesFiltradas.length,
                    itemBuilder: (context, i) {
                      var variante = variantesFiltradas[i];
                      var item = listaItems.firstWhere(
                        (item) => item.variantes.contains(variante),
                        orElse: () => ItemConsulta.empty(),
                      );
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                        elevation: 1,
                        child: ListTile(
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.raiz,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                item.descripcion,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Existencia actual: ${variante.existenciaActualUbi}'),
                              Text('Existencia mínima: ${variante.existenciaMinimaUbi} - Máxima: ${variante.existenciaMaximaUbi}'),
                              Text(
                                'Stock almacén: ${variante.stockAlmacen}',
                                style: TextStyle(
                                  color: variante.stockAlmacen > 0 ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                            ],
                          ),
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
      resizeToAvoidBottomInset: true,
    );
  }

  Future<void> _saveValue(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('conExistencias', value);
  }

  void _resetSearch() {
    ubicacionOrigen = UbicacionAlmacen.empty();
    variantes = [];
    variantesFiltradas = [];
    focoDeScanner.requestFocus();
    setState(() {});
  }

  Future<void> _scanBarcode() async {
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
        UbicacionAlmacen? ubicacionEscaneada = listaUbicaciones.firstWhere(
          (ubicacion) => ubicacion.codUbicacion == code,
          orElse: () => UbicacionAlmacen.empty(),
        );

        if (ubicacionEscaneada.almacenUbicacionId != 0) {
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
        UbicacionAlmacen? ubicacionEscaneada = listaUbicaciones.firstWhere(
          (ubicacion) => ubicacion.codUbicacion == value,
          orElse: () => UbicacionAlmacen.empty(),
        );

        if (ubicacionEscaneada.almacenUbicacionId != 0) {
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