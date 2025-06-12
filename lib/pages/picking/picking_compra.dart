// ignore_for_file: unused_field

import 'package:deposito/models/almacen.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PickingCompra extends StatefulWidget {
  const PickingCompra({super.key});

  @override
  State<PickingCompra> createState() => _PickingCompraState();
}

class _PickingCompraState extends State<PickingCompra> {
  bool isLoading = true;
  String? _error;
  late Almacen almacen;
  late String token;
  FocusNode focoDeScanner = FocusNode();
  TextEditingController textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLineas();
  }

  Future<void> _loadLineas() async {
    final productProvider = context.read<ProductProvider>();
    almacen = productProvider.almacen;
    token = productProvider.token;
    focoDeScanner.requestFocus();
    try {
      setState(() {
        isLoading = true;
        _error = null;
      });
      
      // final ordenPicking = productProvider.ordenPickingInterna;
      // final lines = ordenPicking.lineas;
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: colors.primary,
          title: Consumer<ProductProvider>(
            builder: (context, provider, child) {
              final ordenPicking = provider.ordenPickingInterna;
              final lineas = ordenPicking.lineas ?? [];
              return Text(
                'Orden ${ordenPicking.numeroDocumento} - Línea ${provider.currentLineIndex + 1}/${lineas.length}', 
                style: TextStyle(color: colors.onPrimary),
              );
            },
          ),
        ),
      ),
    );
  }
}