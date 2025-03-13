import 'package:deposito/config/router/router.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/conteo.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/almacen_services.dart';
import 'package:deposito/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ResumenGeneralInventarioPage extends StatefulWidget {
  const ResumenGeneralInventarioPage({super.key});

  @override
  State<ResumenGeneralInventarioPage> createState() => _ResumenGeneralInventarioPageState();
}

class _ResumenGeneralInventarioPageState extends State<ResumenGeneralInventarioPage> {

  late Almacen almacen;
  late String token;
  final _almacenServices = AlmacenServices();
  late List<String> permisos = [];
  List<Conteo> listaConteo = [];
  late int usuarioConteo;
  late bool confirmarConteo = false;
  late bool borrarConteo = false;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  cargarDatos() async {
    final productProvider = context.read<ProductProvider>();
    almacen = productProvider.almacen;
    token = productProvider.token;
    permisos = productProvider.permisos;
    usuarioConteo = productProvider.usuarioConteo;
    confirmarConteo = permisos.contains('WMS_INV_CONF_ADM');
    borrarConteo = permisos.contains('WMS_INV_ELIM_ADM');
    
    listaConteo = await AlmacenServices().getInventarioGeneral(context, almacen.almacenId, usuarioConteo, token);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Confirmar conteo',
          style: TextStyle(color: Colors.white),
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
              itemCount: listaConteo.length,
              itemBuilder: (context, i) {
                var item = listaConteo[i];
                return ListTile(
                  title: Text(item.descripcion),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cantidad contada: ${item.conteo}'),
                      Text('Ubicacion: ${item.codUbicacion}'),
                    ],
                  ),
                );
              }
            )
          ),
        ],
      ),
      bottomNavigationBar: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CustomButton(
            text: 'Borrar conteo del usuario',
            tamano: 16,
            disabled: !borrarConteo,
            onPressed: borrarConteo ? _mostrarDialogoBorrarConteo : null
          ),
          CustomButton(
            tamano: 18,
            text: 'Finalizar',
            disabled: !confirmarConteo,
            onPressed: confirmarConteo ? _mostrarDialogoConfirmarConteo : null
          )
        ],
      ),
    );
  }

  
  Future<void> _mostrarDialogoBorrarConteo() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // El usuario debe tocar un botón para cerrar el diálogo
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¿Estás seguro?'),
          content: const Text('¿Estás seguro de que deseas borrar el conteo del usuario?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
            TextButton(
              child: const Text('Borrar'),
              onPressed: () async {
                Navigator.of(context).pop(); // Cierra el diálogo
                int? statusCode;
                await _almacenServices.deleteInventarioUsuario(context, almacen.almacenId, usuarioConteo, token);
                statusCode = await _almacenServices.getStatusCode();
                await _almacenServices.resetStatusCode();
                if(statusCode == 1) {
                  appRouter.pop();
                  appRouter.pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _mostrarDialogoConfirmarConteo() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // El usuario debe tocar un botón para cerrar el diálogo
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¿Estás seguro?'),
          content: const Text('¿Estás seguro de que deseas confirmar el conteo?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () async {
                Navigator.of(context).pop(); // Cierra el diálogo
                int? statusCode;
                await _almacenServices.postInventarioGeneral(context, almacen.almacenId, usuarioConteo, token);
                statusCode = await _almacenServices.getStatusCode();
                await _almacenServices.resetStatusCode();
                if(statusCode == 1) {
                  appRouter.pop();
                  appRouter.pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}