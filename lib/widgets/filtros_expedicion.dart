import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FiltrosExpedicion extends StatefulWidget {
  final Function(DateTime? fechaDesde, DateTime? fechaHasta, String? cliente, String? numeroDocumento, String? pickId) onSearch;
  final Function onReset;
  final TextEditingController clienteController;
  final TextEditingController numeroDocController;
  final TextEditingController pickIDController;
  final bool isFilterExpanded;
  final Function(bool) onToggleFilter;
  final int cantidadDeOrdenes;

  const FiltrosExpedicion({
    super.key,
    required this.onSearch,
    required this.onReset,
    required this.clienteController,
    required this.numeroDocController,
    required this.pickIDController,
    required this.isFilterExpanded,
    required this.onToggleFilter,
    this.cantidadDeOrdenes = 0
  });

  @override
  State<FiltrosExpedicion> createState() => _FiltrosExpedicionState();
}

class _FiltrosExpedicionState extends State<FiltrosExpedicion> {
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  final FocusNode _clienteFocusNode = FocusNode();
  final FocusNode _numeroDocFocusNode = FocusNode();
  final FocusNode _pickIdFocusNode = FocusNode();

  bool _hasActiveFilters() {
    return _fechaDesde != null ||
          _fechaHasta != null ||
          widget.clienteController.text.isNotEmpty ||
          widget.numeroDocController.text.isNotEmpty ||
          widget.pickIDController.text.isNotEmpty;
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
      widget.clienteController.text,
      widget.numeroDocController.text,
      widget.pickIDController.text
    );
    widget.onToggleFilter(false); // Cerrar los filtros después de buscar
  }

  @override
  void initState() {
    super.initState();
    _clienteFocusNode.addListener(() {
      if (!_clienteFocusNode.hasFocus) {
        _handleSearch();
      }
    });
    _numeroDocFocusNode.addListener(() {
      if (!_numeroDocFocusNode.hasFocus) {
        _handleSearch();
      }
    });
    _pickIdFocusNode.addListener(() {
      if (!_pickIdFocusNode.hasFocus) {
        _handleSearch();
      }
    });
  }

  @override
  void dispose() {
    _clienteFocusNode.dispose();
    _numeroDocFocusNode.dispose();
    _pickIdFocusNode.dispose();
    super.dispose();
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
                                controller: widget.clienteController,
                                focusNode: _clienteFocusNode,
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
                                controller: widget.numeroDocController,
                                focusNode: _numeroDocFocusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Número de documento',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.search),
                                ),
                                onSubmitted: (value) => _handleSearch(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: widget.pickIDController,
                                focusNode: _pickIdFocusNode,
                                decoration: const InputDecoration(
                                  labelText: 'PickID',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.search),
                                ),
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