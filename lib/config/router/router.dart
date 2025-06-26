import 'pages.dart';

class AppRouter {
  static Future<GoRouter> createAppRouter(String initialLocation) async {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/', builder: (context, state) => const VersionCheckPage()),
        GoRoute(path: '/login', builder: (context, state) => const Login()),
        GoRoute(path: '/almacen', builder: (context, state) => const SeleccionAlmacen()),
        GoRoute(path: '/menu', builder: (context, state) => const MenuPage()),
        GoRoute(path: '/config', builder: (context, state) => const ConfigPage()),
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
        GoRoute(path: '/picking-TE', builder: (context, state) => const ListaPicking()),
        GoRoute(path: '/picking-C', builder: (context, state) => const ListaPicking()),
        GoRoute(path: '/picking-V', builder: (context, state) => const ListaPicking()),
        GoRoute(path: '/picking-P', builder: (context, state) => const ListaPicking()),
        GoRoute(path: '/picking-TS', builder: (context, state) => const ListaPicking()),
        GoRoute(path: '/picking-V,P,TS', builder: (context, state) => const ListaPicking()),
        GoRoute(path: '/pickingInterno', builder: (context, state) => const PedidoInterno()),
        GoRoute(path: '/pickingProductos', builder: (context, state) => const PickingPage()),
        GoRoute(path: '/pickingProductosConteo', builder: (context, state) => const PickingProducts()),
        GoRoute(
          path: '/resumenPicking',
          builder: (context, state) {
            final provider = Provider.of<ProductProvider>(context, listen: false);
            final lines = provider.lineasPicking;
            return SummaryScreen(processedLines: lines);
          },
        ),
        GoRoute(path: '/pickingCompra', builder: (context, state) => const PickingCompra(),),
        GoRoute(path: '/pickingProductosCompra', builder: (context, state) => const PickingProductsEntrada()),
        GoRoute(path: '/monitor', builder: (context, state) => const MonitorPage()),
        GoRoute(path: '/qrPage', builder: (context, state) => const QrPage()),
      ],
    );
  }
}

late GoRouter appRouter;