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
    bultos = await EntregaServices().getBultos(context, token, estado: 'CERRADO');
    for (var bulto in bultos) {
      print(bulto.bultoId);
    }
    setState(() {
      
    });
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
                  // Text('${bulto.contenido.length} items'),
                  const SizedBox(),
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

  void _procesarDespacho() async {
    final retira = _retiraController.text.trim();
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

    if (selectedBultos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay bultos seleccionados para despachar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Obtener el agenciaTrId del primer bulto seleccionado
    final int? agenciaTrId = selectedBultos.first.agenciaTrId;

    // Validar que el agenciaTrId no sea nulo
    if (agenciaTrId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Los bultos seleccionados no tienen agencia de transporte asignada'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Llamar al servicio para registrar el retiro
      var response = await EntregaServices().postRetiroBulto(
        context,
        selectedBultos.map((b) => b.bultoId).toList(),
        agenciaTrId,
        retira,
        comentario,
        token,
      );

      if (response.retiroId != 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedBultos.length} bultos despachados a $retira'),
            duration: const Duration(seconds: 3),
          ),
        );

        // Actualizar el estado de los bultos en la lista local
        setState(() {
          for (var bulto in bultos) {
            if (selectedBultos.contains(bulto)) {
              bulto = bulto.copyWith(estado: 'Despachado');
            }
          }
          selectedBultos.clear();
          _retiraController.clear();
          _comentarioController.clear();
        });

        // Opcional: Recargar los datos desde el servidor
        await loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al procesar el despacho'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al despachar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  
}