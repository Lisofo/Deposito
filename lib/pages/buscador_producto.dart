// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:deposito/config/router/routes.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:provider/provider.dart';

class BuscadorProducto extends StatelessWidget {
  List listProducts = [
    'Pantalon Joker',
    'Coca-Cola',
    'Galletitas Oreo',
    'X-Box 720',
  ];

  BuscadorProducto({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton.filledTonal(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(colors.primary)
            ),
            onPressed: () async {
              router.go('/almacen/menu');
            },
            icon: const Icon(Icons.arrow_back,),
          ),
          title: Text('Buscar Producto',
            style: TextStyle(
              fontSize: 24,
              color: colors.onPrimary
            )
          ),
          elevation: 0,
          backgroundColor: colors.primary,
          iconTheme: IconThemeData(color: colors.onPrimary),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(border: Border.all()),
                  child: const TextField(
                    decoration: InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.search)),
                  ),
                ),
                const SizedBox(height: 10,),
                Expanded(
                  flex: 2,
                  child: ListView.builder(
                    itemCount: listProducts.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        onTap: () {
                          Provider.of<ProductProvider>(context,listen: false).setProducto(listProducts[index]);
                          router.go('/buscadorProducto/paginaProducto');
                        },
                        leading: const Icon(
                          Icons.inventory,
                          size: 42,
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          size: 50,
                        ),
                        title: Text(listProducts[index]),
                        subtitle: const Text('Stock: 4'),
                      );
                    },
                  ),
                ),
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}
