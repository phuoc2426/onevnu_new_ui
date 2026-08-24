import 'vnu_select_item.dart';

class VnuSelectGroup<T> {
  const VnuSelectGroup({
    required this.label,
    required this.items,
    this.initiallyExpanded = false,
  });

  final String label;
  final List<VnuSelectItem<T>> items;
  final bool initiallyExpanded;
}
