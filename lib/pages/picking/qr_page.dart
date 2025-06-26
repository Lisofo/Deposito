import 'package:deposito/config/router/pages.dart';
import 'package:deposito/models/almacen.dart';
import 'package:deposito/models/orden_picking.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrPage extends StatefulWidget {
  const QrPage({super.key});

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  late OrdenPicking orderProvider = OrdenPicking.empty();
  String token = '';
  late Almacen almacen = Almacen.empty();
  String? _qrData;

  @override
  void initState() {
    super.initState();
    cargarData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cargarData();
  }

  void cargarData() async {
    orderProvider = context.read<ProductProvider>().ordenPicking;
    token = context.read<ProductProvider>().token;
    almacen = context.read<ProductProvider>().almacen;
    _generateQRCode();
    setState(() {});
  }

  void _generateQRCode() {
    setState(() {
      // Genera un número aleatorio de 5 dígitos (ej. 45575)
      _qrData = (orderProvider.pickId).toString();
    });
  }

  // ignore: unused_element
  void _clearQRCode() {
    setState(() {
      _qrData = null;
    });
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
          title: Text(
            'Orden ${orderProvider.numeroDocumento}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_qrData != null) ...[
                Text(
                  'Código: $_qrData',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                QrImageView(
                  data: _qrData!,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}