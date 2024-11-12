import 'package:deposito/models/almacen.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/almacen_services.dart';
import 'package:flutter/material.dart';
import 'package:deposito/config/router/routes.dart';
import 'package:provider/provider.dart';

class SeleccionAlmacen extends StatefulWidget {
  const SeleccionAlmacen({super.key});

  @override
  State<SeleccionAlmacen> createState() => _SeleccionAlmacenState();
}

class _SeleccionAlmacenState extends State<SeleccionAlmacen> {
  List<Almacen> almacenes = [];
  String token = '';

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  cargarDatos() async {
    token = context.read<ProductProvider>().token;
    almacenes = await AlmacenServices().getAlmacenes(context, token);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    almacenes.sort((a, b) =>  a.descripcion.compareTo(b.descripcion),);
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
              var almacen = almacenes[i];
              return ListTile(
                title: Text(almacen.descripcion, style: const TextStyle(fontSize: 18),),
                leading: CircleAvatar(child: Text(almacen.codAlmacen, style: const TextStyle(fontSize: 14),)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Provider.of<ProductProvider>(context, listen: false).setAlmacen(almacen.almacenId.toString());
                  Provider.of<ProductProvider>(context, listen: false).setAlmacenNombre(almacen.descripcion);
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
