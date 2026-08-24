import 'package:flutter/material.dart';
import 'package:vnu_core/common/error/app_error.dart';

class VnuErrorState extends StatelessWidget {
  const VnuErrorState({
    super.key,
    this.title = 'Không thể tải nội dung',
    required this.message,
    this.supportCode,
    this.onRetry,
    this.compact = false,
  });

  factory VnuErrorState.fromAppError(
    AppError error, {
    Key? key,
    String title = 'Không thể tải nội dung',
    VoidCallback? onRetry,
    bool compact = false,
  }) {
    return VnuErrorState(
      key: key,
      title: title,
      message: error.userMessage,
      supportCode: error.requestId,
      onRetry: error.canRetry ? onRetry : null,
      compact: compact,
    );
  }

  final String title;
  final String message;
  final String? supportCode;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: compact ? 28 : 42,
                color: theme.colorScheme.error,
              ),
              SizedBox(height: compact ? 8 : 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              if (supportCode?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 6),
                Text(
                  'Mã hỗ trợ: ${supportCode!.trim()}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (onRetry != null) ...[
                SizedBox(height: compact ? 10 : 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Thử lại'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class VnuEmptyState extends StatelessWidget {
  const VnuEmptyState({
    super.key,
    this.title = 'Chưa có dữ liệu',
    this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String? message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.outline),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (message?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(
                message!.trim(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class VnuLoadingState extends StatelessWidget {
  const VnuLoadingState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(message!.trim(), textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

class VnuUnexpectedErrorWidget extends StatelessWidget {
  const VnuUnexpectedErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF8F9FA),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Không thể hiển thị nội dung này.\nVui lòng thử lại sau.',
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

/// Backward-compatible wrapper for existing screens.
class ErrorRefreshWidget extends StatelessWidget {
  const ErrorRefreshWidget({
    super.key,
    required this.message,
    this.refreshAction,
    this.padding = 60,
  });

  final String? message;
  final double padding;
  final VoidCallback? refreshAction;

  @override
  Widget build(BuildContext context) {
    return VnuErrorState(
      message: message?.trim().isNotEmpty == true
          ? message!.trim()
          : 'Dữ liệu chưa thể tải lúc này.',
      onRetry: refreshAction,
      compact: padding < 40,
    );
  }
}
