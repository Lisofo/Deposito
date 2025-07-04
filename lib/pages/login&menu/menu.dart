import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/menu.dart';
import 'package:deposito/provider/menu_provider.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/widgets/icon_string.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:deposito/widgets/drawer.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  bool _isNavigating = false; // Flag para controlar navegaciones simultáneas

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final menuProvider = context.read<MenuProvider>();
    final productProvider = context.read<ProductProvider>();
    await menuProvider.initialize(context, productProvider.token);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final menuProvider = context.watch<MenuProvider>();
    final productProvider = context.read<ProductProvider>();
    late String name = productProvider.name;
    String almacen = productProvider.almacenNombre;

    if (!menuProvider.isDataReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
              onPressed: () => logout(),
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
            ),
            IconButton.filledTonal(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(colors.primary)
              ),
              onPressed: () => appRouter.pop(),
              icon: const Icon(Icons.arrow_back_ios_new),
              tooltip: 'Cambiar almacén',
            )
          ],
        ),
        drawer: Drawer(
          backgroundColor: colors.surface,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      maxRadius: 13,
                      backgroundColor: colors.primary,
                      child: const Icon(Icons.person),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      name,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ],
                ),
              ),
              const Expanded(child: BotonesDrawer()),
              _buildQuickAccessHelpButton(context),
            ],
          ),
        ),
        body: _buildQuickAccessGrid(context, menuProvider),
        bottomNavigationBar: Container(
          width: double.infinity,
          color: colors.primary,
          padding: const EdgeInsets.all(8.0),
          child: FutureBuilder(
            future: PackageInfo.fromPlatform(),
            builder: (BuildContext context, AsyncSnapshot<PackageInfo> snapshot) {
              if (snapshot.hasData) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Versión ${snapshot.data!.version}',/*(Build ${snapshot.data!.buildNumber})*/
                      style: const TextStyle(color: Colors.white),
                    ),
                    const Text(
                      '2025.07.03+1',
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
        ),
      ),
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context, MenuProvider menuProvider) {
    final size = MediaQuery.of(context).size;
    final productProvider = context.read<ProductProvider>();
    final crossAxisCount = size.width > 800 ? 3 : 2;
    // final isMobile = size.width < 799;

    final quickAccessRoutes = menuProvider.quickAccessItems;
    final allOptions = menuProvider.opciones.expand((ruta) => ruta.opciones).toList();
    var quickAccessOptions = [];
    try {
      quickAccessOptions = quickAccessRoutes.map((route) {
        return allOptions.firstWhere(
          (opt) => opt.ruta == route,
          orElse: () => null,
        );
      }).whereType<Opcion>().toList();
    } catch (e) {
      return Container();
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Accesos Rápidos',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mantén presionado un ítem del menú para agregarlo aquí',
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded( // Asegura que el GridView ocupe el espacio restante
                child: GridView.count(
                  shrinkWrap: false, // Importante: false para que el GridView gestione su propio scroll
                  physics: quickAccessOptions.length > 6 
                    ? const AlwaysScrollableScrollPhysics() // Scroll habilitado en móvil
                    : const NeverScrollableScrollPhysics(), // Scroll deshabilitado en desktop/tablet
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 1.19,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  padding: const EdgeInsets.only(bottom: 20),
                  children: quickAccessOptions.map((opt) => 
                    _buildResponsiveAccessButton(context, opt, productProvider, size)
                  ).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveAccessButton(BuildContext context, Opcion opt, ProductProvider productProvider, Size screenSize) {
    final buttonSize = screenSize.width > 800 ? 85.0 : 80.0;
    final iconSize = screenSize.width > 800 ? 26.0 : 24.0;
    final fontSize = screenSize.width > 800 ? 13.0 : 12.0;
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _isNavigating 
            ? null
            : () async {
                setState(() => _isNavigating = true);
                try {
                  productProvider.setMenu(opt.ruta);
                  productProvider.setTitle(opt.texto);
                  await appRouter.push(opt.ruta);
                } finally {
                  if (mounted) {
                    setState(() => _isNavigating = false);
                  }
                }
              },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  alignment: Alignment.center,
                  child: getIcon(opt.icon, context, colors.secondary),
                ),
                const SizedBox(height: 6),
                Text(
                  opt.texto,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessHelpButton(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.settings),
      title: const Text('Configurar accesos rápidos'),
      onTap: () => _showQuickAccessHelp(context),
    );
  }

  void _showQuickAccessHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurar accesos rápidos'),
        content: const Text(
          'Para agregar o quitar accesos rápidos:\n\n'
          '1. Abre el menú lateral\n'
          '2. Mantén presionado un ítem del menú'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void logout() {
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Está seguro de querer cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar')
            ),
            TextButton(
              onPressed: () {
                appRouter.go('/login');
                Navigator.of(context).pop();
              },
              child: Text(
                'Cerrar Sesión',
                style: TextStyle(color: colors.onError),
              )
            ),
          ],
        );
      },
    );
  }
}