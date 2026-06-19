import 'package:flutter/material.dart';

class PahtV2EmptyState extends StatelessWidget {
  final String title;
  final String? description;

  const PahtV2EmptyState({
    super.key,
    this.title = 'Không có dữ liệu',
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xffEEF4F8),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.inbox_outlined, color: Color(0xff637392), size: 34),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xff071A44)),
            ),
            if (description != null) ...[
              const SizedBox(height: 6),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xff637392)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
