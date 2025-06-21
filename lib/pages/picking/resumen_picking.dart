import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:deposito/services/picking_services.dart';

class SummaryScreen extends StatelessWidget {
  final List<PickingLinea>? processedLines;
  const SummaryScreen({super.key, required this.processedLines});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    final ordenPicking = provider.ordenPickingInterna;
    final token = provider.token;
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colors.primary,
          title: Text('Resumen de Picking', style: TextStyle(color: colors.onPrimary),),
          leading: BackButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.settings.name == '/pickingInterno');
            },
          ),
          iconTheme: IconThemeData(color: colors.onPrimary),
        ),
        body: processedLines!.isEmpty
            ? const Center(child: Text('No hay líneas procesadas'))
            : _buildSummaryList(processedLines!),
        bottomNavigationBar: Row(
          children: [
            Expanded(
              child: Container(
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
            Expanded(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () async {
                    _pausarPicking(context, provider, ordenPicking, token);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: colors.primary,
                  ),
                  child: Text(
                    'Pausar Picking',
                    style: TextStyle(fontSize: 16, color: colors.onPrimary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryList(List<PickingLinea> lines) {
    final lineasPadre = lines.where((line) => line.tipoLineaAdicional == "C" && line.lineaIdOriginal == 0).toList();
    final lineasHijas = lines.where((line) => line.tipoLineaAdicional == "C" && line.lineaIdOriginal != 0).toList();
    final lineasNormales = lines.where((line) => line.tipoLineaAdicional != "C").toList();

    int totalPedido = 0;
    int totalPickeado = 0;
    
    for (var line in lines) {
      totalPedido += line.cantidadPedida;
      totalPickeado += line.cantidadPickeada;
    }

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Resumen General',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
        
        Expanded(
          child: ListView(
            children: [
              ...lineasNormales.map((line) => _buildLineCard(line)),
              
              ...lineasPadre.map((padre) {
                final hijos = lineasHijas.where((hija) => 
                  hija.lineaIdOriginal == padre.pickLineaId).toList();
                
                if (hijos.isEmpty) return const SizedBox.shrink();
                
                return Card(
                  margin: const EdgeInsets.all(16),
                  child: Builder(
                    builder: (context) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          unselectedWidgetColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          title: SizedBox(
                            width: double.infinity,
                            child: Text(
                              padre.descripcion,
                              style: const TextStyle(fontSize: 16),
                              softWrap: true,
                            ),
                          ),
                          subtitle: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Código: ${padre.codItem}'),
                              const Spacer(),
                              Text('Pedido: ${padre.cantidadPedida}'),
                            ],
                          ),
                          children: hijos.map((hija) => _buildLineCard(hija)).toList(),
                        ),
                      );
                    },
                  )
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLineCard(PickingLinea line) {
    final isComplete = line.cantidadPickeada >= line.cantidadPedida;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    line.descripcion,
                    style: const TextStyle(fontSize: 16),
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
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pedido:'),
                Text('${line.cantidadPedida}'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pickeado:'),
                Text('${line.cantidadPickeada}'),
              ],
            ),
            if (line.ubicaciones.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Ubicaciones:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...line.ubicaciones.map((ubicacion) => Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('- ${ubicacion.codUbicacion} (Stock: ${ubicacion.existenciaActual})'),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _completarPicking(BuildContext context, ProductProvider provider, OrdenPicking ordenPicking, String token) async {
    try {
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

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final orderProvider = await PickingServices().putOrderPicking(
        context, 
        ordenPicking.pickId, 
        'cerrado', 
        token
      );

      Navigator.of(context).pop();
      
      if (orderProvider.pickId != 0) {
        provider.setOrdenPickingInterna(OrdenPicking.empty());
        provider.resetLineasPicking();
        provider.resetCurrentLineIndex();
        Navigator.of(context).popUntil((route) => route.settings.name == '/pickingInterno');
        
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
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _pausarPicking(BuildContext context, ProductProvider provider, OrdenPicking ordenPicking, String token) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar'),
          content: const Text('¿Estás seguro que deseas pausar el picking?'),
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

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await PickingServices().cerrarTarea(context, ordenPicking.pickId, token);
      Navigator.of(context).pop();
      
      provider.setOrdenPickingInterna(OrdenPicking.empty());
      provider.resetLineasPicking();
      provider.resetCurrentLineIndex();
      Navigator.of(context).popUntil((route) => route.settings.name == '/pickingInterno');
      
      if (!Navigator.of(context).canPop()) {
        final router = GoRouter.of(context);
        router.go('/pickingInterno');
      }
      
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}