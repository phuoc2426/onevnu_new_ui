import 'package:flutter/material.dart';
import 'package:vnu_core/services/app_update_coordinator.dart';
import 'package:vnu_core/widgets/app_update_store_dialog.dart';

class AppUpdateGate extends StatelessWidget {
  const AppUpdateGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppUpdateGateSnapshot>(
      valueListenable: AppUpdateCoordinator.instance.notifier,
      builder: (context, snapshot, _) {
        final blockApp = snapshot.shouldBlock;
        final showOptional = snapshot.shouldShowOptional;
        final showOverlay = blockApp || showOptional;

        return PopScope(
          canPop: !showOverlay,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              AbsorbPointer(
                absorbing: blockApp || showOptional,
                child: child,
              ),
              if (showOverlay) ...<Widget>[
                ModalBarrier(
                  dismissible: false,
                  color: Colors.black.withValues(alpha: 0.56),
                ),
                SafeArea(
                  child: Center(
                    child: _UpdateCard(snapshot: snapshot),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({required this.snapshot});

  final AppUpdateGateSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    if (snapshot.mode == AppUpdateGateMode.checking) {
      return const _CheckingCard();
    }

    final policy = snapshot.platformPolicy;
    final force = snapshot.mode == AppUpdateGateMode.force;

    final message = force
        ? ((policy?.forceMessage ?? '').trim().isEmpty
            ? 'Phiên bản OneVNU hiện tại đã cũ. Vui lòng cập nhật để tiếp tục sử dụng ứng dụng.'
            : policy!.forceMessage.trim())
        : ((policy?.optionalMessage ?? '').trim().isEmpty
            ? 'OneVNU đã có phiên bản mới. Bạn có muốn cập nhật ngay không?'
            : policy!.optionalMessage.trim());

    return AppUpdateStoreChooser(
      force: force,
      message: message,
      onClose: force ? null : AppUpdateCoordinator.instance.dismissOptional,
    );
  }
}

class _CheckingCard extends StatelessWidget {
  const _CheckingCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            SizedBox(width: 14),
            Flexible(child: Text('Đang kiểm tra phiên bản OneVNU...')),
          ],
        ),
      ),
    );
  }
}
