import 'package:flutter/material.dart';
import 'package:deposito/config/router/routes.dart';
import 'package:deposito/widgets/drawer.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colors.primary,
          title: const Text(
            'Menú',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: IconThemeData(color: colors.onPrimary),
          actions: [
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 8, 15, 8),
              child: Text('Almacén 1',style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
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
        body: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            children: [
              if (MediaQuery.of(context).size.height > MediaQuery.of(context).size.width) ... [
                Center(
                  child: Image.asset(
                    'images/trackit.jpg',
                    fit: BoxFit.fill,
                  ),
                )
              ] else ... [
                Center(
                  child: Image.asset(
                    'images/trackit.jpg',
                    fit: BoxFit.fill,
                  ),
                )
              ],
              const Spacer(),
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