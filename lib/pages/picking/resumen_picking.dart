import 'package:deposito/models/orden_picking.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class SummaryScreen extends StatelessWidget {
  List<PickingLinea> processedLines = [];

  SummaryScreen({super.key, required this.processedLines});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Resumen de Picking', style: TextStyle(color: colors.onPrimary),),
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
            onPressed: () {
              // Volver al menú principal
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/pickingInterno', 
                (route) => false
              );
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
                final isComplete = (line.cantidadPickeada) >= line.cantidadPedida;
                
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