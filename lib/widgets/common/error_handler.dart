import 'package:flutter/material.dart';

enum ErrorType {
  network,
  permission,
  validation,
  firestore,
  unknown,
}

class AppError {
  final String message;
  final ErrorType type;
  final String? details;
  final dynamic originalError;

  const AppError({
    required this.message,
    required this.type,
    this.details,
    this.originalError,
  });

  factory AppError.network(String message, [dynamic originalError]) =>
      AppError(
        message: message,
        type: ErrorType.network,
        originalError: originalError,
      );

  factory AppError.permission(String message, [dynamic originalError]) =>
      AppError(
        message: message,
        type: ErrorType.permission,
        originalError: originalError,
      );

  factory AppError.validation(String message, [dynamic originalError]) =>
      AppError(
        message: message,
        type: ErrorType.validation,
        originalError: originalError,
      );

  factory AppError.firestore(String message, [dynamic originalError]) =>
      AppError(
        message: message,
        type: ErrorType.firestore,
        originalError: originalError,
      );

  factory AppError.unknown(String message, [dynamic originalError]) =>
      AppError(
        message: message,
        type: ErrorType.unknown,
        originalError: originalError,
      );
}

class ErrorHandler {
  static const Map<ErrorType, IconData> _errorIcons = {
    ErrorType.network: Icons.wifi_off,
    ErrorType.permission: Icons.lock,
    ErrorType.validation: Icons.error_outline,
    ErrorType.firestore: Icons.cloud_off,
    ErrorType.unknown: Icons.warning,
  };

  static const Map<ErrorType, Color> _errorColors = {
    ErrorType.network: Colors.orange,
    ErrorType.permission: Colors.red,
    ErrorType.validation: Colors.amber,
    ErrorType.firestore: Colors.blue,
    ErrorType.unknown: Colors.grey,
  };

  /// Shows a snackbar with error message
  static void showSnackBar(BuildContext context, AppError error) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _errorIcons[error.type] ?? Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error.message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _errorColors[error.type] ?? Colors.red,
        behavior: SnackBarBehavior.floating,
        action: error.details != null
            ? SnackBarAction(
                label: 'Details',
                textColor: Colors.white,
                onPressed: () => _showErrorDialog(context, error),
              )
            : null,
      ),
    );
  }

  /// Shows an error dialog with detailed information
  static void showErrorDialog(BuildContext context, AppError error) {
    if (!context.mounted) return;
    _showErrorDialog(context, error);
  }

  static void _showErrorDialog(BuildContext context, AppError error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _errorIcons[error.type] ?? Icons.error,
              color: _errorColors[error.type],
            ),
            const SizedBox(width: 8),
            Text(_getErrorTitle(error.type)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.message),
            if (error.details != null) ...[
              const SizedBox(height: 12),
              const Text(
                'Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                error.details!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (_canRetry(error.type))
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // You can add retry logic here
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  /// Returns an error widget for displaying in UI
  static Widget buildErrorWidget(
    AppError error, {
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _errorIcons[error.type] ?? Icons.error,
              size: 64,
              color: _errorColors[error.type],
            ),
            const SizedBox(height: 16),
            Text(
              customMessage ?? error.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (error.details != null) ...[
              const SizedBox(height: 8),
              Text(
                error.details!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (onRetry != null && _canRetry(error.type))
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }

  /// Converts generic exceptions to AppError
  static AppError fromException(dynamic exception) {
    if (exception is AppError) return exception;

    String message = exception.toString();

    // Network related errors
    if (message.contains('network') || 
        message.contains('connection') ||
        message.contains('timeout')) {
      return AppError.network(
        'Network connection error. Please check your internet connection.',
        exception,
      );
    }

    // Firestore related errors
    if (message.contains('firestore') || 
        message.contains('firebase') ||
        message.contains('permission-denied')) {
      return AppError.firestore(
        'Database error occurred. Please try again.',
        exception,
      );
    }

    // Permission errors
    if (message.contains('permission')) {
      return AppError.permission(
        'Permission denied. Please check your access rights.',
        exception,
      );
    }

    // Default to unknown error
    return AppError.unknown(
      'An unexpected error occurred. Please try again.',
      exception,
    );
  }

  static String _getErrorTitle(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return 'Connection Error';
      case ErrorType.permission:
        return 'Permission Error';
      case ErrorType.validation:
        return 'Validation Error';
      case ErrorType.firestore:
        return 'Database Error';
      case ErrorType.unknown:
        return 'Unexpected Error';
    }
  }

  static bool _canRetry(ErrorType type) {
    switch (type) {
      case ErrorType.network:
      case ErrorType.firestore:
      case ErrorType.unknown:
        return true;
      case ErrorType.permission:
      case ErrorType.validation:
        return false;
    }
  }
}