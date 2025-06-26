import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:deposito/models/usuario.dart';

class FiltrosPicking extends StatefulWidget {
  final List<Usuario>? usuarios;
  final Function(DateTime? fechaDesde, DateTime? fechaHasta, String? prioridad, 
      List<Map<String, String>>? tipos, Usuario? usuarioCreado, Usuario? usuarioMod) onSearch;
  final Function onReset;
  final TextEditingController nombreController;
  final TextEditingController numeroDocController;
  final bool isFilterExpanded;
  final Function(bool) onToggleFilter;
  final List<Map<String, String>>? tiposDisponibles;
  final List<Map<String, String>>? selectedTiposIniciales;
  final bool mostrarFiltroUsuarios;
  final bool mostrarFiltroTipos;
  final int cantidadDeOrdenes;

  const FiltrosPicking({
    super.key,
    this.usuarios,
    required this.onSearch,
    required this.onReset,
    required this.nombreController,
    required this.numeroDocController,
    required this.isFilterExpanded,
    required this.onToggleFilter,
    this.tiposDisponibles,
    this.selectedTiposIniciales,
    this.mostrarFiltroUsuarios = true,
    this.mostrarFiltroTipos = true,
    this.cantidadDeOrdenes = 0
  });

  @override
  State<FiltrosPicking> createState() => _FiltrosPickingState();
}

class _FiltrosPickingState extends State<FiltrosPicking> {
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  String? _selectedPrioridad;
  List<Map<String, String>>? _selectedTipos = [];
  Usuario? _selectedUsuarioCreado;
  Usuario? _selectedUsuarioMod;

  final List<String> _prioridades = ['ALTA', 'NORMAL', 'BAJA', 'TODAS'];
  late List<Map<String, String>> _tipos;

  @override
  void initState() {
    super.initState();
    _tipos = widget.tiposDisponibles ?? [
      {'value': 'C', 'label': 'Compra'},
      {'value': 'TE', 'label': 'Remito Entrada'},
      {'value': 'V', 'label': 'Venta'},
      {'value': 'TS', 'label': 'Remito Salida'},
      {'value': 'P', 'label': 'Pedido de venta'},
      {'value': '', 'label': 'Todos'},
    ];
    
    // Inicializar los tipos seleccionados si vienen del padre
    if (widget.selectedTiposIniciales != null) {
      _selectedTipos = widget.selectedTiposIniciales;
    }
  }

  bool _hasActiveFilters() {
    return _fechaDesde != null ||
          _fechaHasta != null ||
          (_selectedPrioridad != null && _selectedPrioridad != 'TODAS') ||
          (_selectedTipos != null && _selectedTipos!.isNotEmpty) ||
          widget.nombreController.text.isNotEmpty ||
          widget.numeroDocController.text.isNotEmpty ||
          _selectedUsuarioCreado != null ||
          _selectedUsuarioMod != null;
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
                        widget.cantidadDeOrdenes == 0 ? '' : widget.cantidadDeOrdenes.toString(),
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
                                controller: widget.nombreController,
                                decoration: const InputDecoration(
                                  labelText: 'Cliente/Proveedor',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.search),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: widget.numeroDocController,
                                decoration: const InputDecoration(
                                  labelText: 'Número de documento',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.search),
                                ),
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
                        DropdownButtonFormField<String>(
                          value: _selectedPrioridad,
                          decoration: InputDecoration(
                            labelText: 'Prioridad',
                            border: const OutlineInputBorder(),
                            suffixIcon: _selectedPrioridad != null && _selectedPrioridad != 'TODAS'
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _selectedPrioridad = 'TODAS';
                                    });
                                  },
                                )
                              : null,
                          ),
                          items: _prioridades.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedPrioridad = newValue;
                            });
                          },
                        ),
                        if (widget.mostrarFiltroTipos) ...[
                          const SizedBox(height: 15),
                          DropdownSearch<Map<String, String>>.multiSelection(
                            selectedItems: _selectedTipos ?? [],
                            items: _tipos,
                            dropdownDecoratorProps: const DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                labelText: 'Tipo',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            popupProps: PopupPropsMultiSelection.menu(
                              searchFieldProps: TextFieldProps(
                                decoration: InputDecoration(
                                  suffixIcon: _selectedTipos != null && _selectedTipos!.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setState(() => _selectedTipos = []);
                                        },
                                      )
                                    : null,
                                  hintText: 'Buscar tipo...',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              itemBuilder: (context, item, isSelected) {
                                return ListTile(
                                  title: Text(item['label']!),
                                  trailing: isSelected ? const Icon(Icons.check) : null,
                                );
                              },
                              emptyBuilder: (context, searchEntry) => const Center(
                                child: Text('No se encontraron tipos'),
                              ),
                            ),
                            onChanged: (values) {
                              setState(() => _selectedTipos = values);
                            },
                            dropdownBuilder: (context, selectedItems) {
                              if (selectedItems.isEmpty) {
                                return const Text('Seleccionar tipos...');
                              }
                              return Text(
                                selectedItems.map((tipo) => tipo['label']!).join(', '),
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        ],
                        if (widget.mostrarFiltroUsuarios && widget.usuarios != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownSearch<Usuario>(
                                  selectedItem: _selectedUsuarioCreado,
                                  items: widget.usuarios!,
                                  dropdownDecoratorProps: const DropDownDecoratorProps(
                                    dropdownSearchDecoration: InputDecoration(
                                      labelText: 'Creado por',
                                      border: OutlineInputBorder()
                                    ),
                                  ),
                                  popupProps: const PopupProps.menu(
                                    showSearchBox: true,
                                    searchDelay: Duration.zero,
                                    searchFieldProps: TextFieldProps(
                                      decoration: InputDecoration(
                                        hintText: 'Buscar usuario...',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedUsuarioCreado = value;
                                    });
                                  },
                                )
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownSearch<Usuario>(
                                  selectedItem: _selectedUsuarioMod,
                                  items: widget.usuarios!,
                                  dropdownDecoratorProps: const DropDownDecoratorProps(
                                    dropdownSearchDecoration: InputDecoration(
                                      labelText: 'Ultima modificación por',
                                      border: OutlineInputBorder()
                                    ),
                                  ),
                                  popupProps: const PopupProps.menu(
                                    showSearchBox: true,
                                    searchDelay: Duration.zero,
                                    searchFieldProps: TextFieldProps(
                                      decoration: InputDecoration(
                                        hintText: 'Buscar usuario...',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedUsuarioMod = value;
                                    });
                                  },
                                )
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            widget.onSearch(
                              _fechaDesde, 
                              _fechaHasta, 
                              _selectedPrioridad, 
                              _selectedTipos ?? [], // Provide empty list if null
                              _selectedUsuarioCreado, 
                              _selectedUsuarioMod
                            );
                          },
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