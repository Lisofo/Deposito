import 'package:deposito/provider/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:deposito/config/router/routes.dart';
import 'package:provider/provider.dart';

class SeleccionAlmacen extends StatefulWidget {
  const SeleccionAlmacen({super.key});

  @override
  State<SeleccionAlmacen> createState() => _SeleccionAlmacenState();
}

class _SeleccionAlmacenState extends State<SeleccionAlmacen> {

  List<String> almacenes = ['Almacén 1', 'Almacén 2', 'Almacén 3'];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Seleccione almacén', style: TextStyle(color: colors.onPrimary),),
          backgroundColor: colors.primary,
          iconTheme: IconThemeData(color: colors.onPrimary)
        ),
        body: Center(
          child: ListView.separated(
            itemCount: almacenes.length,
            itemBuilder: (context, i) { 
              return ListTile(
                title: Text(almacenes[i], style: const TextStyle(fontSize: 18),),
                onTap: () {
                  router.go('/almacen/menu');
                },
              );
            }, 
            separatorBuilder: (BuildContext context, int index) { return const Divider(); },
          ),
        )
      ),
    );
  }

  Widget buildInkWell(BuildContext context, String route, String imagePath) {
    return InkWell(
      onTap: () {
        Provider.of<ProductProvider>(context, listen: false).setAlmacen('18');
        router.go(route);
      },
      child: Container(
        height: 200,
        width: 380,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 50),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(30)),
        child: Image.asset(imagePath),
      ),
    );
  }
}
