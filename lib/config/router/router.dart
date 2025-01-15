import 'package:deposito/pages/buscador_producto.dart';
import 'package:deposito/pages/login.dart';
import 'package:deposito/pages/menu.dart';
import 'package:deposito/pages/product_page.dart';
import 'package:deposito/pages/seleccion_almacen.dart';
import 'package:deposito/pages/simple_product_page.dart';
import 'package:deposito/pages/version_check_page.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static Future<GoRouter> createAppRouter (String initialLocation) async {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/', builder: (context, state) => const VersionCheckPage()),
        GoRoute(path: '/login', builder: (context, state) => const Login()),
        GoRoute(path: '/almacen', builder: (context, state) => const SeleccionAlmacen(),),
        GoRoute(path: '/menu', builder: (context, state) => const MenuPage(),),
        GoRoute(path: '/buscadorProducto', builder: (context, state) => const BuscadorProducto()),
        GoRoute(path: '/simpleProductPage', builder: (context, state) => const SimpleProductPage()),
        GoRoute(path: '/paginaProducto', builder: (context, state) => const ProductPage()),
      ]
    );
  }
}

late GoRouter appRouter;
