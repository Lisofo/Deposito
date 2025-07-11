import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/ubicacion_almacen.dart';
import 'package:deposito/pages/Transferencia/transferencia_almacen.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/almacen_services.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:deposito/widgets/custom_button.dart';
import 'package:deposito/widgets/custom_speed_dial.dart';
import 'package:deposito/widgets/escaner_pda.dart';
import 'package:deposito/widgets/ubicacion_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

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
    final listaUser = await AlmacenServices().getUbicacionDeAlmacen(context, almacen.almacenId, token, visualizacion: 'U');
    if(listaUser.isNotEmpty) {
      listaUbicaciones = [...productProvider.listaDeUbicacionesXAlmacen, ...listaUser];
    } else {
      listaUbicaciones = [...productProvider.listaDeUbicacionesXAlmacen,];
    }
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
              // Botón de transferir
              Row(
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
                  const Text('Llevar en mano'),
                  EscanerPDA(
                    onScan: procesarEscaneo,
                    focusNode: focoDeScanner,
                    controller: textController
                  ),
                ],
              ),  
            ],
          ),
        ),
        bottomNavigationBar: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
      Provider.of<ProductProvider>(context, listen: false).setListaDeUbicaciones(await AlmacenServices().getUbicacionDeAlmacen(context, almacen.almacenId, token, visualizacion: 'F'));
      var push = Carteles.showDialogs(context, 'Transferencia completada', true, true, false);
      if(push){
        Navigator.of(context).popUntil((route) => route.settings.name == '/transferencia');
        appRouter.pushReplacement('/transferencia');
      }
    }    
  }
}