import 'package:flutter/material.dart';
import 'package:flutter_app/config/theme_extension.dart';

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
          Icon(Icons.error_outline_rounded, color: context.colors.error, size: 36),
          SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: context.colors.textMuted),
          ),
          if (error != null) ...[
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                error.toString(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.colors.error.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ),
          ],
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }
}
