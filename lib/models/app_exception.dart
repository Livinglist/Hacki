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

class RateLimitedWithFallbackException extends AppException {
  RateLimitedWithFallbackException()
      : super(message: 'Rate limited, fetching from API instead...');
}

class GeneralException extends AppException {
  GeneralException() : super(message: 'Something went wrong...');
}
