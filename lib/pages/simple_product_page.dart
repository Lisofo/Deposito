import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/producto_deposito.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/product_services.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';

class SimpleProductPage extends StatefulWidget {
  static const String name = 'simple_product_page';
  const SimpleProductPage({super.key});

  @override
  State<SimpleProductPage> createState() => _SimpleProductPageState();
}

class _SimpleProductPageState extends State<SimpleProductPage> {
  late String raiz = '';
  late List fotos = [];
  ProductoDeposito productoNuevo = ProductoDeposito.empty();
  late Almacen almacen = Almacen.empty();
  late String token = '';
  late int currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentIndex);
    cargarDatos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  cargarDatos() async {
    almacen = context.read<ProductProvider>().almacen;
    token = context.read<ProductProvider>().token;
    raiz = context.read<ProductProvider>().raiz;
    fotos = context.read<ProductProvider>().fotos;
    productoNuevo = await ProductServices().getProductoDeposito(context, raiz, token);
    setState(() {});
  }

  void _scrollToIndex(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          raiz,
          style: TextStyle(
            color: colores.onPrimary,
          ),
        ),
        backgroundColor: colores.primary,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (fotos.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                productoNuevo.descripcion,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.98,
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: PhotoViewGallery.builder(
                    itemCount: fotos.length,
                    builder: (context, index) {
                      return PhotoViewGalleryPageOptions(
                        imageProvider: NetworkImage(fotos[index]),
                      );
                    },
                    onPageChanged: (index) {
                      setState(() {
                        currentIndex = index;
                      });
                    },
                    pageController: _pageController,
                    scrollPhysics: const BouncingScrollPhysics(),
                    backgroundDecoration: BoxDecoration(
                      color: Theme.of(context).canvasColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(fotos.length, (index) {
                  return GestureDetector(
                    onTap: () {
                      _scrollToIndex(index);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Container(
                        width: 16.0,
                        height: 16.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentIndex == index ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ] else ...[
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Cargando...'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}