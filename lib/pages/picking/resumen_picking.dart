// resumen_picking.dart (cambios completos)

import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:deposito/services/picking_services.dart';

// ignore: must_be_immutable
class SummaryScreen extends StatelessWidget {
  List<PickingLinea>? processedLines = [];
  SummaryScreen({super.key, required this.processedLines});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    processedLines = provider.lineasPicking;
    final colors = Theme.of(context).colorScheme;
    final ordenPicking = provider.ordenPickingInterna;
    final token = provider.token;

    for(var line in processedLines!) {
      print('${line.descripcion} total pickeado: ${line.cantidadPickeada}');
    }

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Resumen de Picking', style: TextStyle(color: colors.onPrimary)),
          backgroundColor: colors.primary,
          iconTheme: IconThemeData(color: colors.onPrimary),
          leading: BackButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.settings.name == '/pickingInterno');
            },
          ),
        ),
        body: processedLines!.isEmpty
            ? const Center(child: Text('No hay líneas procesadas'))
            : _buildSummaryList(processedLines!),
        bottomNavigationBar: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () async {
              await _completarPicking(context, provider, ordenPicking, token);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: colors.primary,
            ),
            child: Text(
              'Completar Picking',
              style: TextStyle(fontSize: 16, color: colors.onPrimary),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _completarPicking(BuildContext context, ProductProvider provider, OrdenPicking ordenPicking, String token) async {
    try {
      // Mostrar diálogo de confirmación
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar'),
          content: const Text('¿Estás seguro que deseas completar el picking?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Mostrar indicador de progreso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Hacer el PUT para cerrar la orden
      final orderProvider = await PickingServices().putOrderPicking(
        context, 
        ordenPicking.pickId, 
        'cerrado', 
        token
      );

      // Navegar de regreso
      Navigator.of(context).pop(); // Cerrar el diálogo de progreso
      
      if (orderProvider.pickId != 0) {
        provider.setOrdenPickingInterna(OrdenPicking.empty());
        provider.resetLineasPicking();
        provider.resetCurrentLineIndex();
        
        // Usar popUntil para volver a pedido_interno eliminando resumen_picking del stack
        Navigator.of(context).popUntil((route) => route.settings.name == '/pickingInterno');
        
        // Si no existe en el stack, entonces navegamos normalmente
        if (!Navigator.of(context).canPop()) {
          final router = GoRouter.of(context);
          router.go('/pickingInterno');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al completar el picking')),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Cerrar el diálogo de progreso en caso de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Widget _buildSummaryList(List<PickingLinea> lines) {
    // Calcular totales generales
    int totalPedido = 0;
    int totalPickeado = 0;
    
    for (var line in lines) {
      totalPedido += line.cantidadPedida;
      totalPickeado += line.cantidadPickeada;
    }

    return Column(
      children: [
        // Resumen general
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Resumen General',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Pedido:'),
                    Text('$totalPedido'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Pickeado:'),
                    Text('$totalPickeado'),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Porcentaje completado:'),
                    Text('${((totalPickeado / totalPedido) * 100).toStringAsFixed(1)}%'),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Lista detallada
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListView.builder(
              itemCount: lines.length,
              itemBuilder: (context, index) {
                final line = lines[index];
                final isComplete = line.cantidadPickeada >= line.cantidadPedida;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.contain,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                line.descripcion,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                isComplete ? Icons.check_circle : Icons.warning,
                                color: isComplete ? Colors.green : Colors.orange,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Código: ${line.codItem}'),
                        Text('ID: ${line.itemId}'),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Cantidad Pedida:'),
                            Text('${line.cantidadPedida}'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Cantidad Pickeada:'),
                            Text('${line.cantidadPickeada}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (line.ubicaciones.isNotEmpty)
                          const Text(
                            'Ubicaciones:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ...line.ubicaciones.map((ubicacion) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '- Ubicación ID: ${ubicacion.almacenUbicacionId} (Pickeado: ${ubicacion.existenciaActual})',
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}