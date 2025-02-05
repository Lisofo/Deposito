// ignore_for_file: overridden_fields

import 'package:deposito/models/product.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/product_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProductSearchDelegate extends SearchDelegate {
  @override
  final String searchFieldLabel;
  final List<Product> historial;
  ProductSearchDelegate(this.searchFieldLabel, this.historial,);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
      IconButton(
        onPressed: () => close(context, null),
        icon: const Icon(Icons.more_horiz)
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back_ios_new),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Text('No hay criterios de búsqueda');
    }

    final productServices = ProductServices();
    final token = context.watch<ProductProvider>().token;
    final almacen = context.watch<ProductProvider>().almacen;

    return FutureBuilder(
      // Especifica explícitamente el tipo de dato para el FutureBuilder
      future: productServices.getProductByName(context, query, '2', almacen.almacenId.toString(), '', '0', token),
      builder: (_, AsyncSnapshot snapshot) {
        if (snapshot.hasError) {
          return const ListTile(
            title: Text('No hay ningún producto con ese nombre'),
          );
        }

        if (snapshot.hasData) {
          return _showClient(snapshot.data!);
        } else {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 4),
          );
        }
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _showClient(historial);
  }

  Widget _showClient(List<Product> products) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, i) {
        final producto = products[i];
        return ListTile(
          title: Text(producto.raiz),
          subtitle: Text(producto.descripcion),
          onTap: () {
            Provider.of<ProductProvider>(context, listen: false).setProduct(producto);
            close(context, producto);
          },
        );
      }
    );
  }
}
