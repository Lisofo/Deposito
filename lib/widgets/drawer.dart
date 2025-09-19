import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/menu.dart';
import 'package:deposito/models/ubicacion_almacen.dart';
import 'package:deposito/provider/menu_provider.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'icon_string.dart';

class BotonesDrawer extends StatefulWidget {
  const BotonesDrawer({super.key});

  @override
  State<BotonesDrawer> createState() => _BotonesDrawerState();
}

class _BotonesDrawerState extends State<BotonesDrawer> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ordenProvider = context.read<ProductProvider>();
    final menuProvider = context.watch<MenuProvider>();

    return FutureBuilder(
      future: menuProvider.cargarData(context, ordenProvider.token),
      initialData: const [],
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay datos disponibles'));
        } else {
          final List<Ruta> rutas = snapshot.data as List<Ruta>;

          return ListView.builder(
            controller: ScrollController(),
            itemCount: rutas.length,
            itemBuilder: (context, index) {
              final Ruta ruta = rutas[index];
              return ExpansionTile(
                title: Text(
                  ruta.camino,
                  style: const TextStyle(color: Colors.black),
                ),
                collapsedIconColor: colors.secondary,
                iconColor: colors.secondary,
                initiallyExpanded: true,
                children: _filaBotones2(ruta.opciones, context),
              );
            },
          );
        }
      },
    );
  }
}

List<Widget> _filaBotones2(List<Opcion> opciones, BuildContext context) {
  final List<Widget> opcionesRet = [];
  final menuProvider = context.read<MenuProvider>();
  final productProvider = context.read<ProductProvider>();
  final colors = Theme.of(context).colorScheme;

  for (var opt in opciones) {
    final isQuickAccess = menuProvider.isQuickAccess(opt.ruta);
    
    final widgetTemp = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: () {
          productProvider.setMenu(opt.ruta);
          productProvider.setTitle(opt.texto);
          if(opt.ruta == '/inventario') {
            Provider.of<ProductProvider>(context, listen: false).setUbicacion(UbicacionAlmacen.empty());
          }
          appRouter.push(opt.ruta);
        },
        onLongPress: () async {
          if (isQuickAccess) {
            await menuProvider.removeQuickAccess(opt.ruta);
          } else {
            await menuProvider.addQuickAccess(opt.ruta);
          }
          // else if (menuProvider.quickAccessItems.length < 6) {
          //   await menuProvider.addQuickAccess(opt.ruta);
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(content: Text('${opt.texto} agregado a accesos rápidos')),
          //   );
          // } else {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     const SnackBar(content: Text('Máximo 6 accesos rápidos permitidos')),
          //   );
          // }
        },
        child: Row(
          children: [
            getIcon(opt.icon, context, colors.secondary),
            const SizedBox(width: 8),
            TextButton(
              onPressed: null,
              child: Text(
                opt.texto,
                style: const TextStyle(color: Colors.black),
              ),
            ),
            if (isQuickAccess)
              const Icon(Icons.star, color: Colors.amber, size: 16),
          ],
        ),
      ),
    );
    opcionesRet.add(widgetTemp);
  }
  return opcionesRet;
}