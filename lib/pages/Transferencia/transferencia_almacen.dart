import 'package:deposito/search/product_search_delegate.dart';
import 'package:deposito/services/almacen_services.dart';
import 'package:deposito/widgets/custom_speed_dial.dart';
import 'package:deposito/widgets/escaner_pda.dart';
import 'package:deposito/widgets/ubicacion_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/ubicacion_almacen.dart';
import 'package:deposito/models/product.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/product_services.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:deposito/widgets/custom_button.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class TransferenciaAlmacenPage extends StatefulWidget {
  const TransferenciaAlmacenPage({super.key});

  @override
  State<TransferenciaAlmacenPage> createState() => _TransferenciaAlmacenPageState();
}

class _TransferenciaAlmacenPageState extends State<TransferenciaAlmacenPage> {
  late Almacen almacen;
  late String token;
  late UbicacionAlmacen ubicacionOrigen = UbicacionAlmacen.empty();
  TextEditingController textController = TextEditingController();
  FocusNode focoDeScanner = FocusNode();
  List<ProductoAAgregar> productosEscaneados = [];
  List<UbicacionAlmacen> listaUbicaciones = [];
  bool ubicacionEscaneada = false;
  late String valorUbicacion = '';
  List<Product> historial = [];
  late Product selectedProduct = Product.empty();
  late bool camera = false;
  late bool enMano = false;
  late bool hayEnMano = false;
  final _almacenServices = AlmacenServices();
  
  // Nuevas variables de estado
  bool _modoSeleccionado = false;
  bool _esModoCarrito = false;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    final productProvider = context.read<ProductProvider>();
    almacen = productProvider.almacen;
    token = productProvider.token;
    camera = productProvider.camera;
    await cargarListaUsuarios(productProvider);
    for(var ubicacion in listaUbicaciones) {
      hayEnMano = ubicacion.codUbicacion == 'USER${productProvider.uId}';
      if(hayEnMano){
        break;
      }
    }
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

  void _seleccionarModo(bool esCarrito) {
    setState(() {
      _modoSeleccionado = true;
      _esModoCarrito = esCarrito;
    });
  }

  void _volverASeleccionModo() {
    setState(() {
      _modoSeleccionado = false;
      _esModoCarrito = false;
      _resetSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Scaffold(
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
              if (_modoSeleccionado) {
                _volverASeleccionModo();
              } else {
                appRouter.pop();
              }
            },
            icon: Icon(_modoSeleccionado ? Icons.arrow_back : Icons.arrow_back),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          backgroundColor: colors.primary,
          actions: [
            if (_modoSeleccionado)
              IconButton(
                onPressed: () async {
                  await agregarDesdeDelegate(context);
                },
                icon: const Icon(Icons.search)
              )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _modoSeleccionado ? _buildInterfazTransferencia(colors) : _buildSeleccionModo(colors),
        ),
        floatingActionButton: _modoSeleccionado ? _buildSpeedDial(colors) : null,
      ),
    );
  }

  Widget _buildSeleccionModo(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomButton(
            text: 'Transferir al contenedor',
            onPressed: () => _seleccionarModo(true),
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: 'Transferir a ubicación final',
            onPressed: () => _seleccionarModo(false),
          ),
        ],
      ),
    );
  }

  Widget _buildInterfazTransferencia(ColorScheme colors) {
    return Column(
      children: [
        // Escaneo de ubicación de origen
        Row(
          children: [
            if (hayEnMano && !_esModoCarrito) ...[
              Icon(Icons.shopping_basket_outlined, color: colors.primary),
              Checkbox(
                value: enMano,
                onChanged: (value) {
                  ubicacionOrigen = listaUbicaciones.firstWhere((element) => element.codUbicacion == 'USER${context.read<ProductProvider>().uId}');
                  setState(() {
                    ubicacionEscaneada = value!;
                    enMano = value;
                  });
                }
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: UbicacionDropdown(
                listaUbicaciones: listaUbicaciones,
                selectedItem: ubicacionOrigen.almacenId == 0 ? null : ubicacionOrigen,
                onChanged: (value) {
                  setState(() {
                    ubicacionOrigen = value!;
                    ubicacionEscaneada = true;
                  });
                },
                enabled: (productosEscaneados.isNotEmpty || enMano) ? false : true,
                hintText: 'Seleccione ubicación de origen',
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Lista de productos escaneados
        if (productosEscaneados.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                ubicacionEscaneada || enMano
                    ? 'No hay productos escaneados. Por favor, escanee o busque productos para transferir.'
                    : 'Por favor, escanee o seleccione una ubicación de origen primero.',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        
        if (productosEscaneados.isNotEmpty) ...[
          Text(
            'IMPORTANTE: Indique la cantidad de cada producto escaneado', 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: productosEscaneados.length,
              itemBuilder: (context, index) {
                final productoAAgregar = productosEscaneados[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productoAAgregar.productoAgregado.raiz,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          productoAAgregar.productoAgregado.descripcion,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    subtitle: Text('Cantidad: ${productoAAgregar.cantidad}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editarCantidad(context, productoAAgregar),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              productosEscaneados.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        
        const SizedBox(height: 10),
        EscanerPDA(
          onScan: procesarEscaneoProducto,
          focusNode: focoDeScanner,
          controller: textController
        ),

        // Botón de acción inferior según el modo
        if ((ubicacionEscaneada || enMano) && productosEscaneados.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: _esModoCarrito 
                ? CustomButton(
                    text: 'Transferir al contenedor',
                    onPressed: () => _transferirAlCarrito(context),
                  )
                : CustomButton(
                    text: 'Continuar a destino',
                    onPressed: () {
                      appRouter.push('/transferencia-destino', extra: {
                        'ubicacionOrigen': ubicacionOrigen,
                        'productosEscaneados': productosEscaneados,
                        'onTransferenciaCompletada': () {
                          // Recargar datos después de la transferencia
                          cargarDatos();
                        },
                      });
                    },
                  ),
          ),
      ],
    );
  }

  Widget _buildSpeedDial(ColorScheme colors) {
    return Column(
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
    );
  }

  void _resetSearch() {
    ubicacionOrigen = UbicacionAlmacen.empty();
    productosEscaneados = [];
    ubicacionEscaneada = false;
    enMano = false;
    focoDeScanner.requestFocus();
    setState(() {});
  }

  Future<void> agregarDesdeDelegate(BuildContext context) async {
    final producto = await showSearch(
      context: context,
      delegate: ProductSearchDelegate('Buscar producto', historial)
    );
    
    if (producto != null) {
      final productoExistente = productosEscaneados.firstWhere(
        (p) => p.productoAgregado.raiz == producto.raiz,
        orElse: () => ProductoAAgregar(productoAgregado: Product.empty(), cantidad: 0),
      );
  
      if (productoExistente.productoAgregado.raiz != '') {
        productoExistente.cantidad += 1;
      } else {
        productosEscaneados.add(ProductoAAgregar(productoAgregado: producto, cantidad: 1));
      }
  
      setState(() {
        selectedProduct = producto;
      });
  
      textController.clear();
      await Future.delayed(const Duration(milliseconds: 100));
      focoDeScanner.requestFocus();
    } else {
      setState(() {
        selectedProduct = Product.empty();
      });
    }
  }

  Future<void> procesarEscaneoProducto(String value) async {
    if (value.isNotEmpty) {
      if (!ubicacionEscaneada && !enMano) {
        try {
          final ubicacionEncontrada = listaUbicaciones.firstWhere((element) => element.codUbicacion == value);
          setState(() {
            ubicacionOrigen = ubicacionEncontrada;
            valorUbicacion = ubicacionEncontrada.codUbicacion;
            ubicacionEscaneada = true;
          });
          textController.clear();
          await Future.delayed(const Duration(milliseconds: 100));
          focoDeScanner.requestFocus();
        } catch (e) {
          Carteles.showDialogs(context, 'Ubicación no encontrada', false, false, false);
        }
      } else {
        final productos = await ProductServices().getProductByName(context, '', '2', almacen.almacenId.toString(), value, '0', token);
        if (productos.isNotEmpty) {
          final producto = productos[0];
          final productoExistente = productosEscaneados.firstWhere(
            (p) => p.productoAgregado.raiz == producto.raiz,
            orElse: () => ProductoAAgregar(productoAgregado: Product.empty(), cantidad: 0),
          );
          if (productoExistente.productoAgregado.raiz != '') {
            productoExistente.cantidad += 1;
          } else {
            productosEscaneados.add(ProductoAAgregar(productoAgregado: producto, cantidad: 1));
          }
          setState(() {});
          textController.clear();
          await Future.delayed(const Duration(milliseconds: 100));
          focoDeScanner.requestFocus();
        } else {
          Carteles.showDialogs(context, 'Producto no encontrado', false, false, false);
        }
      }
    }
  }

  Future<void> _editarCantidad(BuildContext context, ProductoAAgregar productoAAgregar) async {
    final cantidadController = TextEditingController(text: productoAAgregar.cantidad.toString());
    var product = productoAAgregar.productoAgregado;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Editar cantidad ${product.raiz} - ${product.descripcion}"),
          content: TextField(
            controller: cantidadController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Cantidad'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final nuevaCantidad = int.tryParse(cantidadController.text) ?? 1;
                if (nuevaCantidad > 0) {
                  setState(() {
                    productoAAgregar.cantidad = nuevaCantidad;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
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
      if (!ubicacionEscaneada && !enMano) {
        try {
          final ubicacionEncontrada = listaUbicaciones.firstWhere((element) => element.codUbicacion == code);
          setState(() {
            ubicacionOrigen = ubicacionEncontrada;
            valorUbicacion = ubicacionEncontrada.codUbicacion;
            ubicacionEscaneada = true;
          });
          textController.clear();
          await Future.delayed(const Duration(milliseconds: 100));
          focoDeScanner.requestFocus();
        } catch (e) {
          Carteles.showDialogs(context, 'Ubicación no encontrada', false, false, false);
        }
      } else {
        final productos = await ProductServices().getProductByName(context, '', '2', almacen.almacenId.toString(), code.toString(), '0', token);
        if (productos.isNotEmpty) {
          final producto = productos[0];
          final productoExistente = productosEscaneados.firstWhere(
            (p) => p.productoAgregado.raiz == producto.raiz,
            orElse: () => ProductoAAgregar(productoAgregado: Product.empty(), cantidad: 0),
          );
          if (productoExistente.productoAgregado.raiz != '') {
            productoExistente.cantidad += 1;
          } else {
            productosEscaneados.add(ProductoAAgregar(productoAgregado: producto, cantidad: 1));
          }
          setState(() {});
          textController.clear();
          await Future.delayed(const Duration(milliseconds: 100));
          focoDeScanner.requestFocus();
        } else {
          Carteles.showDialogs(context, 'Producto no encontrado', false, false, false);
        }
      }
    }
    
    setState(() {});
  }

  Future<void> _transferirAlCarrito(BuildContext context) async {
    int? statusCode;
    for (final productoAAgregar in productosEscaneados) {
      await _almacenServices.postTransferencia(
        context,
        productoAAgregar.productoAgregado.raiz,
        almacen.almacenId,
        ubicacionOrigen.almacenUbicacionId,
        0, // almacenIdDestino = 0 para el carrito
        productoAAgregar.cantidad,
        token,
      );
    }
    statusCode = await _almacenServices.getStatusCode();
    await _almacenServices.resetStatusCode();
    if(statusCode == 1) {
      // Recargar los datos de ubicaciones
      await cargarDatos();
      
      // Reiniciar solo la parte de escaneo, volviendo a la selección de ubicación
      _resetSearch();
      Carteles.showDialogs(context, 'Transferencia al contenedor completada', false, false, false);
    }
  }
}

class ProductoAAgregar {
  late Product productoAgregado;
  late int cantidad;

  ProductoAAgregar({
    required this.productoAgregado,
    this.cantidad = 1,
  });
}