import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/picking_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class SummaryScreen extends StatelessWidget {
  List<PickingLinea> processedLines = [];
  SummaryScreen({super.key, required this.processedLines});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    processedLines = provider.lineasPicking;
    final colors = Theme.of(context).colorScheme;

    for(var line in processedLines) {
      print('${line.descripcion} total pickeado: ${line.cantidadPickeada}');
    }

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Resumen de Picking', style: TextStyle(color: colors.onPrimary)),
          automaticallyImplyLeading: false,
          backgroundColor: colors.primary,
        ),
        body: processedLines.isEmpty
            ? const Center(child: Text('No hay líneas procesadas'))
            : _buildSummaryList(processedLines),
        bottomNavigationBar: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () async {
              await _completarPicking(context, provider);
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

  // Agregar este método a la clase SummaryScreen:
  Future<void> _completarPicking(BuildContext context, ProductProvider provider) async {
    final pickingServices = PickingServices();
    final String token = context.read<ProductProvider>().token; // Ajusta según cómo obtienes el token
    
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // Hacer patchPicking por cada línea procesada
      for (var line in processedLines) {
        // Hacer patch por cada ubicación (incluso si existenciaActual es 0)
        for (var ubicacion in line.ubicaciones) {
          await pickingServices.patchPicking(
            context,
            line.pickId, // ID del picking
            line.codItem, // Código del item
            ubicacion.almacenUbicacionId, // ID de la ubicación
            line.cantidadPickeada, // Cantidad pickeada (puede ser 0)
            token
          );
          
          // Verificar si el patch fue exitoso
          int? statusCode = await pickingServices.getStatusCode();
          if (statusCode != 1) {
            // Si hay error, salir del bucle
            Navigator.of(context).pop(); // Cerrar loading
            return;
          }
        }
      }

      // Cerrar loading
      Navigator.of(context).pop();
      
      // Reset y navegación
      provider.resetLineasPicking();
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/pickingInterno', 
        (route) => false
      );
      
    } catch (e) {
      // Cerrar loading en caso de error
      Navigator.of(context).pop();
      
      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al completar picking: $e'),
          backgroundColor: Colors.red,
        ),
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
                        Row(
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