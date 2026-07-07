import 'package:flutter/material.dart';
import '../config/theme.dart';

class ErrorRetryWidget extends StatelessWidget {
  final String message;
  final Object? error;
  final VoidCallback onRetry;

  const ErrorRetryWidget({
    super.key,
    required this.message,
    this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 36),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: AppTheme.textMuted),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                error.toString(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.error.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
