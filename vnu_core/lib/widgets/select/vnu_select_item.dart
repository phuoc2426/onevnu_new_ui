class VnuSelectItem<T> {
  const VnuSelectItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.enabled = true,
    this.searchText,
  });

  final T value;
  final String label;
  final String? subtitle;
  final bool enabled;
  final String? searchText;

  String get effectiveSearchText =>
      (searchText == null || searchText!.trim().isEmpty)
          ? [label, subtitle ?? ''].join(' ')
          : searchText!;
}
