import 'package:flutter/material.dart';
import 'package:vnu_core/services/app_update_coordinator.dart';

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

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 420,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              blurRadius: 30,
              offset: Offset(0, 12),
              color: Color(0x33000000),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.system_update_alt_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        force ? 'Yêu cầu cập nhật' : 'Có phiên bản mới',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      if (snapshot.evaluation != null)
                        Text(
                          'Phiên bản hiện tại: ${snapshot.evaluation!.currentVersion}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                if (!force) ...<Widget>[
                  TextButton(
                    onPressed: AppUpdateCoordinator.instance.dismissOptional,
                    child: const Text('Để sau'),
                  ),
                  const SizedBox(width: 8),
                ],
                FilledButton.icon(
                  onPressed: () {
                    AppUpdateCoordinator.instance.openStore();
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: Text(force ? 'Cập nhật ngay' : 'Cập nhật'),
                ),
              ],
            ),
          ],
        ),
      ),
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
