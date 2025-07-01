// ignore_for_file: library_private_types_in_public_api

import 'package:deposito/config/router/pages.dart';
import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/orden_picking.dart';
import 'package:deposito/services/picking_services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SeleccionOrdenesScreen extends StatefulWidget {
  const SeleccionOrdenesScreen({super.key});

  @override
  _SeleccionOrdenesScreenState createState() => _SeleccionOrdenesScreenState();
}

class _SeleccionOrdenesScreenState extends State<SeleccionOrdenesScreen> {
  final List<OrdenPicking> _ordenesSeleccionadas = [];
  late List<OrdenPicking> _ordenes = [];
  final PickingServices _pickingServices = PickingServices();
  late Almacen almacen = Almacen.empty();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();


  bool _isLoading = true;
  bool camera = false;
  String token = '';

  @override
  void initState() {
    super.initState();
    token = context.read<ProductProvider>().token;
    camera = context.read<ProductProvider>().camera;
    
    _loadData();
  }


  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _pickingServices.resetStatusCode();
      final result = await _pickingServices.getOrdenesPicking(
        context, 
        almacen.almacenId,
        token, 
        tipo: 'V,P,TS',
        estado: 'CERRADO'
      );
      
      if (result != null && _pickingServices.statusCode == 1) {
        setState(() {
          _ordenes = result;          
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        title: Text(
          context.read<ProductProvider>().menuTitle,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: colors.onPrimary),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _refreshData,
            child: _ordenes.isEmpty
              ? ListView(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                    const Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No se encontraron órdenes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ), 
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _ordenes.length,
                        itemBuilder: (context, index) {
                          final orden = _ordenes[index];
                          return _buildOrdenItem(orden);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: _ordenesSeleccionadas.isNotEmpty
                          ? () {
                              productProvider.setOrdenesExpedicion(_ordenesSeleccionadas);
                              appRouter.push('/salidaBultos');
                            }
                          : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: const Text(
                          'Siguiente',
                          style: TextStyle(color: Colors.white, fontSize: 24),
                        ),
                      ),
                    ),
                  ],
                ),
        )
    );
  }

  Widget _buildOrdenItem(OrdenPicking orden) {
    final isSelected = _ordenesSeleccionadas.contains(orden);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _ordenesSeleccionadas.remove(orden);
            } else {
              _ordenesSeleccionadas.add(orden);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _ordenesSeleccionadas.add(orden);
                        } else {
                          _ordenesSeleccionadas.remove(orden);
                        }
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      '${orden.serie}-${orden.numeroDocumento}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      '${orden.porcentajeCompletado.toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: orden.porcentajeCompletado == 100 ? Colors.green : Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Cliente: ${orden.nombre}'),
              const SizedBox(height: 8),
              Text('Tipo: ${orden.descTipo}'),
              Text('Cliente: ${orden.codEntidad} - ${orden.nombre}'),
              Text('RUC: ${orden.ruc}'),
              Text(orden.transaccion),
              Text('Fecha: ${DateFormat('dd/MM/yyyy').format(orden.fechaDate)}'),
              Text("Fecha última mod.: ${DateFormat('dd/MM/yyyy HH:mm').format(orden.fechaDate)}"),
            ],
          ),
        ),
      ),
    );
  }
}