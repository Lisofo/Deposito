import 'package:deposito/models/almacen.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/almacen_services.dart';
import 'package:flutter/material.dart';
import 'package:deposito/config/router/router.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:deposito/provider/theme_provider.dart';

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
    almacenes.sort((a, b) => a.descripcion.compareTo(b.descripcion));
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            surfaceTintColor: Colors.white,
            title: const Text('¿Desea salir de la aplicación?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('Sí'),
              ),
            ],
          ),
        );
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text('Seleccione almacén', style: TextStyle(color: colors.onPrimary)),
            backgroundColor: colors.primary,
            iconTheme: IconThemeData(color: colors.onPrimary),
            actions: [
              IconButton(
                onPressed: () {
                  appRouter.push('/config');
                },
                icon: Icon(Icons.settings, color: colors.onPrimary,)
              )
            ],
          ),
          body: Center(
            child: ListView.separated(
              itemCount: almacenes.length,
              itemBuilder: (context, i) {
                var almacen = almacenes[i];
                return ListTile(
                  title: Text(almacen.descripcion, style: const TextStyle(fontSize: 18)),
                  leading: CircleAvatar(child: Text(almacen.codAlmacen, style: const TextStyle(fontSize: 14))),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Provider.of<ProductProvider>(context, listen: false).setAlmacen(almacen);
                    Provider.of<ProductProvider>(context, listen: false).setAlmacenNombre(almacen.descripcion);
      
                    // Cambiar el tema usando el color del almacén seleccionado
                    Provider.of<ThemeProvider>(context, listen: false).setThemeFromAlmacen(almacen);
      
                    appRouter.push('/menu');
                  },
                );
              },
              separatorBuilder: (BuildContext context, int index) => const Divider(),
            ),
          ),
        ),
      ),
    );
  }
}
