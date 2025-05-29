import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/pages/Productos/agregar_ubicaciones.dart';
import 'package:deposito/pages/Productos/buscador_producto.dart';
import 'package:deposito/pages/Dashboard/dashboard.dart';
import 'package:deposito/pages/Productos/edit_ubicaciones.dart';
import 'package:deposito/pages/Inventario/editar_inventario.dart';
import 'package:deposito/pages/Inventario/inventario.dart';
import 'package:deposito/pages/consultaUbicaciones/consulta_ubicaciones.dart';
import 'package:deposito/pages/login&menu/login.dart';
import 'package:deposito/pages/login&menu/menu.dart';
import 'package:deposito/pages/Productos/product_page.dart';
import 'package:deposito/pages/Inventario/revisar_inventario.dart';
import 'package:deposito/pages/picking/pedido_interno.dart';
import 'package:deposito/pages/picking/pedidos.dart';
import 'package:deposito/pages/picking/picking.dart';
import 'package:deposito/pages/picking/picking_products.dart';
import 'package:deposito/pages/picking/resumen_picking.dart';
import 'package:deposito/pages/resumenInventario/resumen_general_inventario.dart';
import 'package:deposito/pages/resumenInventario/resumen_inventario.dart';
import 'package:deposito/pages/seleccion_almacen.dart';
import 'package:deposito/pages/simple_product_page.dart';
import 'package:deposito/pages/Transferencia/transferencia_almacen.dart';
import 'package:deposito/pages/Transferencia/transferencia_ubicacion_destino.dart'; // Importa la nueva pantalla
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
        // GoRoute(
        //   path: '/buscadorProducto',
        //   builder: (context, state) {
        //     // Obtener el parámetro pasado a través de `extra`
        //     final parametro = state.extra as int? ?? 0; // Valor por defecto si no se pasa nada
        //     return BuscadorProducto(parametro: parametro);
        //   },
        // ),
        GoRoute(path: '/buscadorProducto', builder: (context, state) => const BuscadorProducto()),
        GoRoute(path: '/simpleProductPage', builder: (context, state) => const SimpleProductPage()),
        GoRoute(path: '/paginaProducto', builder: (context, state) => const ProductPage()),
        GoRoute(path: '/editUbicaciones', builder: (context, state) => const EditUbicaciones()),
        GoRoute(path: '/agregarUbicaciones', builder: (context, state) => const AgregarUbicaciones()),
        GoRoute(path: '/inventario', builder: (context, state) => const InventarioPage()),
        GoRoute(path: '/editarInventario', builder: (context, state) => const EditarInventario()),
        GoRoute(path: '/revisarInventario', builder: (context, state) => const RevisarInventario()),
        GoRoute(path: '/dashboard', builder: (context, state) => const DashboardPage()),
        GoRoute(path: '/transferencia', builder: (context, state) => const TransferenciaAlmacenPage()),
        GoRoute(path: '/resumenInventario', builder: (context, state) => const ResumenInventarioPage()),
        GoRoute(path: '/resumenGeneralnventarioPage', builder: (context, state) => const ResumenGeneralInventarioPage()),
        // Nueva ruta para TransferenciaUbicacionDestino
        GoRoute(
          path: '/transferencia-destino',
          builder: (context, state) {
            // Obtener los argumentos pasados a través de `extra`
            final args = state.extra as Map<String, dynamic>;
            return TransferenciaUbicacionDestino(
              ubicacionOrigen: args['ubicacionOrigen'],
              productosEscaneados: args['productosEscaneados'],
            );
          },
        ),
        GoRoute(path: '/consultaUbicaciones', builder: (context, state) => const ConsultaUbicacionesPage()),
        GoRoute(path: '/picking', builder: (context, state) => const ListaPicking()),
        GoRoute(path: '/pickingInterno', builder: (context, state) => const PedidoInterno()),
        GoRoute(path: '/pickingProductos', builder: (context, state) => const PickingPage()),
        GoRoute(path: '/pickingProductosConteo', builder: (context, state) => const PickingProducts()),
        GoRoute(
          path: '/resumenPicking',
          builder: (context, state) {
            final args = state.extra as List<PickingLinea>;
            return SummaryScreen(processedLines: args);
          },
        ),
      ],
    );
  }
}

late GoRouter appRouter;