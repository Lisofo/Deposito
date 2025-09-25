// ignore_for_file: must_be_immutable, unused_local_variable, unnecessary_new, unrelated_type_equality_checks
import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/client.dart';
import 'package:deposito/models/codigo_barras.dart';
import 'package:deposito/models/producto_deposito.dart';
import 'package:deposito/models/ubicacion_almacen.dart';
import 'package:deposito/provider/ubicacion_provider.dart';
import 'package:deposito/services/product_services.dart';
import 'package:deposito/services/qr_services.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:deposito/widgets/custom_form_field.dart';
import 'package:flutter/material.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:provider/provider.dart';

class ProductPage extends StatefulWidget {
  static const String name = 'product_page';
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  late List<Variante>? _variantes = [];
  late String raiz = '';
  late Almacen almacen = Almacen.empty();
  late String token = '';
  late Client cliente = Client.empty();
  late num cantidadTotal = 0;
  late double montoTotal = 0.0;
  ProductoDeposito productoSeleccionado = ProductoDeposito.empty();
  ProductoDeposito productoNuevo = ProductoDeposito.empty();
  bool buscando = true;
  final ScrollController listController = ScrollController();
  late ScaffoldMessengerState scaffoldMessenger;
  late List<Almacene> almacenes = [];
  late Almacene? almacenSeleccionado = Almacene.empty();
  late List<Ubicacione> ubicaciones = [];
  late List<CodigoBarras> codigos = [];
  final _qrServices = QrServices();
  final TextEditingController codBarrasController = TextEditingController();
  late int uId = 0;
  late List<String> permisos = [];
  late bool editUbi = false;
  late bool editCodBarras = false;
  late Almacene almacenCargado = Almacene.empty();
  bool _verMasModelo = false;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  @override
  void dispose() {
    scaffoldMessenger.clearSnackBars();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Recargar datos cuando la página vuelva a ser visible
    // ignore: deprecated_member_use
    ModalRoute.of(context)?.addScopedWillPopCallback(() async {
      if (mounted) {
        cargarDatos();
      }
      return true;
    });
  }

  cargarDatos() async {
    setState(() {
      buscando = true;
      _variantes = [];
    });

    almacen = context.read<ProductProvider>().almacen;
    token = context.read<ProductProvider>().token;
    cliente = context.read<ProductProvider>().client;
    raiz = context.read<ProductProvider>().raiz;
    uId = context.read<ProductProvider>().uId;
    permisos = context.read<ProductProvider>().permisos;
    editCodBarras = permisos.contains('WMS_MANT_ITEM_CB');
    editUbi = permisos.contains('WMS_MANT_ITEM_UBI');

    productoSeleccionado = context.read<ProductProvider>().productoDeposito;

    productoNuevo = await ProductServices().getProductoDeposito(context, raiz, token);
    codigos = await QrServices().getCodBarras(context, productoNuevo.variantes[0].codItem, token);
    _variantes = productoNuevo.variantes;
    almacenCargado = _variantes![0].almacenes.firstWhere((e) => e.descAlmacen == almacen.descripcion);
    seleccionarAlmacen(almacenCargado);
    Provider.of<UbicacionProvider>(context, listen: false).setUbicaciones(almacenCargado.ubicaciones);
    setState(() {
      buscando = false;
    });
  }

  void seleccionarAlmacen(Almacene almacen) {
    setState(() {
      almacenSeleccionado = almacen;
      ubicaciones = almacen.ubicaciones;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final ubicacionProvider = Provider.of<UbicacionProvider>(context);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            productoNuevo.raiz,
            style: TextStyle(
              color: colores.onPrimary,
            ),
          ),
          backgroundColor: colores.primary,
          iconTheme: IconThemeData(
            color: colores.surface,
          ),
          actions: [
            IconButton(
              onPressed: () async {
                final productProvider = Provider.of<ProductProvider>(context, listen: false);
                productProvider.setFotos(productoNuevo.fotosUrl);
                appRouter.push('/simpleProductPage');
              },
              icon: const Icon(Icons.image)
            )
          ],
        ),
        body: buscando 
          ? const Center(child: CircularProgressIndicator())
          : _variantes!.isEmpty || _variantes == null 
            ? const Center(child: Text('El Producto no existe', style: TextStyle(fontSize: 24)))
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Encabezado con descripción del producto
                          Padding(
                            padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Center(
                                    child: Text(
                                      productoNuevo.descripcion,
                                      style: const TextStyle(fontSize: 24),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // En tu ListView.builder, modifica la parte del texto del modelo:
                          ListView.builder(
                            controller: listController,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _variantes!.length,
                            itemBuilder: (context, i) {
                              var item = _variantes![i];
                              var stockAlmacen = item.almacenes.firstWhere(
                                (Almacene alamacen) => alamacen.almacenId == almacen.almacenId
                              ).stockAlmacen;
                              
                              // Determina si el texto necesita ser recortado
                              bool textoLargo = productoNuevo.modelos.length > 200;
                              String textoMostrar = _verMasModelo 
                                ? productoNuevo.modelos 
                                : (textoLargo 
                                    ? '${productoNuevo.modelos.substring(0, 150)}...' 
                                    : productoNuevo.modelos);
                              
                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.codItem,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: MediaQuery.of(context).size.width < 600 ? 1 : 3,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Stock Total: ${item.stockTotal}',
                                                style: const TextStyle(fontSize: 18),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Stock del Almacen ${almacen.descripcion}: $stockAlmacen',
                                                style: const TextStyle(fontSize: 18),
                                              ),
                                              const SizedBox(height: 10),
                                              const Text('Modelos:'),
                                              if (textoLargo)
                                                TextButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _verMasModelo = !_verMasModelo;
                                                    });
                                                  },
                                                  child: Text(
                                                    _verMasModelo ? 'Ver menos' : 'Ver más',
                                                    style: const TextStyle(
                                                      color: Colors.blue,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              const SizedBox(height: 10),
                                              Text(
                                                textoMostrar,
                                                textAlign: TextAlign.start,
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        if(productoNuevo.fotosUrl.isNotEmpty)
                                          Expanded(
                                            flex: 1,
                                            child: InkWell(
                                              onTap: () {
                                                final productProvider = Provider.of<ProductProvider>(context, listen: false);
                                                productProvider.setFotos(productoNuevo.fotosUrl);
                                                appRouter.push('/simpleProductPage');
                                              },
                                              child: Image.network(
                                                productoNuevo.fotosUrl[0],
                                                width: double.infinity,
                                                height: 120,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // Sección de Almacenes (fuera del ListView.builder)
                          const Padding(
                            padding: EdgeInsets.only(left: 16.0, top: 10),
                            child: Text(
                              'Almacenes:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _variantes!.isNotEmpty ? _variantes![0].almacenes.length : 0,
                              itemBuilder: (context, index) {
                                var almacenItem = _variantes![0].almacenes[index];
                                return GestureDetector(
                                  onTap: () {
                                    ubicacionProvider.setUbicaciones([]);
                                    seleccionarAlmacen(almacenItem);
                                    ubicacionProvider.setUbicaciones(almacenItem.ubicaciones);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.all(8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: almacenSeleccionado?.almacenId == almacenItem.almacenId 
                                        ? Colors.blue[100] 
                                        : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: almacenSeleccionado?.almacenId == almacenItem.almacenId 
                                          ? Colors.blue 
                                          : Colors.transparent,
                                        width: 2
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          almacenItem.descAlmacen,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Stock: ${almacenItem.stockAlmacen}'),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (almacenSeleccionado!.almacenId != 0)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Text(
                                  'Ubicaciones del almacen ${almacenSeleccionado!.descAlmacen}:',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              if(editUbi)
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: TextButton(
                                  onPressed: () {
                                    Provider.of<ProductProvider>(context, listen: false).setAlmacenUbicacion(almacenSeleccionado!);
                                    appRouter.push('/editUbicaciones');
                                  },
                                  child: const Text('Editar ubicaciones')
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (ubicacionProvider.ubicaciones.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(left: 16.0),
                                  child: Text(
                                    'Ubicación vacía',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              if (ubicacionProvider.ubicaciones.isNotEmpty)
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: ubicacionProvider.ubicaciones.length,
                                  itemBuilder: (context, index) {
                                    var ubicacion = ubicacionProvider.ubicaciones[index];
                                    return ListTile(
                                      title: Text(
                                        '${ubicacion.codUbicacion} ${ubicacion.descUbicacion}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      subtitle: Text('Existencia actual: ${ubicacion.existenciaActualUbi}'),
                                      trailing: TextButton(
                                        onPressed: () {
                                          final productProvider = Provider.of<ProductProvider>(context, listen: false);
                                          productProvider.setUbicacion(
                                            UbicacionAlmacen(
                                              almacenId: almacenSeleccionado!.almacenId,
                                              codUbicacion: ubicacion.codUbicacion,
                                              descripcion: ubicacion.descUbicacion,
                                              almacenUbicacionId: ubicacion.almacenUbicacionId,
                                              capacidad: ubicacion.capacidad,
                                              orden: ubicacion.orden, 
                                              tipoUbicacion: '',
                                            )
                                          );
                                          productProvider.setVoyDesdeMenu(false);
                                          appRouter.push('/inventario');
                                        },
                                        child: const Text('Conteo')
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Codigos ya asignados:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if(editCodBarras)
                                TextButton(
                                  onPressed: () async {
                                    await postCB(context);
                                  },
                                  child: const Text('Agregar codigo +')
                                )
                              ],
                            ),
                          ),
                          if(codigos.isEmpty) ... [
                            const SizedBox(height: 10),
                            const Padding(
                              padding: EdgeInsets.only(left: 16.0),
                              child: Text('Este item no tiene codigos asignados'),
                            )
                          ] else ... [
                            const SizedBox(height: 5),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: codigos.length,
                              itemBuilder: (context, i) {
                                var codigo = codigos[i];
                                return ListTile(
                                  title: Text(codigo.codigoBarra),
                                  trailing: editCodBarras ? IconButton(
                                    onPressed: () async {
                                      await borrarCodBarra(context, codigo);
                                    },
                                    icon: const Icon(Icons.delete, color: Colors.red,)
                                  ) : const SizedBox(),
                                );
                              },
                            ),
                          ],
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> postCB(BuildContext context) async {
    int? statusCode;
    codBarrasController.clear();
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Mensaje'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ingrese el codigo de barras manualmente'),
              const SizedBox(height: 10,),
              CustomTextFormField(
                controller: codBarrasController,
                hint: 'Ingrese codigo',
                maxLines: 1,
              )
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                var trimmed = codBarrasController.text.trim();
                await _qrServices.postCB(context, productoNuevo.variantes[0].codItem, trimmed, token);
                statusCode = await _qrServices.getStatusCode();
                await _qrServices.resetStatusCode();
                if(statusCode == 1) {
                  Carteles.showDialogs(context, "Codigo agregado correctamente", true, false, false);
                  codigos = await QrServices().getCodBarras(context, productoNuevo.variantes[0].codItem, token);
                  setState(() {});
                }
              },
              child: const Text('Agregar'),
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

  Future<void> borrarCodBarra(BuildContext context, CodigoBarras codigo) async {
    int? statusCode;

    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Advertencia'),
          content: Text('Esta por borrar el codigo de barras ${codigo.codigoBarra}. Esta seguro de querer borrarlo?'),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                await _qrServices.deleteCB(context, productoNuevo.variantes[0].codItem, codigo.codBarraId, token);
                statusCode = await _qrServices.getStatusCode();
                await _qrServices.resetStatusCode();
                if(statusCode == 1) {
                  Carteles.showDialogs(context, 'Codigo de barras borrado correctamente', true, false, false);
                  codigos.removeWhere((CodigoBarras element) => element.codBarraId == codigo.codBarraId);
                  setState(() {
                    
                  });
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