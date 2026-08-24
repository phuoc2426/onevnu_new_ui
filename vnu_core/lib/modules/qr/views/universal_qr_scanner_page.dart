import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vnu_core/modules/qr/cubit/qr_cubit.dart';
import 'package:vnu_core/modules/qr/views/qr_confirmation_page.dart';

class UniversalQrScannerPage extends StatefulWidget {
  const UniversalQrScannerPage({super.key});

  @override
  State<UniversalQrScannerPage> createState() =>
      _UniversalQrScannerPageState();
}

class _UniversalQrScannerPageState
    extends State<UniversalQrScannerPage> {
  final MobileScannerController _scannerController =
      MobileScannerController();

  late final QrCubit _cubit;
  bool _scanLocked = false;

  @override
  void initState() {
    super.initState();
    _cubit = QrCubit();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanLocked) return;

    String? raw;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.trim().isNotEmpty) {
        raw = value;
        break;
      }
    }

    if (raw == null || raw.trim().isEmpty) return;

    _scanLocked = true;
    await _scannerController.stop();
    await _cubit.resolve(raw);
  }

  Future<void> _resume() async {
    _cubit.reset();
    _scanLocked = false;
    await _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<QrCubit, QrState>(
        listener: (context, state) async {
          if (state is QrResolved) {
            final confirmed =
                await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => QrConfirmationPage(
                  resolution: state.resolution,
                ),
              ),
            );

            if (!mounted) return;

            if (confirmed == true) {
              await _cubit.execute(state.resolution);
            } else {
              await _cubit.cancel(state.resolution);
              await _resume();
            }
          }

          if (state is QrExecuted) {
            if (!mounted) return;
            await showDialog<void>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Thành công'),
                content: Text(state.result.message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            );
            if (mounted) {
              await _resume();
            }
          }

          if (state is QrFailure) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            await _resume();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Quét QR'),
            actions: [
              IconButton(
                tooltip: 'Đèn pin',
                onPressed: _scannerController.toggleTorch,
                icon: const Icon(Icons.flashlight_on_rounded),
              ),
            ],
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: _onDetect,
              ),
              IgnorePointer(
                child: Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              BlocBuilder<QrCubit, QrState>(
                builder: (context, state) {
                  if (state is QrResolving ||
                      state is QrExecuting) {
                    return Container(
                      color: Colors.black38,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
