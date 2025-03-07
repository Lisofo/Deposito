import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/product.dart';
import 'package:deposito/models/ubicacion_almacen.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/almacen_services.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:deposito/widgets/custom_button.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class TransferenciaUbicacionDestino extends StatefulWidget {
  final UbicacionAlmacen ubicacionOrigen;
  final List<Product> productosEscaneados;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
                      hintText: 'Seleccione ubicación de destino',
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
                      ubicacionDestino = value!;
                    });
                  },
                  items: listaUbicaciones,
                  selectedItem: ubicacionDestino.almacenId == 0 ? null : ubicacionDestino,
                ),
              ),
              const SizedBox(height: 20),
              // Botón de transferir
              CustomButton(
                text: 'Transferir',
                onPressed: () async {
                  if (ubicacionDestino.almacenId == 0) {
                    Carteles.showDialogs(context, 'Seleccione una ubicación de destino', false, true, false);
                    return;
                  }
                  await transferirProductos(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> transferirProductos(BuildContext context) async {
    for (final producto in widget.productosEscaneados) {
      await _almacenServices.postTransferencia(
        context,
        producto.raiz,
        almacen.almacenId,
        widget.ubicacionOrigen.almacenUbicacionId,
        ubicacionDestino.almacenUbicacionId,
        token,
      );
    }
    Carteles.showDialogs(context, 'Transferencia completada', true, false, false);
    appRouter.pop('/transferencia');
  }
}