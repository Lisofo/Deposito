import 'package:deposito/provider/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:deposito/config/router/router.dart';
import 'package:deposito/widgets/drawer.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    String almacen = context.watch<ProductProvider>().almacenNombre;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colors.primary,
          title: Text(
            almacen,
            style: TextStyle(color: colors.surface),
          ),
          iconTheme: IconThemeData(color: colors.onPrimary),
          actions: [
            IconButton.filledTonal(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(colors.primary)
              ),
              onPressed: () async {
                await logout();
              },
              icon: const Icon(Icons.logout,),
              tooltip: 'Logout',
            ),
            IconButton.filledTonal(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(colors.primary)
              ),
              onPressed: () async {
                appRouter.pop();
              },
              icon: const Icon(Icons.arrow_back_ios_new,),
              tooltip: 'Cambiar almacén',
            )
    
            
          ],
        ),
        drawer: Drawer(
          backgroundColor: colors.surface,
          child: const BotonesDrawer(),
        ),
        body: const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // if (MediaQuery.of(context).size.height > MediaQuery.of(context).size.width) ... [
              //   Center(
              //     child: Image.asset(
              //       'images/familcarLogo.png',
              //       fit: BoxFit.fill,
              //     ),
              //   )
              // ] else ... [
              //   Center(
              //     child: Image.asset(
              //       'images/familcarLogo.png',
              //       fit: BoxFit.fill,
              //     ),
              //   )
              // ],
            ],
          ),
        ),
        bottomNavigationBar: Container(
          width: double.infinity, // Ocupa todo el ancho de la pantalla
          color: colors.primary, // Color de fondo del contenedor
          padding: const EdgeInsets.all(8.0), // Espaciado interno
          child: FutureBuilder(
            future: PackageInfo.fromPlatform(),
            builder: (BuildContext context, AsyncSnapshot<PackageInfo> snapshot) {
              if (snapshot.hasData) {
                return Column(
                  mainAxisSize: MainAxisSize.min, // Ajusta el tamaño al contenido
                  children: [
                    Text(
                      'Versión ${snapshot.data!.version} (Build ${snapshot.data!.buildNumber})',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const Text(
                      '2025.03.06+1',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                );
              } else {
                return const Text(
                  'Cargando la app...',
                  style: TextStyle(color: Colors.white),
                );
              }
            },
          ),
        )
      )
    );
  }

  logout() {
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cerrar sesion'),
          content: const Text('Esta seguro de querer cerrar sesion?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar')
            ),
            TextButton(
              onPressed: () {
                //Provider.of<OrdenProvider>(context, listen: false).setToken('');
                appRouter.go('/login');
                Navigator.of(context).pop();
              },
              child: Text(
                'Cerrar Sesion',
                style: TextStyle(color: colors.onError),
              )
            ),
          ],
        );
      },
    );
  }
}