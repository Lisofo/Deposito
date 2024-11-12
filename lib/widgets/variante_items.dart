// Widget separado para la variante
import 'package:flutter/material.dart';

class VarianteItem extends StatelessWidget {
  final dynamic producto;
  final ColorScheme colores;
  final VoidCallback onAgregar;

  const VarianteItem({
    super.key,
    required this.producto,
    required this.colores,
    required this.onAgregar,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // if (producto.disponible <= 0) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     const SnackBar(
        //       content: Center(child: Text('No hay disponibles de esa variante')),
        //       duration: Duration(seconds: 2),
        //     ),
        //   );
        // } else {
        onAgregar();
        // }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(7),
        ),
        alignment: Alignment.center,
        height: 80,
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              producto.talle,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 5),
            const Divider(height: 2, thickness: 2),
            const SizedBox(height: 5),
            Text(
              producto.disponible.toString(),
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}