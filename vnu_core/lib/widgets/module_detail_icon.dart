import 'package:flutter/material.dart';

/// Local 3D icon assets for One Door and ULIS tuition row-level UI.
/// Keep quick_access icons separate: those can be replaced by the designer's
/// own icon pack without affecting the module detail icons.
class ModuleDetailIcon extends StatelessWidget {
  const ModuleDetailIcon({
    super.key,
    required this.name,
    this.size = 26,
    this.semanticLabel,
  });

  final String name;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/icons/module_details/$name.png',
        package: 'vnu_core',
        width: size,
        height: size,
        fit: BoxFit.contain,
        semanticLabel: semanticLabel,
        filterQuality: FilterQuality.medium,
      );
}
