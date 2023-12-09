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

class PossibleParsingException extends AppException {
  PossibleParsingException({
    required this.itemId,
  }) : super(message: 'Possible parsing failure...');

  final int itemId;
}

class BrowserNotRunningException extends AppException {
  BrowserNotRunningException() : super(message: 'Browser not running...');
}

class GenericException extends AppException {
  GenericException() : super(message: 'Something went wrong...');
}
