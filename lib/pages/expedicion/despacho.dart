import 'package:deposito/config/router/pages.dart';
import 'package:deposito/models/bulto.dart';
import 'package:deposito/services/entrega_services.dart';
import 'package:flutter/material.dart';

class DespachoPage extends StatefulWidget {
  const DespachoPage({super.key});

  @override
  DespachoPageState createState() => DespachoPageState();
}

class DespachoPageState extends State<DespachoPage> {
  List<Bulto> selectedBultos = [];
  List<Bulto> bultos = [];
  final TextEditingController _retiraController = TextEditingController();
  final TextEditingController _comentarioController = TextEditingController();
  String token = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    _retiraController.dispose();
    _comentarioController.dispose();
    super.dispose();
  }

  loadData() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    token = productProvider.token;
    bultos = await EntregaServices().getBultos(context, token);
    for (var bulto in bultos) {
      print(bulto.bultoId);
    }
    setState(() {
      
    });
  }

  void _precargarBultos() {
    final List<Bulto> listaTemp = [];
    final now = DateTime.now();
    
    for (int i = 1; i <= 20; i++) {
      listaTemp.add(
        Bulto(
          bultoId: i,
          entregaId: 1000 + i,
          clienteId: i % 5 + 1,
          nombreCliente: 'Cliente ${i % 5 + 1}',
          fechaDate: now.subtract(Duration(days: i % 7)),
          fechaBulto: now.subtract(Duration(hours: i * 2)),
          estado: _obtenerEstado(i),
          almacenId: i % 2 + 1,
          tipoBultoId: i % 4 + 1,
          armadoPorUsuId: 1,
          contenido: _generarContenidoBulto(i),
          nroBulto: i,
          totalBultos: 20,
          direccion: 'Calle ${i + 100}, Ciudad ${i % 3 + 1}',
          localidad: 'Localidad ${i % 4 + 1}',
        ),
      );
    }
    
    setState(() {
      bultos = listaTemp;
    });
  }

  String _obtenerEstado(int index) {
    switch (index % 3) {
      case 0: return 'Pendiente';
      case 1: return 'Preparado';
      case 2: return 'Listo';
      default: return 'Pendiente';
    }
  }

  List<BultoItem> _generarContenidoBulto(int bultoId) {
    return List.generate(
      bultoId % 5 + 1, // Entre 1 y 5 items
      (index) => BultoItem(
        bultoLinId: bultoId * 100 + index + 1,
        bultoId: bultoId,
        pickLineaId: bultoId * 10 + index + 1,
        cantidad: index + 1,
        cantidadMaxima: index + 3,
        codigoRaiz: 'ART$bultoId',
        codigo: 'ART$bultoId-${index + 1}',
        descripcion: 'Artículo de prueba $bultoId-${index + 1}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        title: Text(
          context.read<ProductProvider>().menuTitle,
          style: TextStyle(color: colors.onPrimary),
        ),
        iconTheme: IconThemeData(color: colors.onPrimary),
        actions: [
          if (selectedBultos.isNotEmpty)
            Chip(
              label: Text('${selectedBultos.length}'),
              backgroundColor: Colors.blueAccent,
              labelStyle: const TextStyle(color: Colors.white),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: bultos.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: bultos.length,
                    itemBuilder: (context, index) => _buildBultoItem(bultos[index]),
                  ),
          ),
          if (selectedBultos.isNotEmpty) _buildDespacharButton(),
        ],
      ),
    );
  }

  Widget _buildBultoItem(Bulto bulto) {
    final isSelected = selectedBultos.contains(bulto);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      color: isSelected ? Colors.blue[50] : null,
      child: InkWell(
        onTap: () => _toggleSeleccionBulto(bulto),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bulto #${bulto.bultoId}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    bulto.estado,
                    style: TextStyle(
                      color: _getEstadoColor(bulto.estado),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Cliente: ${bulto.nombreCliente}'),
              Text('Dirección: ${bulto.direccion}'),
              Text('Localidad: ${bulto.localidad}'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${bulto.contenido.length} items'),
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSeleccionBulto(bulto),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'Pendiente': return Colors.orange;
      case 'Preparado': return Colors.blue;
      case 'Listo': return Colors.green;
      default: return Colors.grey;
    }
  }

  void _toggleSeleccionBulto(Bulto bulto) {
    setState(() {
      if (selectedBultos.contains(bulto)) {
        selectedBultos.remove(bulto);
      } else {
        selectedBultos.add(bulto);
      }
    });
  }

  Widget _buildDespacharButton() {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(25, 50),
          backgroundColor: colors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: _showDespachoDialog,
        child: Text(
          'DESPACHAR (${selectedBultos.length})',
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }

  void _showDespachoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Despacho'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _retiraController,
                  decoration: const InputDecoration(
                    labelText: 'Persona que retira',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _comentarioController,
                  decoration: const InputDecoration(
                    labelText: 'Comentarios adicionales',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Text(
                  'Bultos a despachar:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...selectedBultos.map((bulto) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.inventory, size: 20),
                  title: Text('Bulto #${bulto.bultoId}'),
                  subtitle: Text('Cliente: ${bulto.nombreCliente}'),
                )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () {
              _procesarDespacho();
              Navigator.pop(context);
            },
            child: const Text('CONFIRMAR DESPACHO'),
          ),
        ],
      ),
    );
  }

  void _procesarDespacho() {
    final retira = _retiraController.text.trim();
    // ignore: unused_local_variable
    final comentario = _comentarioController.text.trim();

    if (retira.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe ingresar el nombre de quien retira'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Simular procesamiento
    Future.delayed(const Duration(milliseconds: 500), () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selectedBultos.length} bultos despachados a $retira'),
          duration: const Duration(seconds: 3),
        ),
      );

      setState(() {
        selectedBultos.clear();
        _retiraController.clear();
        _comentarioController.clear();
      });
    });
  }

  
}