import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../themes/app_theme.dart';

class LoadingIndicator extends StatefulWidget {
  final double? height;
  final double radius;
  final Color? color;
  const LoadingIndicator({Key? key, this.height, this.color, this.radius = 14})
      : super(key: key);

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator> {
  Timer? _timer;
  bool _endLoading = false;
  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(minutes: 1), () {
      setState(() {
        _endLoading = true;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height ?? 100,
      child: Center(
        child: _endLoading
            ? const SizedBox()
            : CupertinoActivityIndicator(
                color: widget.color ?? AppTheme.colorMain,
                radius: widget.radius,
              ),
      ),
    );
  }
}
