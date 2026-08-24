import 'dart:async';

import '../utils.dart';
import 'app_error.dart';
import 'app_error_mapper.dart';
import 'app_error_reporter.dart';

class AppFeedback {
  AppFeedback._();

  static String? _lastMessage;
  static DateTime? _lastShownAt;

  static AppError showError(
    Object error, {
    StackTrace? stackTrace,
    String? fallbackMessage,
    bool report = true,
  }) {
    final appError = AppErrorMapper.map(
      error,
      stackTrace: stackTrace,
      fallbackMessage: fallbackMessage,
    );
    return showAppError(
      appError,
      stackTrace: stackTrace,
      report: report,
    );
  }

  static AppError showAppError(
    AppError error, {
    StackTrace? stackTrace,
    bool report = true,
  }) {
    if (report) {
      unawaited(
        AppErrorReporter.report(
          error,
          stackTrace: stackTrace,
        ),
      );
    }

    if (!error.isSilent) {
      _showErrorMessage(error.displayMessage);
    }
    return error;
  }

  static void showWarning(String message) {
    final normalized = message.trim();
    if (normalized.isEmpty) return;
    snackBarWarning(normalized);
  }

  static void showSuccess(String message) {
    final normalized = message.trim();
    if (normalized.isEmpty) return;
    snackBarSuccess(normalized);
  }

  static void _showErrorMessage(String message) {
    final now = DateTime.now();
    if (_lastMessage == message &&
        _lastShownAt != null &&
        now.difference(_lastShownAt!).inMilliseconds < 900) {
      return;
    }

    _lastMessage = message;
    _lastShownAt = now;
    snackBarError(message);
  }
}
