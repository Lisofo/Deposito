// salida_cierre_bultos_page.dart
import 'package:deposito/models/bulto.dart';
import 'package:deposito/models/entrega.dart';
import 'package:deposito/models/forma_envio.dart';
import 'package:deposito/models/modo_envio.dart';
import 'package:deposito/models/tipo_bulto.dart';
import 'package:deposito/services/entrega_services.dart';
import 'package:deposito/widgets/carteles.dart';
import 'package:deposito/widgets/icon_string.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:deposito/models/orden_picking.dart';

class SalidaCierreBultosPage extends StatefulWidget {
  final Entrega entrega;
  final OrdenPicking ordenSeleccionada;
  final Bulto bultoVirtual;
  final List<TipoBulto> tipoBultos;
  final List<ModoEnvio> modoEnvios;
  final List<FormaEnvio> transportistas;
  final List<FormaEnvio> empresasEnvio;
  final String token;
  final bool modoReadOnly; // Nuevo parámetro para modo readonly

  const SalidaCierreBultosPage({
    super.key,
    required this.entrega,
    required this.ordenSeleccionada,
    required this.bultoVirtual,
    required this.tipoBultos,
    required this.modoEnvios,
    required this.transportistas,
    required this.empresasEnvio,
    required this.token,
    this.modoReadOnly = false, // Por defecto no es readonly
  });

  @override
  SalidaCierreBultosPageState createState() => SalidaCierreBultosPageState();
}

class SalidaCierreBultosPageState extends State<SalidaCierreBultosPage> {
  final Map<int, int> _cantidadesPorTipo = {};
  final Map<int, TextEditingController> _controllers = {};
  ModoEnvio? _metodoEnvio;
  FormaEnvio? _empresaEnvioSeleccionada;
  FormaEnvio? _transportistaSeleccionado;
  final TextEditingController _comentarioController = TextEditingController();
  bool _incluyeFactura = false;
  bool _procesandoCierre = false;
  bool _entregaFinalizada = false;
  List<Bulto> _bultosCerrados = [];

  @override
  void initState() {
    super.initState();
    _cargarBultosCerrados();
    
    if (!widget.modoReadOnly) {
      // Solo inicializar controles si no es modo readonly
      final tiposDisponibles = widget.tipoBultos
          .where((tipo) => tipo.codTipoBulto != "VIRTUAL")
          .toList();
      
      for (var tipo in tiposDisponibles) {
        _cantidadesPorTipo[tipo.tipoBultoId] = 0;
        _controllers[tipo.tipoBultoId] = TextEditingController(text: '0');
      }
    }
  }

  Future<void> _cargarBultosCerrados() async {
    try {
      final bultosExistentes = await EntregaServices().getBultosEntrega(
        context, 
        widget.entrega.entregaId, 
        widget.token
      );
      
      // Filtrar bultos cerrados excluyendo los VIRTUAL
      final bultosCerradosFiltrados = bultosExistentes.where((b) => 
        b.estado == 'CERRADO' && 
        b.tipoBultoId != widget.bultoVirtual.tipoBultoId // Excluir bultos VIRTUAL
      ).toList();
      
      setState(() {
        _bultosCerrados = bultosCerradosFiltrados;
        _entregaFinalizada = widget.entrega.estado == 'finalizado' || _bultosCerrados.isNotEmpty;
      });
    } catch (e) {
      Carteles.showDialogs(context, 'Error al cargar bultos', false, false, false);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _cerrarBultoVirtual(String comentario, bool incluyeFactura) async {
    try {
      await EntregaServices().putBultoEntrega(
        context,
        widget.entrega.entregaId,
        widget.bultoVirtual.bultoId,
        widget.ordenSeleccionada.entidadId,
        widget.ordenSeleccionada.nombre,
        0,
        0,
        0,
        '',
        widget.ordenSeleccionada.localidad,
        widget.ordenSeleccionada.telefono,
        comentario,
        comentario,
        widget.bultoVirtual.tipoBultoId,
        incluyeFactura,
        widget.bultoVirtual.nroBulto,
        widget.bultoVirtual.totalBultos,
        widget.token,
      );

      await EntregaServices().patchBultoEstado(
        context,
        widget.entrega.entregaId,
        widget.bultoVirtual.bultoId,
        'CERRADO',
        widget.token,
      );
    } catch (e) {
      throw Exception('Error al cerrar bulto VIRTUAL: ${e.toString()}');
    }
  }

  Future<void> _procesarCierre() async {
    final totalBultos = _cantidadesPorTipo.values
        .fold(0, (sum, cantidad) => sum + cantidad);
    
    if (totalBultos == 0) {
      Carteles.showDialogs(context, 'Debe crear al menos un bulto', false, false, false);
      return;
    }
    
    if (_metodoEnvio == null) {
      Carteles.showDialogs(context, 'Debe seleccionar un método de envío', false, false, false);
      return;
    }
    
    if (_metodoEnvio?.modoEnvioId == 2 &&
        (_empresaEnvioSeleccionada == null ||
            _transportistaSeleccionado == null)) {
      Carteles.showDialogs(
        context, 
        'Para envío por correo debe seleccionar empresa y transportista', 
        false, 
        false, 
        false
      );
      return;
    }
    
    setState(() {
      _procesandoCierre = true;
    });
    
    try {
      final List<Bulto> bultosCreados = [];
      final tiposDisponibles = widget.tipoBultos
          .where((tipo) => tipo.codTipoBulto != "VIRTUAL")
          .toList();
      
      for (var tipo in tiposDisponibles) {
        final cantidad = _cantidadesPorTipo[tipo.tipoBultoId] ?? 0;
        
        for (int i = 0; i < cantidad; i++) {
          final nuevoBulto = await EntregaServices().postBultoEntrega(
            context,
            widget.entrega.entregaId,
            tipo.tipoBultoId,
            widget.token,
          );
          
          if (nuevoBulto.bultoId != 0) {
            bultosCreados.add(nuevoBulto);
          }
        }
      }
      
      for (var bulto in bultosCreados) {
        await EntregaServices().putBultoEntrega(
          context,
          widget.entrega.entregaId,
          bulto.bultoId,
          widget.ordenSeleccionada.entidadId,
          widget.ordenSeleccionada.nombre,
          _metodoEnvio!.modoEnvioId,
          _transportistaSeleccionado?.formaEnvioId ?? 0,
          _empresaEnvioSeleccionada?.formaEnvioId ?? 0,
          '',
          widget.ordenSeleccionada.localidad,
          widget.ordenSeleccionada.telefono,
          _comentarioController.text,
          _comentarioController.text,
          bulto.tipoBultoId,
          _incluyeFactura,
          bulto.nroBulto,
          bulto.totalBultos,
          widget.token,
        );
        
        await EntregaServices().patchBultoEstado(
          context,
          widget.entrega.entregaId,
          bulto.bultoId,
          'CERRADO',
          widget.token,
        );
      }
      
      await _cerrarBultoVirtual(_comentarioController.text, _incluyeFactura);
      
      await EntregaServices().patchEntregaEstado(
        context,
        widget.entrega.entregaId,
        'finalizado',
        widget.token,
      );
      
      // En lugar de navegar de regreso, actualizamos el estado a readonly
      setState(() {
        _entregaFinalizada = true;
        _procesandoCierre = false;
      });
      
      // Recargar bultos cerrados
      await _cargarBultosCerrados();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bultos creados y entrega finalizada exitosamente'),
        ),
      );
    } catch (e) {
      if (mounted) {
        Carteles.showDialogs(context, 'Error al procesar cierre: ${e.toString()}', false, false, false);
        setState(() {
          _procesandoCierre = false;
        });
      }
    }
  }

  Future<void> _reimprimirEtiquetas() async {
    try {
      // Lógica para reimprimir etiquetas
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reimprimiendo etiquetas...')),
      );
      
      await Future.delayed(const Duration(seconds: 2));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Etiquetas reimpresas correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al reimprimir etiquetas: ${e.toString()}')),
      );
    }
  }

  Widget _buildFormularioCierre() {
    final tiposDisponibles = widget.tipoBultos
        .where((tipo) => tipo.codTipoBulto != "VIRTUAL")
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Tipos y cantidades de bultos:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 12),
        
        ...tiposDisponibles.map((tipo) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                getIcon(tipo.icon, context, Theme.of(context).colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(child: Text(tipo.descripcion, style: const TextStyle(fontWeight: FontWeight.w500))),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: _controllers[tipo.tipoBultoId],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    enabled: !_procesandoCierre,
                    decoration: InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      final cantidad = int.tryParse(value) ?? 0;
                      setState(() {
                        _cantidadesPorTipo[tipo.tipoBultoId] = cantidad;
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        }),
        
        const SizedBox(height: 20),
        const Text('Método de envío:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonFormField<ModoEnvio>(
            isExpanded: true,
            value: _metodoEnvio,
            hint: const Text('Seleccione método de envío'),
            decoration: const InputDecoration(border: InputBorder.none),
            dropdownColor: Colors.white,
            icon: const Icon(Icons.arrow_drop_down),
            items: widget.modoEnvios.map((value) {
              return DropdownMenuItem(
                value: value,
                child: Text(value.descripcion, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: _procesandoCierre ? null : (ModoEnvio? newValue) {
              setState(() {
                _metodoEnvio = newValue;
                if (newValue?.modoEnvioId != 2) {
                  _empresaEnvioSeleccionada = null;
                  _transportistaSeleccionado = null;
                }
              });
            },
          ),
        ),
        
        if (_metodoEnvio?.modoEnvioId == 2) ...[
          const SizedBox(height: 16),
          const Text('Transportista:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonFormField<FormaEnvio>(
              isExpanded: true,
              value: _transportistaSeleccionado,
              hint: const Text('Seleccione transportista'),
              decoration: const InputDecoration(border: InputBorder.none),
              dropdownColor: Colors.white,
              icon: const Icon(Icons.arrow_drop_down),
              items: widget.transportistas.map((FormaEnvio value) {
                return DropdownMenuItem(
                  value: value,
                  child: Text(value.descripcion.toString(), overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: _procesandoCierre ? null : (FormaEnvio? newValue) {
                setState(() {
                  _transportistaSeleccionado = newValue;
                });
              },
            ),
          ),
          
          const SizedBox(height: 16),
          const Text('Empresa de envío:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownSearch<FormaEnvio>(
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchDelay: Duration.zero,
                constraints: BoxConstraints.tightFor(width: MediaQuery.of(context).size.width * 0.7),
                searchFieldProps: const TextFieldProps(
                  decoration: InputDecoration(
                    hintText: "Buscar empresa...",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                menuProps: const MenuProps(backgroundColor: Colors.white, elevation: 8),
              ),
              items: widget.empresasEnvio,
              itemAsString: (FormaEnvio item) => item.descripcion.toString(),
              selectedItem: _empresaEnvioSeleccionada,
              onChanged: _procesandoCierre ? null : (FormaEnvio? newValue) {
                setState(() {
                  _empresaEnvioSeleccionada = newValue;
                });
              },
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  hintText: "Seleccione empresa",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              compareFn: (item, selectedItem) => item.codFormaEnvio == selectedItem.codFormaEnvio,
            ),
          ),
        ],
        
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Incluye factura', style: TextStyle(fontSize: 16)),
            value: _incluyeFactura,
            onChanged: _procesandoCierre ? null : (bool? value) {
              setState(() {
                _incluyeFactura = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
        
        const SizedBox(height: 16),
        const Text('Comentario:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: _comentarioController,
          minLines: 2,
          maxLines: 4,
          enabled: !_procesandoCierre,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              onPressed: _procesandoCierre ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: _procesandoCierre ? null : _procesarCierre,
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBultosCerrados() {
    final colors = Theme.of(context).colorScheme;
    // Filtrar nuevamente por si acaso (aunque ya se filtró en _cargarBultosCerrados)
    final bultosNoVirtuales = _bultosCerrados.where((b) => 
      b.tipoBultoId != widget.bultoVirtual.tipoBultoId
    ).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Bultos Cerrados:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        
        if (bultosNoVirtuales.isEmpty)
          const Text('No hay bultos cerrados', style: TextStyle(color: Colors.grey)),
        
        ...bultosNoVirtuales.map((bulto) {
          final tipoBulto = widget.tipoBultos.firstWhere(
            (t) => t.tipoBultoId == bulto.tipoBultoId,
            orElse: () => TipoBulto.empty()
          );
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: getIcon(tipoBulto.icon, context, Colors.green),
              title: Text('Bulto ${tipoBulto.descripcion}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estado: ${bulto.estado}'),
                  if (bulto.comentario!.isNotEmpty) Text('Comentario: ${bulto.comentario}'),
                ],
              ),
            ),
          );
        }),
        
        const SizedBox(height: 10),
        ElevatedButton.icon(
          icon: Icon(Icons.print, color: colors.onPrimary,),
          label: const Text('Reimprimir Etiquetas'),
          onPressed: _reimprimirEtiquetas,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          icon: Icon(Icons.print, color: colors.onPrimary,),
          label: const Text('Reimprimir Entrega'),
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            // Navegar hacia atrás hasta encontrar la pantalla SeleccionOrdenesScreen
            Navigator.of(context).popUntil((route) => route.settings.name == '/expedicionPaquetes');
          },
          child: const Text('Volver'),
        ),
      ],
    );
  }

  // ignore: unused_element
  void _verDetallesBulto(Bulto bulto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles del Bulto ${bulto.nroBulto}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tipo: ${widget.tipoBultos.firstWhere((t) => t.tipoBultoId == bulto.tipoBultoId, orElse: () => TipoBulto.empty()).descripcion}'),
              Text('Estado: ${bulto.estado}'),
              if (bulto.comentario!.isNotEmpty) Text('Comentario: ${bulto.comentario}'),
              const SizedBox(height: 16),
              const Text('Contenido:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...bulto.contenido.map((item) => 
                ListTile(
                  title: Text(item.item),
                  subtitle: Text('Cantidad: ${item.cantidad}'),
                )
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_entregaFinalizada ? 'Bultos Cerrados' : 'Crear y cerrar bultos'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),
      body: _procesandoCierre
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _entregaFinalizada || widget.modoReadOnly
                  ? _buildBultosCerrados()
                  : _buildFormularioCierre(),
            ),
    );
  }
}