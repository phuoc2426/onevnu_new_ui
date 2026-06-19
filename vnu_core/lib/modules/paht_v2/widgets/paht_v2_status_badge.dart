import 'package:flutter/material.dart';

class PahtV2StatusBadge extends StatelessWidget {
  final String? status;

  const PahtV2StatusBadge({super.key, this.status});

  bool get _isDone => (status ?? '').toLowerCase().contains('datraloi') || (status ?? '').toLowerCase().contains('da');

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDone ? const Color(0xffE7F8EF) : const Color(0xffFFF6E8);
    final textColor = _isDone ? const Color(0xff008B52) : const Color(0xffC77900);
    final text = _isDone ? 'Đã xử lý' : 'Chưa xử lý';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }
}
