// widgets/custom_segmented_control.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomSegmentedControl extends StatelessWidget {
  final int groupValue;
  final ValueChanged<int> onValueChanged;
  final Map<int, String> options;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? textColor;
  final bool usePickingStyle;
  final double? fontSize;

  const CustomSegmentedControl({
    super.key,
    required this.groupValue,
    required this.onValueChanged,
    required this.options,
    this.padding,
    this.borderColor,
    this.selectedColor,
    this.unselectedColor,
    this.textColor,
    this.usePickingStyle = false,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    // Si usePickingStyle es true, usa los colores específicos de pedidos.dart
    final effectiveBorderColor = usePickingStyle 
        ? colors.primary 
        : borderColor ?? colors.primary;
    
    final effectiveSelectedColor = usePickingStyle 
        ? colors.primary 
        : selectedColor ?? colors.primary;
    
    final effectiveUnselectedColor = usePickingStyle 
        ? Colors.white 
        : unselectedColor ?? Colors.white;

    return CupertinoSegmentedControl<int>(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 10),
      groupValue: groupValue,
      borderColor: effectiveBorderColor,
      selectedColor: effectiveSelectedColor,
      unselectedColor: effectiveUnselectedColor,
      children: _buildChildren(options),
      onValueChanged: onValueChanged,
    );
  }

  Map<int, Widget> _buildChildren(Map<int, String> options) {
    return options.map((key, value) {
      return MapEntry(key, _buildSegment(value));
    });
  }

  Widget _buildSegment(String text) {
    if (usePickingStyle) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize ?? 14,
              color: textColor,
            ),
          ),
        ),
      );
    } else {
      return Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color: textColor,
        ),
      );
    }
  }
}

// Helper class para opciones predefinidas
class SegmentedOptions {
  static const Map<int, String> pickingStates = {
    0: 'Pendiente',
    1: 'En Proceso',
    2: 'Preparado',
    -1: 'Mis ordenes',
  };

  static const Map<int, String> expedicionStates = {
    0: 'Preparado',
    1: 'Embalaje',
    2: 'Entrega parcial',
  };

  static const Map<int, String> bultosStates = {
    0: 'Todos',
    1: 'Pendiente',
    2: 'Cerrado',
    3: 'Retirado',
    4: 'Devuelto'
  };

  static const Map<int, String> monitorOrdenes = {
    0: 'Todos',
    1: 'Pendiente',
    2: 'En Proceso',
    3: 'Preparado',
  };

  static const Map<int, String> monitorEntregas = {
    0: 'Todos',
    1: 'Pendiente',
    2: 'En Proceso',
    3: 'Finalizada',
  };

  static const Map<int, String> monitorBultos = {
    0: 'Todos',
    1: 'Pendiente',
    2: 'Cerrado',
    3: 'Despachado',
  };
}