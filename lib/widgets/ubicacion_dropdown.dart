import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:deposito/models/ubicacion_almacen.dart';

class UbicacionDropdown extends StatelessWidget {
  final List<UbicacionAlmacen> listaUbicaciones;
  final UbicacionAlmacen? selectedItem;
  final ValueChanged<UbicacionAlmacen?> onChanged;
  final bool enabled;
  final String hintText;
  final VoidCallback? onPopupDismissed; // NUEVO

  const UbicacionDropdown({
    super.key,
    required this.listaUbicaciones,
    required this.selectedItem,
    required this.onChanged,
    this.enabled = true,
    this.hintText = 'Seleccione ubicación',
    this.onPopupDismissed, // NUEVO
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownSearch<UbicacionAlmacen>(
        dropdownDecoratorProps: DropDownDecoratorProps(
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          dropdownSearchDecoration: InputDecoration(
            hintText: hintText,
            alignLabelWithHint: true,
            border: InputBorder.none,
          ),
        ),
        enabled: enabled,
        popupProps: PopupProps.menu(
          showSearchBox: true,
          searchDelay: Duration.zero,
          itemBuilder: (context, item, isSelected) {
            return ListTile(
              title: Text('${item.codUbicacion} ${item.descripcion}'),
              trailing: item.tipoUbicacion == 'I'
                  ? const Icon(Icons.compare_arrows, color: Colors.blue)
                  : null,
            );
          },
          onDismissed: onPopupDismissed, // NUEVO
        ),
        onChanged: onChanged,
        items: listaUbicaciones,
        selectedItem: selectedItem,
      ),
    );
  }
}