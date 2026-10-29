class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() {
    if (code != null) return '[$code] $message';
    return message;
  }
}

class AppAuthException extends AppException {
  AppAuthException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class NetworkException extends AppException {
  NetworkException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class CacheException extends AppException {
  CacheException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class ApiException extends AppException {
  ApiException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}
