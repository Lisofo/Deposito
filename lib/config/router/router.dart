import 'package:deposito/pages/agregar_ubicaciones.dart';
import 'package:deposito/pages/buscador_producto.dart';
import 'package:deposito/pages/dashboard.dart';
import 'package:deposito/pages/edit_ubicaciones.dart';
import 'package:deposito/pages/editar_inventario.dart';
import 'package:deposito/pages/inventario.dart';
import 'package:deposito/pages/login.dart';
import 'package:deposito/pages/menu.dart';
import 'package:deposito/pages/product_page.dart';
import 'package:deposito/pages/revisar_inventario.dart';
import 'package:deposito/pages/seleccion_almacen.dart';
import 'package:deposito/pages/simple_product_page.dart';
import 'package:deposito/pages/version_check_page.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static Future<GoRouter> createAppRouter(String initialLocation) async {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/', builder: (context, state) => const VersionCheckPage()),
        GoRoute(path: '/login', builder: (context, state) => const Login()),
        GoRoute(path: '/almacen', builder: (context, state) => const SeleccionAlmacen()),
        GoRoute(path: '/menu', builder: (context, state) => const MenuPage()),
        GoRoute(
          path: '/buscadorProducto',
          builder: (context, state) {
            // Obtener el parámetro pasado a través de `extra`
            final parametro = state.extra as int? ?? 0; // Valor por defecto si no se pasa nada
            return BuscadorProducto(parametro: parametro);
          },
        ),
        GoRoute(path: '/simpleProductPage', builder: (context, state) => const SimpleProductPage()),
        GoRoute(path: '/paginaProducto', builder: (context, state) => const ProductPage()),
        GoRoute(path: '/editUbicaciones', builder: (context, state) => const EditUbicaciones()),
        GoRoute(path: '/agregarUbicaciones', builder: (context, state) => const AgregarUbicaciones()),
        GoRoute(path: '/inventario', builder: (context, state) => const InventarioPage()),
        GoRoute(path: '/editarInventario', builder: (context, state) => const EditarInventario()),
        GoRoute(path: '/revisarInventario', builder: (context, state) => const RevisarInventario()),
        GoRoute(path: '/dashboard', builder: (context, state) => const DashboardPage()),
      ],
    );
  }
}

late GoRouter appRouter;