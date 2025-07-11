import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:deposito/models/usuario.dart';

class FiltrosEntregas extends StatefulWidget {
  final List<Usuario>? usuarios;
  final Function(
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    Usuario? usuario,
  ) onSearch;
  final Function onReset;
  final bool isFilterExpanded;
  final Function(bool) onToggleFilter;
  final int cantidadDeEntregas;

  const FiltrosEntregas({
    super.key,
    this.usuarios,
    required this.onSearch,
    required this.onReset,
    required this.isFilterExpanded,
    required this.onToggleFilter,
    this.cantidadDeEntregas = 0,
  });

  @override
  State<FiltrosEntregas> createState() => _FiltrosEntregasState();
}

class _FiltrosEntregasState extends State<FiltrosEntregas> {
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  Usuario? _selectedUsuario;

  bool _hasActiveFilters() {
    return _fechaDesde != null ||
          _fechaHasta != null ||
          _selectedUsuario != null;
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
      _selectedUsuario,
    );
    widget.onToggleFilter(false);
  }

  // void _resetFilters() {
  //   setState(() {
  //     _fechaDesde = null;
  //     _fechaHasta = null;
  //     _selectedUsuario = null;
  //   });
  //   widget.onReset();
  // }

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
                        widget.cantidadDeEntregas == 0 ? '' : widget.cantidadDeEntregas.toString(),
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
                        if (widget.usuarios != null)
                          DropdownSearch<Usuario>(
                            selectedItem: _selectedUsuario,
                            items: widget.usuarios!,
                            dropdownDecoratorProps: const DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                labelText: 'Usuario',
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
                                _selectedUsuario = value;
                              });
                            },
                          ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
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
                            ),
                          ],
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