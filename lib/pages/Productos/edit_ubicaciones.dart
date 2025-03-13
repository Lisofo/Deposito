import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/client.dart';
import 'package:deposito/models/items_x_ubicacion.dart';
import 'package:deposito/models/product.dart';
import 'package:deposito/models/producto_deposito.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/provider/ubicacion_provider.dart';
import 'package:deposito/services/almacen_services.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:deposito/widgets/custom_form_field.dart';
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
  final TextEditingController minController = TextEditingController();
  final TextEditingController maxController = TextEditingController();

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
    Provider.of<UbicacionProvider>(context, listen: false).setItemsXUbicacionesAlmacen(itemsXUbicacionesAlmacen);
    
    setState(() {
      buscando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    // final ubicacionProvider = Provider.of<UbicacionProvider>(context);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Ubicaciones ${almacen.descAlmacen}',
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
        : Stack(
          children: [
            Column(
                children: [
                  Expanded(
                    child: Consumer<UbicacionProvider>(
                      builder: (context, listaProvider, child) {
                        return ListView.builder(
                          itemCount: listaProvider.itemsXUbicacionesAlmacen.length,
                          itemBuilder: (context, i) {
                            var item = listaProvider.itemsXUbicacionesAlmacen[i];
                            print(item.almacenUbicacionId);
                            return ListTile(
                              title: Text(item.descripcion),
                              subtitle: Text('${item.codUbicacion} stock: ${item.existenciaActual}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () async {
                                      await editar(context, item);
                                    },
                                    icon: const Icon(Icons.edit, color: Colors.blue,)
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      await borrar(context, item);
                                    },
                                    icon: const Icon(Icons.delete, color: Colors.red,)
                                  ),
                                ],
                              ),
                            );
                          }
                        );
                      },
                    )
                  ),
              ],
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FloatingActionButton(
                  onPressed: () async {
                    appRouter.push('/agregarUbicaciones');
                  },
                  child: const Icon(Icons.add),
                ),
              ),
            ),
          ],
        )
      )
    );
  }

  Future<void> editar(BuildContext context, ItemsPorUbicacion item) async {
    int? statusCode;
    minController.text = item.existenciaMinima.toString();
    maxController.text = item.existenciaMaxima.toString();

    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Esta editando la ubicación ${item.codUbicacion} ${item.descripcion}', style: const TextStyle(fontSize: 16),),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Editar capacidad mínima'),
                const SizedBox(
                  height: 5,
                ),
                CustomTextFormField(
                  controller: minController,
                  maxLines: 1,
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text('Editar capacidad máxima'),
                const SizedBox(
                  height: 5,
                ),
                CustomTextFormField(
                  controller: maxController,
                  maxLines: 1,
                )
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                int min = int.parse(minController.text);
                int max = int.parse(maxController.text);
                await _almacenServices.putUbicacionItemEnAlmacen(context, productoSeleccionado.raiz, item.almacenUbicacionId, min, max, token);
                statusCode = await _almacenServices.getStatusCode();
                await _almacenServices.resetStatusCode();
                if(statusCode == 1) {
                  String texto = '';
                  if(min != item.existenciaMinima && max != item.existenciaMaxima) {
                    texto = 'Cantidades mínimas y máximas editadas correctamente';
                  } else if(min != item.existenciaMinima && max == item.existenciaMaxima) {
                    texto = 'Cantidades mínimas editadas correctamente';
                  } else if(min == item.existenciaMinima && max != item.existenciaMaxima) {
                    texto = 'Cantidades máximas editadas correctamente';
                  } else if(min == 0 && max == 0){
                    texto = 'Cantidades mínimas y máximas editadas correctamente';
                  }
                  print(texto);
                  item.existenciaMaxima = max;
                  item.existenciaMinima = min;
                  Carteles.showDialogs(context, texto, true, false, false);
                }
              },
              child: const Text('Confirmar'),
            ),
            TextButton(
              onPressed: () => appRouter.pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
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
                  Carteles.showDialogs(context, 'Ubicación borrada correctamente', true, false, false);
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