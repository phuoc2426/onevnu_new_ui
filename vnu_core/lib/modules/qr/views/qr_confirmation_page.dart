import 'package:flutter/material.dart';
import 'package:vnu_core/modules/qr/models/qr_resolution.dart';

class QrConfirmationPage extends StatelessWidget {
  const QrConfirmationPage({
    super.key,
    required this.resolution,
  });

  final QrResolution resolution;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận QR')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Icon(Icons.qr_code_2_rounded, size: 72),
              const SizedBox(height: 24),
              Text(
                resolution.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                resolution.description,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '${resolution.provider} • ${resolution.type}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(resolution.actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
