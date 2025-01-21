import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/client.dart';
import 'package:deposito/models/items_x_ubicacion.dart';
import 'package:deposito/models/product.dart';
import 'package:deposito/models/producto_deposito.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/almacen_services.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class EditUbicaciones extends StatefulWidget {
  const EditUbicaciones({super.key});

  @override
  State<EditUbicaciones> createState() => _EditUbicacionesState();
}

class _EditUbicacionesState extends State<EditUbicaciones> {

  late String token = '';
  late Client cliente = Client.empty();
  late String raiz = '';
  late Almacene almacen = Almacene.empty();
  bool buscando = true;
  Product productoSeleccionado = Product.empty();
  late List<ItemsPorUbicacion> itemsXUbicacionesAlmacen = [];
  final _almacenServices = AlmacenServices();

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  cargarDatos() async {

    almacen = context.read<ProductProvider>().almacene;
    token = context.read<ProductProvider>().token;
    cliente = context.read<ProductProvider>().client;
    raiz = context.read<ProductProvider>().raiz;
    productoSeleccionado = context.read<ProductProvider>().product;
    
    itemsXUbicacionesAlmacen = await AlmacenServices().getItemPorUbicacionDeAlmacen(context, almacen.almacenId, productoSeleccionado.raiz, token);
    
    
    setState(() {
      buscando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            productoSeleccionado.raiz,
            style: TextStyle(
              color: colores.onPrimary,
            ),
          ),
          backgroundColor: colores.primary,
          iconTheme: IconThemeData(
            color: colores.surface,
          ),
        ),
        body: buscando ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: itemsXUbicacionesAlmacen.length,
                  itemBuilder: (context, i) {
                    var item = itemsXUbicacionesAlmacen[i];
                    return ListTile(
                      title: Text(item.descripcion),
                      subtitle: Text('${item.codUbicacion} stock: ${item.capacidad}'),
                      trailing: IconButton(
                        onPressed: () async {
                          await borrar(context, item);
                        },
                        icon: const Icon(Icons.delete, color: Colors.red,)
                      ),
                    );
                  }
                )
              ),
          ],
        )
      )
    );
  }

  Future<void> borrar(BuildContext context, ItemsPorUbicacion item) async {
    int? statusCode;

    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Advertencia'),
          content: Text('Esta por borrar el codigo de barras ${item.descripcion}. Esta seguro de querer borrarlo?'),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                await _almacenServices.deleteUbicacionItemEnAlmacen(context, productoSeleccionado.raiz, item.almacenUbicacionId, token);
                statusCode = await _almacenServices.getStatusCode();
                await _almacenServices.resetStatusCode();
                if(statusCode == 1) {
                  Carteles.showDialogs(context, 'Item borrado correctamente', true, false, false);
                  itemsXUbicacionesAlmacen.removeWhere((ItemsPorUbicacion element) => element.itemAlmacenUbicacionId == item.itemAlmacenUbicacionId);
                  setState(() {});
                }
              },
              child: const Text('SI'),
            ),
            TextButton(
              onPressed: () => appRouter.pop(),
              child: const Text('NO'),
            ),
          ],
        );
      },
    );
  }
}