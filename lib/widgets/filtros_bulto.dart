import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:deposito/models/usuario.dart';
import 'package:deposito/models/modo_envio.dart';
import 'package:deposito/models/tipo_bulto.dart';

class FiltrosBulto extends StatefulWidget {
  final List<Usuario>? usuarios;
  final List<ModoEnvio>? modosEnvio;
  final List<TipoBulto>? tiposBulto;
  final Function(
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int? modoEnvioId,
    int? tipoBultoId,
    Usuario? usuarioArmado,
    String? nombreCliente,
    String? bultoId,
  ) onSearch;
  final Function onReset;
  final TextEditingController nombreClienteController;
  final TextEditingController bultoIdController;
  final bool isFilterExpanded;
  final Function(bool) onToggleFilter;
  final int cantidadDeBultos;

  const FiltrosBulto({
    super.key,
    this.usuarios,
    this.modosEnvio,
    this.tiposBulto,
    required this.onSearch,
    required this.onReset,
    required this.nombreClienteController,
    required this.bultoIdController,
    required this.isFilterExpanded,
    required this.onToggleFilter,
    this.cantidadDeBultos = 0,
  });

  @override
  State<FiltrosBulto> createState() => _FiltrosBultoState();
}

class _FiltrosBultoState extends State<FiltrosBulto> {
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  int? _selectedModoEnvioId;
  int? _selectedTipoBultoId;
  Usuario? _selectedUsuarioArmado;
  final FocusNode _nombreClienteFocusNode = FocusNode();
  final FocusNode _bultoIdFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nombreClienteFocusNode.addListener(() {
      if (!_nombreClienteFocusNode.hasFocus) {
        _handleSearch();
      }
    });
    _bultoIdFocusNode.addListener(() {
      if (!_bultoIdFocusNode.hasFocus) {
        _handleSearch();
      }
    });
  }

  @override
  void dispose() {
    _nombreClienteFocusNode.dispose();
    _bultoIdFocusNode.dispose();
    super.dispose();
  }

  bool _hasActiveFilters() {
    return _fechaDesde != null ||
          _fechaHasta != null ||
          _selectedModoEnvioId != null ||
          _selectedTipoBultoId != null ||
          widget.nombreClienteController.text.isNotEmpty ||
          widget.bultoIdController.text.isNotEmpty ||
          _selectedUsuarioArmado != null;
  }

  Future<void> _selectDate(BuildContext context, bool isDesde) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isDesde) {
          _fechaDesde = picked;
        } else {
          _fechaHasta = picked;
        }
      });
    }
  }

  void _handleSearch() {
    widget.onSearch(
      _fechaDesde,
      _fechaHasta,
      _selectedModoEnvioId,
      _selectedTipoBultoId,
      _selectedUsuarioArmado,
      widget.nombreClienteController.text.isNotEmpty ? widget.nombreClienteController.text : null,
      widget.bultoIdController.text.isNotEmpty ? widget.bultoIdController.text : null,
    );
    widget.onToggleFilter(false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Card(
      margin: const EdgeInsets.all(10),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              widget.onToggleFilter(!widget.isFilterExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const Icon(Icons.filter_list),
                  const SizedBox(width: 8),
                  const Text(
                    'Filtros',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_hasActiveFilters())
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.cantidadDeBultos == 0 ? '' : widget.cantidadDeBultos.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    widget.isFilterExpanded 
                      ? Icons.keyboard_arrow_up 
                      : Icons.keyboard_arrow_down,
                  ),
                ],
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: widget.isFilterExpanded ? null : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: widget.isFilterExpanded ? 1.0 : 0.0,
              child: widget.isFilterExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      children: [
                        const Divider(),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: widget.nombreClienteController,
                                focusNode: _nombreClienteFocusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Cliente',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.search),
                                ),
                                onSubmitted: (value) => _handleSearch(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: widget.bultoIdController,
                                focusNode: _bultoIdFocusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Número de bulto',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.search),
                                ),
                                keyboardType: TextInputType.number,
                                onSubmitted: (value) => _handleSearch(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context, true),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Fecha Desde',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: _fechaDesde != null
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            setState(() {
                                              _fechaDesde = null;
                                            });
                                          },
                                        )
                                      : const Icon(Icons.calendar_today, size: 18),
                                  ),
                                  child: Text(
                                    _fechaDesde != null 
                                      ? DateFormat('dd/MM/yyyy').format(_fechaDesde!)
                                      : 'Seleccionar fecha',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context, false),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Fecha Hasta',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: _fechaHasta != null
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            setState(() {
                                              _fechaHasta = null;
                                            });
                                          },
                                        )
                                      : const Icon(Icons.calendar_today, size: 18),
                                  ),
                                  child: Text(
                                    _fechaHasta != null 
                                      ? DateFormat('dd/MM/yyyy').format(_fechaHasta!)
                                      : 'Seleccionar fecha',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        if (widget.modosEnvio != null)
                          DropdownSearch<ModoEnvio>(
                            selectedItem: _selectedModoEnvioId != null
                              ? widget.modosEnvio!.firstWhere(
                                  (m) => m.modoEnvioId == _selectedModoEnvioId,
                                  orElse: () => ModoEnvio.empty(),
                                )
                              : null,
                            items: widget.modosEnvio!,
                            dropdownDecoratorProps: const DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                labelText: 'Modo de envío',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            popupProps: const PopupProps.menu(
                              showSearchBox: true,
                              searchFieldProps: TextFieldProps(
                                decoration: InputDecoration(
                                  hintText: 'Buscar modo de envío...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _selectedModoEnvioId = value?.modoEnvioId;
                              });
                            },
                          ),
                        const SizedBox(height: 15),
                        if (widget.tiposBulto != null)
                          DropdownSearch<TipoBulto>(
                            selectedItem: _selectedTipoBultoId != null
                              ? widget.tiposBulto!.firstWhere(
                                  (t) => t.tipoBultoId == _selectedTipoBultoId,
                                  orElse: () => TipoBulto.empty(),
                                )
                              : null,
                            items: widget.tiposBulto!,
                            dropdownDecoratorProps: const DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                labelText: 'Tipo de bulto',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            popupProps: const PopupProps.menu(
                              showSearchBox: true,
                              searchFieldProps: TextFieldProps(
                                decoration: InputDecoration(
                                  hintText: 'Buscar tipo de bulto...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _selectedTipoBultoId = value?.tipoBultoId;
                              });
                            },
                          ),
                        const SizedBox(height: 15),
                        if (widget.usuarios != null)
                          DropdownSearch<Usuario>(
                            selectedItem: _selectedUsuarioArmado,
                            items: widget.usuarios!,
                            dropdownDecoratorProps: const DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                labelText: 'Armado por',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            popupProps: const PopupProps.menu(
                              showSearchBox: true,
                              searchFieldProps: TextFieldProps(
                                decoration: InputDecoration(
                                  hintText: 'Buscar usuario...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _selectedUsuarioArmado = value;
                              });
                            },
                          ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: _handleSearch,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: colors.primary,
                          ),
                          child: const Text(
                            'BUSCAR',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(),
            ),
          ),
        ],
      ),
    );
  }
}