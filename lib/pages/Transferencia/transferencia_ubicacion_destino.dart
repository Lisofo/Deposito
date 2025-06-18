import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/ubicacion_almacen.dart';
import 'package:deposito/pages/Transferencia/transferencia_almacen.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/almacen_services.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:deposito/widgets/custom_button.dart';
import 'package:deposito/widgets/ubicacion_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:visibility_detector/visibility_detector.dart';

class TransferenciaUbicacionDestino extends StatefulWidget {
  final UbicacionAlmacen ubicacionOrigen;
  final List<ProductoAAgregar> productosEscaneados; // Cambiado a List<ProductoAAgregar>

  const TransferenciaUbicacionDestino({
    super.key,
    required this.ubicacionOrigen,
    required this.productosEscaneados,
  });

  @override
  State<TransferenciaUbicacionDestino> createState() => _TransferenciaUbicacionDestinoState();
}

class _TransferenciaUbicacionDestinoState extends State<TransferenciaUbicacionDestino> {
  late Almacen almacen;
  late String token;
  late UbicacionAlmacen ubicacionDestino = UbicacionAlmacen.empty();
  List<UbicacionAlmacen> listaUbicaciones = [];
  final _almacenServices = AlmacenServices();
  TextEditingController textController = TextEditingController();
  FocusNode focoDeScanner = FocusNode();
  late bool camera = false;
  late bool enMano = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cargarDatos();
  }

  cargarDatos() async {
    final productProvider = context.read<ProductProvider>();
    almacen = productProvider.almacen;
    token = productProvider.token;
    camera = productProvider.camera;
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
            'Transferencia - Destino',
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
              // Selección de ubicación de destino
              UbicacionDropdown(
                listaUbicaciones: listaUbicaciones,
                selectedItem: ubicacionDestino.almacenId == 0 ? null : ubicacionDestino,
                enabled: !enMano,
                onChanged: (value) {
                  setState(() {
                    ubicacionDestino = value!;
                  });
                },
                hintText: 'Seleccione ubicación de destino',
              ),
              const SizedBox(height: 20),
              // Lista de productos a transferir
              Expanded(
                child: ListView.builder(
                  itemCount: widget.productosEscaneados.length,
                  itemBuilder: (context, I) {
                    final productoAAgregar = widget.productosEscaneados[I];
                    return ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(productoAAgregar.productoAgregado.raiz),
                          Text(productoAAgregar.productoAgregado.descripcion),
                        ],
                      ),
                      subtitle: Text('Cantidad: ${productoAAgregar.cantidad}'),
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
                  onFieldSubmitted: procesarEscaneo,
                ),
              ),
              // Botón de transferir
              CustomButton(
                text: 'Transferir',
                onPressed: () async {
                  if (ubicacionDestino.almacenId == 0 && enMano == false) {
                    Carteles.showDialogs(context, 'Seleccione una ubicación de destino', false, true, false);
                    return;
                  }
                  await transferirProductos(context);
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Switch(
              value: enMano,
              onChanged: (value) {
                ubicacionDestino = UbicacionAlmacen.empty();
                setState(() {
                  enMano = value;
                });
              }
            ),
            const Text('Llevar en mano')
          ],
        ),
        floatingActionButton: SpeedDial(
          icon: Icons.add,
          activeIcon: Icons.close,
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          children: [
            if(camera)
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
      // Si la ubicación no ha sido escaneada, procesar como ubicación
      try {
        final ubicacionEncontrada = listaUbicaciones.firstWhere((element) => element.codUbicacion == code);
        setState(() {
          ubicacionDestino = ubicacionEncontrada;
        });
        textController.clear();
        await Future.delayed(const Duration(milliseconds: 100));
        focoDeScanner.requestFocus();
      } catch (e) {
        Carteles.showDialogs(context, 'Ubicación no encontrada', false, false, false);
      }
    }
    
    setState(() {});
  }

  void _resetSearch() {
    ubicacionDestino = UbicacionAlmacen.empty();
    focoDeScanner.requestFocus();
    setState(() {});
  }

  Future<void> procesarEscaneo(String value) async {
    if (value.isNotEmpty) {
      // Si la ubicación no ha sido escaneada, procesar como ubicación
      try {
        final ubicacionEncontrada = listaUbicaciones.firstWhere((element) => element.codUbicacion == value);
        setState(() {
          ubicacionDestino = ubicacionEncontrada;
        });
        textController.clear();
        await Future.delayed(const Duration(milliseconds: 100));
        focoDeScanner.requestFocus();
      } catch (e) {
        Carteles.showDialogs(context, 'Ubicación no encontrada', false, false, false);
      }
    }
  }

  Future<void> transferirProductos(BuildContext context) async {
    int? statusCode;
    for (final productoAAgregar in widget.productosEscaneados) {
      await _almacenServices.postTransferencia(
        context,
        productoAAgregar.productoAgregado.raiz,
        almacen.almacenId,
        widget.ubicacionOrigen.almacenUbicacionId,
        enMano ? 0 :ubicacionDestino.almacenUbicacionId,
        productoAAgregar.cantidad,
        token,
      );
    }
    statusCode = await _almacenServices.getStatusCode();
    await _almacenServices.resetStatusCode();
    if(statusCode == 1) {
      var push = Carteles.showDialogs(context, 'Transferencia completada', true, true, false);
      if(push){
        Navigator.of(context).popUntil((route) => route.settings.name == '/transferencia');
        appRouter.pushReplacement('/transferencia');
      }
    }    
  }
}