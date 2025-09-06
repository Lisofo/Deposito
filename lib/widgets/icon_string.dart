import 'package:flutter/material.dart';

final _icons = <String, IconData>{
  'corporate_fare_rounded': Icons.corporate_fare_rounded,
  'task': Icons.task,
  'person': Icons.person,
  'bug_report': Icons.bug_report,
  'assignment': Icons.assignment,
  'grading': Icons.grading,
  'calendar_month': Icons.calendar_month,
  'event_busy': Icons.event_busy,
  'map': Icons.map,
  'settings_sharp': Icons.settings_sharp,
  'person_add_alt_1': Icons.person_add_alt_1,
  'security': Icons.security,
  'groups': Icons.groups,
  'my_library_books_rounded': Icons.my_library_books_rounded,
  'person_3_rounded': Icons.person_3_rounded,
  'task_outlined': Icons.task_outlined,
  'grain_outlined': Icons.grain_outlined,
  'person_pin_circle_outlined': Icons.person_pin_circle_outlined,
  'inventory' : Icons.inventory,
  'checklist' : Icons.checklist,
  'assignment_ind' : Icons.assignment_ind,
  'compare_arrows': Icons.compare_arrows,
  'move_to_inbox': Icons.move_to_inbox,
  'shopping_basket' : Icons.shopping_basket,
  'sell' : Icons.sell,
  'list_alt' : Icons.list_alt,
  'exit_to_app' : Icons.exit_to_app,
  'dashboard' : Icons.dashboard,
  'monitor' : Icons.monitor,
  'handshake' : Icons.handshake,
  'shopping_bag' : Icons.shopping_bag,
  'local_shipping' : Icons.local_shipping,
  'settings_ethernet' : Icons.settings_ethernet,
};

Icon getIcon(String iconName, BuildContext context, Color colors) {
  // final colors = Theme.of(context).colorScheme;
  return Icon(
    _icons[iconName],
    color: colors
  );
}
