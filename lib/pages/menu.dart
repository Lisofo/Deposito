import 'package:deposito/provider/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:deposito/config/router/routes.dart';
import 'package:deposito/widgets/drawer.dart';
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
            style: const TextStyle(color: Colors.white),
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
                router.go('/almacen');
              },
              icon: const Icon(Icons.arrow_back_ios_new,),
              tooltip: 'Cambiar almacén',
            )

            
          ],
        ),
        drawer: const Drawer(
          backgroundColor: Colors.white,
          child: BotonesDrawer(),
        ),
        body: const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Column(
            children: [
              // if (MediaQuery.of(context).size.height > MediaQuery.of(context).size.width) ... [
              //   Center(
              //     child: Image.asset(
              //       'images/nyp-logo.png',
              //       fit: BoxFit.fill,
              //     ),
              //   )
              // ] else ... [
              //   Center(
              //     child: Image.asset(
              //       'images/nyp-logo.png',
              //       fit: BoxFit.fill,
              //     ),
              //   )
              // ],
              Spacer(),
            ],
          ),
        ),
      )
    );
  }

  logout() {
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
                router.go('/');
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cerrar Sesion',
                style: TextStyle(color: Colors.red),
              )
            ),
          ],
        );
      },
    );
  }
}