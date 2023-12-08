typedef AppExceptionHandler = void Function(AppException);

class AppException implements Exception {
  AppException({
    required this.message,
    this.stackTrace,
  });

  final String message;
  final StackTrace? stackTrace;
}

class RateLimitedException extends AppException {
  RateLimitedException() : super(message: 'Rate limited...');
}
