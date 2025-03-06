import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/conteo.dart';
import 'package:deposito/models/product.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/almacen_services.dart';
import 'package:deposito/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RevisarInventario extends StatefulWidget {
  const RevisarInventario({super.key});

  @override
  State<RevisarInventario> createState() => _RevisarInventarioState();
}

class _RevisarInventarioState extends State<RevisarInventario> {
  List<Conteo> listaConteo = [];
  late Product productoSeleccionado = Product.empty();
  String ticket = '';
  String result = '';
  late bool visible;
  late Almacen almacen;
  late String token;

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

    listaConteo = await AlmacenServices().getConteoUbicacion(context, almacen.almacenId, 0, token);
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
          'Revisar',
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
              Expanded(
                child: ListView.builder(
                  itemCount: listaConteo.length,
                  itemBuilder: (context, i) {
                    var item = listaConteo[i];
                    return ListTile(
                      title: Text(item.descripcion),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cantidad contada: ${item.conteo}'),
                          Text('Ubicacion: ${item.codUbicacion}'),
                        ],
                      ),
                    );
                  }
                )
              )
            ],
          ),
        ),
      ),
      bottomNavigationBar: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CustomButton(
            tamano: 24,
            text: 'Finalizar', 
            onPressed: () async {
            }
          )
        ],
      ),
    );
  }
}