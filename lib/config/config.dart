
import 'package:deposito/provider/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final productProvider = Provider.of<ProductProvider>(context);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colores.primary,
          title: Text('Configuración', style: TextStyle(color: colores.onPrimary)),
          iconTheme: IconThemeData(color: colores.onPrimary),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Cámara no disponible'),
                  Switch(
                    value: productProvider.camera,
                    onChanged: (value) {
                      productProvider.setCamara(value);
                      _saveValue(value);
                    },
                  ),
                  const Text('Cámara disponible')
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // Método para guardar el valor en SharedPreferences
  Future<void> _saveValue(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('camDisponible', value);
  }
}