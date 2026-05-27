import 'dart:math' as math;
import 'package:flutter/material.dart';

class YOnlyCard extends StatelessWidget {
  const YOnlyCard({
    super.key,
    required this.width,
    required this.height,
    required this.angleY,
    required this.front,
    required this.back,
    required this.matrixProvider,
    required this.isBackProvider,
  });

  final double width, height, angleY;
  final Widget front, back;
  final Matrix4 Function(double angleY) matrixProvider;
  final bool Function(double angleY) isBackProvider;

  @override
  Widget build(BuildContext context) {
    final isBack = isBackProvider(angleY);
    final m = matrixProvider(angleY);

    return Transform(
      alignment: Alignment.center,
      transform: m,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _Face(visible: !isBack, child: front),
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(math.pi),
                child: _Face(visible: isBack, child: back),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.visible, required this.child, super.key});
  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: visible ? 1 : 0,
        child: child,
      ),
    );
  }
}
