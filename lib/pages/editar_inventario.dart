import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/conteo.dart';
import 'package:deposito/models/product.dart';
import 'package:deposito/models/ubicacion_almacen.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/search/product_search_delegate.dart';
import 'package:deposito/services/almacen_services.dart';
import 'package:deposito/services/product_services.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:deposito/widgets/custom_button.dart';
import 'package:deposito/widgets/custom_form_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

class EditarInventario extends StatefulWidget {
  const EditarInventario({super.key});

  @override
  State<EditarInventario> createState() => _EditarInventarioState();
}

class _EditarInventarioState extends State<EditarInventario> {

  late Almacen almacen;
  late String token;
  late UbicacionAlmacen ubicacion = UbicacionAlmacen.empty();
  TextEditingController textController = TextEditingController();
  FocusNode focoDeScanner = FocusNode();
  late Product productoEscaneado = Product.empty();
  final _almacenServices = AlmacenServices();
  late List<String> productosAgregados = [];
  List<Product> historial = [];
  late Product selectedProduct = Product.empty();
  late List<Conteo> conteoList = [];
  final TextEditingController conteoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  cargarDatos() async {
    final productProvider = context.read<ProductProvider>();
    almacen = productProvider.almacen;
    token = productProvider.token;
    ubicacion = productProvider.ubicacion;
    conteoList = await _almacenServices.getConteoUbicacion(context, almacen.almacenId, ubicacion.almacenUbicacionId, token);
    setState(() {});
  }
  


  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            ubicacion.codUbicacion,
            style: TextStyle(
              color: colors.onPrimary
            ),
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
          actions: [
            IconButton(
              onPressed: () async {
                await agregarDesdeDelegate(context);
              },
              icon: const Icon(Icons.search)
            )
          ],
        ),
        body: Column(
          children: [
            // Text(productoEscaneado.descripcion),
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
                  border: UnderlineInputBorder(borderSide: BorderSide.none)
                ),
                style: const TextStyle(color: Colors.transparent),
                autofocus: true,
                keyboardType: TextInputType.none,
                controller: textController,
                onFieldSubmitted: procesarEscaneo, // Cambiado a usar onFieldSubmitted
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: conteoList.length,
                itemBuilder: (context, i) {
                  var product = conteoList[i];
                  return ListTile(
                    title: Text(product.descripcion),
                    subtitle: Text('Cantidad contada: ${product.conteo}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () async {
                            await editarConteo(context, product);
                          },
                          icon: Icon(Icons.edit, color: colors.primary,)
                        ),
                        IconButton(
                          onPressed: () async {
                            borrarConteoItem(context, product, false);
                          },
                          icon: const Icon(Icons.delete, color: Colors.red,)
                        )
                      ],
                    ),
                  );
                }
              )
            )
          ],
        ),
        bottomNavigationBar: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CustomButton(
              tamano: 16,
              text: 'Borrar conteo de la ubicacion ${ubicacion.descripcion}',
              disabled: conteoList.isEmpty,
              onPressed: conteoList.isEmpty ? null : () async {
                await borrarConteoTotal(context);
              }
            )
          ],
        ),
      )
    );
  }

  Future<void> borrarConteoTotal(BuildContext context) async {
    String texto = 'Desea eliminar todo los productos contados hasta ahora?';
    await showDialog(
      context: context, 
      builder: (context) {
        return AlertDialog(
          title: const Text("Mensaje"),
          content: Text(texto),
          actions: [
            TextButton(
              onPressed: () async {
                appRouter.pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                await _almacenServices.deleteConteo(context, almacen.almacenId, ubicacion.almacenUbicacionId, 0, token);
                int? statusCode;
                statusCode = await _almacenServices.getStatusCode();
                await _almacenServices.resetStatusCode();
                if(statusCode == 1) {
                  Carteles.showDialogs(context, 'Conteos eliminados de la lista correctamente', true, false, false);
                  conteoList.clear();
                  setState(() {});
                }
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> borrarConteoItem(BuildContext context, Conteo product, bool borrarTodo) async {
    String texto = 'Desea eliminar la cantidad contada total del producto ${product.descripcion}?';
    await showDialog(
      context: context, 
      builder: (context) {
        return AlertDialog(
          title: const Text("Mensaje"),
          content: Text(texto),
          actions: [
            TextButton(
              onPressed: () async {
                appRouter.pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                await _almacenServices.deleteConteo(context, product.almacenId, product.almacenUbicacionId, product.itemId, token);
                int? statusCode;
                statusCode = await _almacenServices.getStatusCode();
                await _almacenServices.resetStatusCode();
                if(statusCode == 1) {
                  Carteles.showDialogs(context, 'Producto eliminado de la lista correctamente', true, false, false);
                  conteoList.removeWhere((e) => e.itemId == product.itemId);
                  setState(() {});
                }
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> editarConteo(BuildContext context, Conteo product) async {
    conteoController.text = product.conteo.toString();
    await showDialog(
      context: context, 
      builder: (context) {
        return AlertDialog(
          title: const Text("Editar/Agregar"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Desea contabilizar más productos ${product.descripcion}?'),
              const SizedBox(
                height: 10,
              ),
              CustomTextFormField(
                controller: conteoController,
                keyboard: const TextInputType.numberWithOptions(),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                appRouter.pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                late int conteo = int.parse(conteoController.text);
                int? statusCode;
                await _almacenServices.patchUbicacionItemEnAlmacen(context, product.codItem, almacen.almacenId, product.almacenUbicacionId, true, conteo, token);
                statusCode = await _almacenServices.getStatusCode();
                await _almacenServices.resetStatusCode();
                if(statusCode == 1) {
                  product.conteo = conteo;
                  Carteles.showDialogs(context, 'Conteo del producto ${product.descripcion} editado correctamente', true, false, false);
                  setState(() {});
                }
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> agregarDesdeDelegate(BuildContext context) async {
    final producto = await showSearch(
      context: context,
      delegate: ProductSearchDelegate('Buscar producto', historial)
    );
    int? statusCode;
    if(producto != null) {
      setState(() {
        selectedProduct = producto;
        final int clienteExiste = historial.indexWhere((element) => element.raiz == producto.raiz);
        if (clienteExiste == -1) {
          historial.insert(0, producto);
        }
      });
      await showDialog(
        context: context, 
        builder: (context) {
          return AlertDialog(
            title: const Text("Mensaje"),
            content: Text('Desea agregar el producto ${selectedProduct.descripcion} a la ubicacion ${ubicacion.descripcion}'),
            actions: [
              TextButton(
                onPressed: () async {
                  await _almacenServices.patchUbicacionItemEnAlmacen(context, selectedProduct.raiz, almacen.almacenId, ubicacion.almacenUbicacionId, false, 0, token);
                  statusCode = await _almacenServices.getStatusCode();
                  await _almacenServices.resetStatusCode();
                  if( statusCode == 1 ) {
                    Carteles.showDialogs(context, 'Existencia del producto ${productoEscaneado.descripcion} ha sido actualizada', true, false, false);
                  }
                  conteoList = await _almacenServices.getConteoUbicacion(context, almacen.almacenId, ubicacion.almacenUbicacionId, token);
                  setState(() {});
                },
                child: const Text('Aceptar'),
              ),
              TextButton(
                onPressed: () {
                  appRouter.pop();
                },
                child: const Text('Cancelar'),
              ),
            ],
          );
        },
      );
      
    } else {
      setState(() {
        selectedProduct = Product.empty();
      });
    }
  }

   procesarEscaneo(String value) async {
    late List<Product> productos = [];
    int? statusCode;
    if (value.isNotEmpty) {
      print('Valor escaneado: $value');
      try {
        productos = await ProductServices().getProductByName(context, '', '2', almacen.almacenId.toString(), value, '0', token);
        productoEscaneado = productos[0];
        await _almacenServices.patchUbicacionItemEnAlmacen(context, productoEscaneado.raiz, almacen.almacenId, ubicacion.almacenUbicacionId, false, 0, token);
        statusCode = await _almacenServices.getStatusCode();
        await _almacenServices.resetStatusCode();
        if( statusCode == 1 ) {
          Carteles.showDialogs(context, 'Existencia del producto ${productoEscaneado.descripcion} ha sido actualizada', true, false, false);
        }
        conteoList = await _almacenServices.getConteoUbicacion(context, almacen.almacenId, ubicacion.almacenUbicacionId, token);
        setState(() {});
      } catch (e) {
        // await error(value);
        print('Producto no encontrado: $value');
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