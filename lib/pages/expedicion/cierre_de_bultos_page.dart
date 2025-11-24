// salida_cierre_bultos_page.dart
import 'package:deposito/config/router/pages.dart';
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
  final TextEditingController _comentarioEnvioController = TextEditingController();
  bool _incluyeFactura = false;
  bool _procesandoCierre = false;
  bool _entregaFinalizada = false;
  List<Bulto> _bultosCerrados = [];
  final TextEditingController _nombreEnvioController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _localidadController = TextEditingController();
  final TextEditingController _departamentoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  late String token2 = '';

  @override
  void initState() {
    super.initState();
    _cargarBultosCerrados();
    
    // Inicializar los controladores con los datos de la orden
    _nombreEnvioController.text = widget.ordenSeleccionada.nombreEnvio;
    _direccionController.text = widget.ordenSeleccionada.direccionEnvio;
    _localidadController.text = widget.ordenSeleccionada.localidadEnvio;
    _departamentoController.text = widget.ordenSeleccionada.departamentoEnvio;
    _telefonoController.text = widget.ordenSeleccionada.telefonoEnvio;
    _comentarioEnvioController.text = widget.ordenSeleccionada.comentarioEnvio;
    
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

  @override
  void dispose() {
    // Dispose de los nuevos controladores
    _nombreEnvioController.dispose();
    _direccionController.dispose();
    _localidadController.dispose();
    _departamentoController.dispose();
    _telefonoController.dispose();
    
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _cargarBultosCerrados() async {
    try {
      // USAR TOKEN DEL PIN SI ESTÁ DISPONIBLE
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final tokenPin = productProvider.tokenPin;
      final tokenFinal = tokenPin.isNotEmpty ? tokenPin : widget.token;
      
      final bultosExistentes = await EntregaServices().getBultosEntrega(
        context, 
        widget.entrega.entregaId, 
        tokenFinal // USAR TOKEN FINAL
      );
      
      // Filtrar bultos cerrados excluyendo los VIRTUAL
      final bultosCerradosFiltrados = bultosExistentes.where((b) => 
        b.estado == 'CERRADO' && 
        b.tipoBultoId != widget.bultoVirtual.tipoBultoId // Excluir bultos VIRTUAL
      ).toList();
      
      setState(() {
        _bultosCerrados = bultosCerradosFiltrados;
        _entregaFinalizada = widget.entrega.estado == 'FINALIZADO' || _bultosCerrados.isNotEmpty;
      });
    } catch (e) {
      Carteles.showDialogs(context, 'Error al cargar bultos', false, false, false);
    }
  }

  Future<void> _cerrarBultoVirtual(String comentario, bool incluyeFactura) async {
    try {
      // USAR TOKEN DEL PIN SI ESTÁ DISPONIBLE
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final tokenPin = productProvider.tokenPin;
      final tokenFinal = tokenPin.isNotEmpty ? tokenPin : widget.token;
      
      await EntregaServices().putBultoEntrega(
        context,
        widget.entrega.entregaId,
        widget.bultoVirtual.bultoId,
        widget.ordenSeleccionada.entidadId,
        _nombreEnvioController.text, // Usar el controlador
        0,
        0,
        0,
        _direccionController.text, // Usar el controlador
        _localidadController.text, // Usar el controlador
        _departamentoController.text, // Usar el controlador
        _telefonoController.text, // Usar el controlador
        widget.ordenSeleccionada.comentarioEnvio,
        comentario,
        widget.bultoVirtual.tipoBultoId,
        incluyeFactura,
        widget.bultoVirtual.nroBulto,
        widget.bultoVirtual.totalBultos,
        tokenFinal, // USAR TOKEN FINAL
      );

      // await EntregaServices().patchBultoEstado(
      //   context,
      //   widget.entrega.entregaId,
      //   widget.bultoVirtual.bultoId,
      //   'CERRADO',
      //   widget.token,
      // );
    } catch (e) {
      throw Exception('Error al cerrar bulto VIRTUAL: ${e.toString()}');
    }
  }

  Future<void> _procesarCierre() async {
    final totalBultos = _cantidadesPorTipo.values.fold(0, (sum, cantidad) => sum + cantidad);
    
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
        'Para envío debe seleccionar empresa y transportista', 
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
      // USAR TOKEN DEL PIN SI ESTÁ DISPONIBLE
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final tokenPin = productProvider.tokenPin;
      final tokenFinal = tokenPin.isNotEmpty ? tokenPin : widget.token;
      
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
            tokenFinal, // USAR TOKEN FINAL
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
          _nombreEnvioController.text,
          _metodoEnvio!.modoEnvioId,
          _transportistaSeleccionado?.formaEnvioId ?? 0,
          _empresaEnvioSeleccionada?.formaEnvioId ?? 0,
          _direccionController.text, // Usar el controlador
          _localidadController.text, // Usar el controlador
          _departamentoController.text, // Usar el controlador
          _telefonoController.text, // Usar el controlador
          widget.ordenSeleccionada.comentarioEnvio,
          _comentarioController.text,
          bulto.tipoBultoId,
          _incluyeFactura,
          bulto.nroBulto,
          bulto.totalBultos,
          tokenFinal, // USAR TOKEN FINAL
        );
        
        await EntregaServices().patchBultoEstado(
          context,
          widget.entrega.entregaId,
          bulto.bultoId,
          'CERRADO',
          tokenFinal, // USAR TOKEN FINAL
        );
      }
      
      await _cerrarBultoVirtual(_comentarioController.text, _incluyeFactura);
      
      await EntregaServices().cerrarEntrega(
        context,
        widget.entrega.entregaId,
        tokenFinal, // USAR TOKEN FINAL
      );
      
      // LIMPIAR COMPLETAMENTE EL ESTADO DE LA ENTREGA
      productProvider.setTokenPin('');
      productProvider.setUserIdPin(0);
      productProvider.setEntrega(Entrega.empty()); // ← AÑADIR ESTO
      productProvider.setOrdenesExpedicion([]); // ← AÑADIR ESTO
      
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

  Widget _buildFormularioCierre() {
    final tiposDisponibles = widget.tipoBultos
        .where((tipo) => tipo.codTipoBulto != "VIRTUAL")
        .toList();

    _metodoEnvio = (widget.ordenSeleccionada.envio && _metodoEnvio == null) 
      ? widget.modoEnvios.firstWhere(
          (m) => m.modoEnvioId == widget.ordenSeleccionada.modoEnvioId,
          orElse: () => widget.modoEnvios.isNotEmpty ? widget.modoEnvios.first : ModoEnvio.empty(),
        ) 
      : _metodoEnvio;
    _empresaEnvioSeleccionada = widget.ordenSeleccionada.envio && widget.ordenSeleccionada.formaIdEnvio != 0 
      ? widget.empresasEnvio.firstWhere(
          (e) => e.formaEnvioId == widget.ordenSeleccionada.formaIdEnvio,
          orElse: () => widget.empresasEnvio.isNotEmpty ? widget.empresasEnvio.first : FormaEnvio.empty(),
        ) 
      : _empresaEnvioSeleccionada;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDatosEnvio(),
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
                _buildCantidadControl(tipo.tipoBultoId),
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
          const SizedBox(height: 8,),
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
        const Text('Comentario Envio:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8,),
        TextField(
          controller: _comentarioEnvioController,
          minLines: 2,
          maxLines: 4,
          enabled: !_procesandoCierre,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        // const Text('Comentario:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        // const SizedBox(height: 8),
        // TextField(
        //   controller: _comentarioController,
        //   minLines: 2,
        //   maxLines: 4,
        //   enabled: !_procesandoCierre,
        //   decoration: InputDecoration(
        //     border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        //     contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        //   ),
        // ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // TextButton(
            //   style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            //   onPressed: _procesandoCierre ? null : () => Navigator.of(context).pop(),
            //   child: const Text('Cancelar'),
            // ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: _procesandoCierre ? null : _procesarCierre, // CAMBIO: Quitar _solicitarPin2 y usar _procesarCierre directamente
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
          onPressed: _mostrarPopupReimprimirEtiquetas, // ← Nuevo método
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          icon: Icon(Icons.print, color: colors.onPrimary,),
          label: const Text('Imprimir Detalle de Entrega'),
          onPressed: _mostrarPopupImprimirDetalle, // ← Nuevo método
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
            // Y RESETEAR EL TOKEN DEL PIN
            final productProvider = Provider.of<ProductProvider>(context, listen: false);
            productProvider.setTokenPin('');
            productProvider.setUserIdPin(0);
            productProvider.setEntrega(Entrega.empty());
            productProvider.setOrdenesExpedicion([]);
            Navigator.of(context).popUntil((route) => route.settings.name == '/expedicionPaquetes');
            GoRouter.of(context).pushReplacement('/expedicionPaquetes');
          },
          child: const Text('Finalizar'),
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

  Widget _buildCantidadControl(int tipoBultoId) {
    final cantidad = _cantidadesPorTipo[tipoBultoId] ?? 0;
    final controller = _controllers[tipoBultoId]!;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botón de disminuir
          IconButton(
            icon: const Icon(Icons.remove, size: 20),
            onPressed: _procesandoCierre ? null : () {
              final nuevaCantidad = (cantidad - 1).clamp(0, 999);
              _actualizarCantidad(tipoBultoId, nuevaCantidad);
            },
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
          ),
          
          // Campo de texto en el medio
          SizedBox(
            width: 60,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              enabled: !_procesandoCierre,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (value) {
                final nuevaCantidad = int.tryParse(value) ?? 0;
                _actualizarCantidad(tipoBultoId, nuevaCantidad);
              },
            ),
          ),
          
          // Botón de aumentar
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: _procesandoCierre ? null : () {
              final nuevaCantidad = cantidad + 1;
              _actualizarCantidad(tipoBultoId, nuevaCantidad);
            },
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _actualizarCantidad(int tipoBultoId, int nuevaCantidad) {
    setState(() {
      _cantidadesPorTipo[tipoBultoId] = nuevaCantidad;
      _controllers[tipoBultoId]!.text = nuevaCantidad.toString();
    });
  }

  Future<void> _mostrarPopupReimprimirEtiquetas() async {
    final bultosNoVirtuales = _bultosCerrados.where((b) => 
      b.tipoBultoId != widget.bultoVirtual.tipoBultoId
    ).toList();

    if (bultosNoVirtuales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay bultos disponibles para imprimir')),
      );
      return;
    }

    final Set<int> bultosSeleccionados = {};

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Reimprimir Etiquetas'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Seleccione los bultos a imprimir:'),
                    const SizedBox(height: 16),
                    ...bultosNoVirtuales.map((bulto) {
                      final tipoBulto = widget.tipoBultos.firstWhere(
                        (t) => t.tipoBultoId == bulto.tipoBultoId,
                        orElse: () => TipoBulto.empty()
                      );
                      
                      return CheckboxListTile(
                        title: Text('Bulto ${bulto.bultoId} - ${tipoBulto.descripcion}'),
                        value: bultosSeleccionados.contains(bulto.bultoId),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              bultosSeleccionados.add(bulto.bultoId);
                            } else {
                              bultosSeleccionados.remove(bulto.bultoId);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: bultosSeleccionados.isEmpty
                    ? null
                    : () async {
                        Navigator.of(context).pop();
                        await _reimprimirEtiquetasSeleccionadas(bultosSeleccionados.toList());
                      },
                child: const Text('Imprimir'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _reimprimirEtiquetasSeleccionadas(List<int> bultosIds) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imprimiendo etiquetas...')),
      );

      // USAR TOKEN DEL PIN SI ESTÁ DISPONIBLE
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final tokenPin = productProvider.tokenPin;
      final tokenFinal = tokenPin.isNotEmpty ? tokenPin : widget.token;

      // Imprimir cada bulto seleccionado
      for (int bultoId in bultosIds) {
        await EntregaServices().imprimirEtiqueta(
          context,
          bultoId,
          context.read<ProductProvider>().almacen.almacenId,
          tokenFinal, // USAR TOKEN FINAL
        );
        // Pequeña pausa entre impresiones
        await Future.delayed(const Duration(milliseconds: 500));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${bultosIds.length} etiqueta(s) impresa(s) correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al imprimir etiquetas: ${e.toString()}')),
      );
    }
  }

  Future<void> _mostrarPopupImprimirDetalle() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Imprimir Detalle'),
        content: const Text('¿Desea imprimir el detalle de la entrega?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _imprimirDetalleEntrega();
            },
            child: const Text('Imprimir'),
          ),
        ],
      ),
    );
  }

  Future<void> _imprimirDetalleEntrega() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imprimiendo detalle de entrega...')),
      );

      // USAR TOKEN DEL PIN SI ESTÁ DISPONIBLE
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final tokenPin = productProvider.tokenPin;
      final tokenFinal = tokenPin.isNotEmpty ? tokenPin : widget.token;

      // Imprimir detalle del bulto virtual (que representa la entrega completa)
      await EntregaServices().imprimirDetalle(
        context,
        widget.bultoVirtual.bultoId,
        context.read<ProductProvider>().almacen.almacenId,
        tokenFinal, // USAR TOKEN FINAL
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Detalle de entrega impreso correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al imprimir detalle: ${e.toString()}')),
      );
    }
  }

  // Agregar este método para construir la sección de datos de envío
  Widget _buildDatosEnvio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Datos de envío:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 12),
        
        // Nombre de envío
        const Text('Nombre:', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: _nombreEnvioController,
          enabled: !_procesandoCierre && !widget.modoReadOnly,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            hintText: 'Nombre',
          ),
        ),
        const SizedBox(height: 12),
        
        // Dirección
        const Text('Dirección:', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: _direccionController,
          enabled: !_procesandoCierre && !widget.modoReadOnly,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            hintText: 'Dirección',
          ),
        ),
        const SizedBox(height: 12),
        
        // Localidad
        const Text('Localidad:', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: _localidadController,
          enabled: !_procesandoCierre && !widget.modoReadOnly,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            hintText: 'Localidad',
          ),
        ),
        const SizedBox(height: 12),
        
        // Departamento
        const Text('Departamento:', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: _departamentoController,
          enabled: !_procesandoCierre && !widget.modoReadOnly,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            hintText: 'Departamento',
          ),
        ),
        const SizedBox(height: 12),
        
        // Teléfono
        const Text('Teléfono:', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: _telefonoController,
          enabled: !_procesandoCierre && !widget.modoReadOnly,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            hintText: 'Teléfono',
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // MÉTODO _solicitarPin2 ELIMINADO - Ya no se solicita PIN aquí

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: PopScope(
        canPop: false,
        child: Scaffold(
          appBar: AppBar(
            title: Text(_entregaFinalizada ? 'Bultos Cerrados' : 'Crear y cerrar bultos'),
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            automaticallyImplyLeading: false,
          ),
          body: _procesandoCierre
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: _entregaFinalizada || widget.modoReadOnly
                      ? _buildBultosCerrados()
                      : _buildFormularioCierre(),
                ),
        ),
      ),
    );
  }
}