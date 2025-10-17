import 'package:deposito/config/router/pages.dart';
import 'package:deposito/models/bulto.dart';
import 'package:deposito/models/entrega.dart';
import 'package:deposito/models/forma_envio.dart';
import 'package:deposito/services/entrega_services.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:deposito/widgets/escaner_pda.dart';
import 'package:deposito/widgets/icon_string.dart';
import 'package:deposito/widgets/segmented_buttons.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:deposito/pages/expedicion/salida_bultos_page_basica.dart';

class DespachoPage extends StatefulWidget {
  const DespachoPage({super.key});

  @override
  DespachoPageState createState() => DespachoPageState();
}

class DespachoPageState extends State<DespachoPage> {
  List<Bulto> selectedBultos = [];
  List<Bulto> bultos = [];
  List<FormaEnvio> transportistas = [];
  List<FormaEnvio> agencias = [];
  FormaEnvio? transportistaSeleccionado;
  final TextEditingController _retiraController = TextEditingController();
  final TextEditingController _comentarioController = TextEditingController();
  final FocusNode focoDeScanner = FocusNode();
  final TextEditingController textController = TextEditingController();
  String token = '';
  bool isLoading = true;
  int _groupValueBultos = 2; // Default to "Cerrado"

  @override
  void initState() {
    super.initState();
    loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        focoDeScanner.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _retiraController.dispose();
    _comentarioController.dispose();
    focoDeScanner.dispose();
    textController.dispose();
    super.dispose();
  }

  loadData() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    token = productProvider.token;
    
    try {
      // Cargar transportistas (FormaEnvio con tr=true)
      final formasEnvio = await EntregaServices().formaEnvio(context, token);

      for (var forma in formasEnvio) {
        if (forma.tr == true) {
          transportistas.add(forma);
        }
        if (forma.envio == true) {
          agencias.add(forma);
        }
      }
      transportistas.sort((a, b) => a.descripcion!.compareTo(b.descripcion.toString()));
      agencias.sort((a, b) => a.descripcion!.compareTo(b.descripcion.toString()));

      // Cargar bultos cerrados
      await _cargarBultos();
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _cargarBultos({int? agenciaTrId}) async {
    setState(() {
      isLoading = true;
    });
    
    try {
      String? estado;
      if (_groupValueBultos != 0) {
        estado = ['PENDIENTE', 'CERRADO', 'RETIRADO', 'DEVUELTO'][_groupValueBultos - 1];
      }
      
      // Obtener todos los bultos
      List<Bulto> todosBultos = await EntregaServices().getBultos(
        context, 
        token, 
        estado: estado,
        agenciaTrId: agenciaTrId,
      );
      
      // Filtrar bultos - excluir los que tienen tipoBultoId = 4
      bultos = todosBultos.where((bulto) => bulto.tipoBultoId != 4).toList();
      
      if (mounted) {
        setState(() {
          selectedBultos.clear();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  bool _todosBultosDespachados() {
    return selectedBultos.isNotEmpty && selectedBultos.every((b) => b.estado == 'RETIRADO');
  }

  bool _esBultoImprimible(Bulto bulto) {
    return (bulto.estado == 'CERRADO' || bulto.estado == 'RETIRADO') && bulto.retiroId != null;
  }

  void _mantenerFocoScanner() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        focoDeScanner.requestFocus();
      }
    });
  }

  Future<void> procesarEscaneoBulto(String value) async {
    if (value.isEmpty) return;
    
    if (_groupValueBultos != 0 && _groupValueBultos != 1) return;

    try {
      var bultoEncontrado = bultos.firstWhere((bulto) => bulto.bultoId == int.parse(value));
      
      // Verificar que el bulto no sea del tipo 4 antes de agregarlo
      if (bultoEncontrado.tipoBultoId != 4 && !selectedBultos.contains(bultoEncontrado)) {
        setState(() {
          selectedBultos.add(bultoEncontrado);
        });
      } else if (bultoEncontrado.tipoBultoId == 4) {
        Carteles.showDialogs(context, 'Este tipo de bulto no puede ser procesado', false, false, false);
      }
      
      textController.clear();
      _mantenerFocoScanner();
    } catch (e) {
      Carteles.showDialogs(context, 'Error al procesar el escaneo', false, false, false);
      _mantenerFocoScanner();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colors.primary,
          title: Text(
            context.read<ProductProvider>().menuTitle,
            style: TextStyle(color: colors.onPrimary),
          ),
          iconTheme: IconThemeData(color: colors.onPrimary),
          actions: [
            if (transportistaSeleccionado != null)
              IconButton(
                icon: const Icon(Icons.clear_all),
                tooltip: 'Limpiar filtro',
                onPressed: () async {
                  setState(() {
                    transportistaSeleccionado = null;
                  });
                  await _cargarBultos();
                  _mantenerFocoScanner();
                },
              ),
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
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: DropdownSearch<FormaEnvio>(
                popupProps: const PopupProps.menu(
                  showSearchBox: true,
                  searchDelay: Duration.zero,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      hintText: "Buscar transportista...",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                items: transportistas,
                itemAsString: (FormaEnvio item) => item.descripcion.toString(),
                selectedItem: transportistaSeleccionado,
                onChanged: (FormaEnvio? newValue) async {
                  setState(() {
                    transportistaSeleccionado = newValue;
                  });
                  await _cargarBultos(
                    agenciaTrId: newValue?.formaEnvioId
                  );
                  _mantenerFocoScanner();
                },
                dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: "Seleccionar transportista",
                    border: OutlineInputBorder(),
                  ),
                ),
                compareFn: (item, selectedItem) => item.formaEnvioId == selectedItem.formaEnvioId,
              ),
            ),
            CustomSegmentedControl(
              groupValue: _groupValueBultos,
              onValueChanged: (newValue) {
                setState(() {
                  _groupValueBultos = newValue;
                  _cargarBultos(agenciaTrId: transportistaSeleccionado?.formaEnvioId);
                });
              },
              options: SegmentedOptions.bultosStates,
              usePickingStyle: true,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : bultos.isEmpty
                      ? const Center(child: Text('No hay bultos disponibles'))
                      : ListView.builder(
                          itemCount: bultos.length,
                          itemBuilder: (context, index) => _buildBultoItem(bultos[index]),
                        ),
            ),
            EscanerPDA(
              onScan: procesarEscaneoBulto,
              focusNode: focoDeScanner,
              controller: textController,
            ),
            if (selectedBultos.isNotEmpty) _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildBultoItem(Bulto bulto) {
    final colors = Theme.of(context).colorScheme;
    final isSelected = selectedBultos.contains(bulto);
    late String fechaDate = DateFormat('dd/MM/yyyy HH:mm', 'es').format(bulto.fechaDate);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      color: isSelected ? Colors.blue[50] : null,
      child: InkWell(
        onTap: () => (_groupValueBultos != 0 && _groupValueBultos != 1 && _groupValueBultos != 4) ? _toggleSeleccionBulto(bulto) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  getIcon(bulto.icon, context, colors.primary),
                  const SizedBox(width: 10,),
                  Text(
                    'Bulto #${bulto.bultoId}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Expanded(child: SizedBox()),
                  Column(
                    children: [
                      Text(
                        bulto.estado,
                        style: TextStyle(
                          color: _getEstadoColor(bulto.estado),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(bulto.modoEnvioId == 1 ? 'Retira' : 'Envío', style: const TextStyle(fontWeight: FontWeight.bold),),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Cliente: ${bulto.nombreCliente} - tel: ${bulto.telefono}'),
              Text('Dirección: ${bulto.direccion}'),
              Text('Localidad: ${bulto.localidad} \nDepartamento: ${bulto.departamento}'),
              if (bulto.agenciaTrId != null)
                Text('Transportista: ${_getNombreTransportista(bulto.agenciaTrId)}'),
              if (bulto.agenciaUFId != null)
                Text('Agencia: ${_getNombreAgencia(bulto.agenciaUFId)}'),
              if (bulto.retiroId != null)
                Text('Retiro ID: ${bulto.retiroId}'),
              const SizedBox(height: 8),
              Text('Fecha: $fechaDate'),
              if (bulto.comentarioEnvio != '')
                Text(bulto.comentarioEnvio.toString()),
              if (_groupValueBultos != 0 && _groupValueBultos != 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => _verContenidoEntrega(bulto),
                      child: const Text('Ver contenido de la entrega')
                    ),
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

  Widget _buildActionButtons() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: selectedBultos.length == 1 && _esBultoImprimible(selectedBultos.first)
          ? Row(
              children: [
                Expanded(child: _buildImprimirButton()),
                Expanded(child: _buildDespacharButton()),
              ],
            )
          : SizedBox(
              width: MediaQuery.of(context).size.width > 600 ? MediaQuery.of(context).size.width * 0.4 : MediaQuery.of(context).size.width,
              child: _buildDespacharButton())
            ,
    );
  }

  Widget _buildImprimirButton() {
    final colors = Theme.of(context).colorScheme;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: colors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () => _confirmarImpresion(),
      child: const Text(
        'IMPRIMIR RETIRO',
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }

  Widget _buildDespacharButton() {
    final colors = Theme.of(context).colorScheme;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: _todosBultosDespachados() ? colors.secondary : colors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: _todosBultosDespachados() ? _showDevolucionDialog : _showDespachoDialog,
      child: Text(
        _todosBultosDespachados() 
            ? 'DEVOLVER (${selectedBultos.length})' 
            : 'Retirar (${selectedBultos.length})',
        style: const TextStyle(fontSize: 16, color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _confirmarImpresion() async {
    final bulto = selectedBultos.first;
    bool confirmado = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Impresión'),
        content: const Text('¿Desea imprimir los datos del retiro de este bulto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ACEPTAR'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await _imprimirRetiro(bulto.retiroId!);
    }
  }

  Future<void> _imprimirRetiro(int retiroId) async {
    try {
      await EntregaServices().postImprimirRetiro(
        context,
        retiroId,
        context.read<ProductProvider>().almacen.almacenId,
        token,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impresión del retiro enviada correctamente'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al imprimir: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getNombreTransportista(int? agenciaTrId) {
    if (agenciaTrId == null) return 'No asignado';
    final transportista = transportistas.firstWhere(
      (t) => t.formaEnvioId == agenciaTrId,
      orElse: () => FormaEnvio.empty(),
    );
    return transportista.descripcion ?? 'Transportista desconocido';
  }

  String _getNombreAgencia(int? agenciaUFId) {
    if (agenciaUFId == null) return 'No asignado';
    final agencia = agencias.firstWhere(
      (a) => a.formaEnvioId == agenciaUFId,
      orElse: () => FormaEnvio.empty(),
    );
    return agencia.descripcion ?? 'Agencia desconocida';
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'Pendiente': return Colors.orange;
      case 'Preparado': return Colors.blue;
      case 'Listo': return Colors.green;
      case 'CERRADO': return Colors.purple;
      case 'RETIRADO': return Colors.teal;
      case 'DEVUELTO': return Colors.red;
      default: return Colors.grey;
    }
  }

  void _toggleSeleccionBulto(Bulto bulto) {
    // No permitir seleccionar bultos con tipoBultoId = 4
    if (bulto.tipoBultoId == 4) {
      Carteles.showDialogs(context, 'Este tipo de bulto no puede ser seleccionado', false, false, false);
      return;
    }
    
    setState(() {
      if (selectedBultos.contains(bulto)) {
        selectedBultos.remove(bulto);
      } else {
        selectedBultos.add(bulto);
      }
    });
    _mantenerFocoScanner();
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
            child: const Text('CONFIRMAR RETIRO'),
          ),
        ],
      ),
    );
  }

  void _showDevolucionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Devolución'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _retiraController,
                  decoration: const InputDecoration(
                    labelText: 'Persona que devuelve',
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
                  'Bultos a devolver:',
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
              _procesarDevolucion();
              Navigator.pop(context);
            },
            child: const Text('CONFIRMAR DEVOLUCIÓN'),
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
          content: Text('No hay bultos seleccionados para retirar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Obtener el agenciaTrId del transportista seleccionado o del primer bulto
    final int? agenciaTrId = transportistaSeleccionado?.formaEnvioId ?? selectedBultos.first.agenciaTrId;

    if (agenciaTrId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se ha seleccionado un transportista válido'),
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
            content: Text('${selectedBultos.length} bultos retirados a $retira'),
            duration: const Duration(seconds: 3),
          ),
        );
        await EntregaServices().postImprimirRetiro(context, response.retiroId, context.read<ProductProvider>().almacen.almacenId, token);
        // Actualizar el estado de los bultos en la lista local
        setState(() {
          for (var bulto in bultos) {
            if (selectedBultos.contains(bulto)) {
              bulto = bulto.copyWith(estado: 'RETIRADO');
            }
          }
          selectedBultos.clear();
          _retiraController.clear();
          _comentarioController.clear();
        });

        // Recargar los datos desde el servidor
        await _cargarBultos(agenciaTrId: transportistaSeleccionado?.formaEnvioId);
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
          content: Text('Error al retirar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _procesarDevolucion() async {
    final devueltoPor = _retiraController.text.trim();
    final comentario = _comentarioController.text.trim();

    if (devueltoPor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe ingresar el nombre de quien devuelve'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedBultos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay bultos seleccionados para devolver'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await EntregaServices().postDevolucionBulto(
        context,
        selectedBultos.map((b) => b.bultoId).toList(),
        devueltoPor,
        comentario,
        token,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selectedBultos.length} bultos devueltos por $devueltoPor'),
          duration: const Duration(seconds: 3),
        ),
      );

      // Actualizar el estado de los bultos en la lista local
      setState(() {
        for (var bulto in bultos) {
          if (selectedBultos.contains(bulto)) {
            bulto = bulto.copyWith(estado: 'DEVUELTO');
          }
        }
        selectedBultos.clear();
        _retiraController.clear();
        _comentarioController.clear();
      });

      // Recargar los datos desde el servidor
      await _cargarBultos(agenciaTrId: transportistaSeleccionado?.formaEnvioId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al devolver: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Nuevo método para ver el contenido de la entrega navegando a SalidaBultosPageBasica en modo monitor
  void _verContenidoEntrega(Bulto bulto) async {
    try {
      // Obtener la entrega completa por ID
      Entrega entregaCompleta = await EntregaServices().getEntregaPorId(
        context, 
        token, 
        entregaId: bulto.entregaId
      );
      
      if (entregaCompleta.entregaId == 0) {
        Carteles.showDialogs(context, 'No se pudo cargar la entrega', false, false, false);
        return;
      }

      // Navegar a SalidaBultosPageBasica en modo monitor
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SalidaBultosPageBasica(
            entregaExterna: entregaCompleta,
            esModoMonitor: true,
          ),
        ),
      ).then((_) {
        // Cuando regresemos, mantener el foco en el scanner
        _mantenerFocoScanner();
      });

    } catch (e) {
      Carteles.showDialogs(context, 'Error al cargar el contenido de la entrega: ${e.toString()}', false, false, false);
      _mantenerFocoScanner();
    }
  }
}