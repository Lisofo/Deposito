import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/resumen_general.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/almacen_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ResumenInventarioPage extends StatefulWidget {
  const ResumenInventarioPage({super.key});

  @override
  State<ResumenInventarioPage> createState() => _ResumenInventarioPageState();
}

class _ResumenInventarioPageState extends State<ResumenInventarioPage> {
  
  late Almacen almacen;
  late String token;
  late List<ResumenGeneral> resumen = [];

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  cargarDatos() async {
    final productProvider = context.read<ProductProvider>();
    almacen = productProvider.almacen;
    token = productProvider.token;

    resumen = await AlmacenServices().getResumen(context, almacen.almacenId, token);
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.read<ProductProvider>().menuTitle,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton.filledTonal(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(colors.primary)
          ),
          onPressed: () async {
            appRouter.pop();
          },
          icon: const Icon(Icons.arrow_back,),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        backgroundColor: colors.primary,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: resumen.length,
              itemBuilder: (context, i) {
                var usuario = resumen[i];
                return ListTile(
                  title: Text('Usuario ${usuario.nombre} ${usuario.apelldio}'),
                  subtitle: Text('Conteo ${usuario.conteo}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () async {
                    Provider.of<ProductProvider>(context, listen: false).setUsuarioConteo(usuario.usuarioId);
                    appRouter.push('/resumenGeneralnventarioPage');
                  },
                );
              },
            )
          ),
        ],
      ),
    );
  }
}