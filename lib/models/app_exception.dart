typedef AppExceptionHandler = void Function(AppException);

class AppException implements Exception {
  AppException({
    required this.message,
    this.stackTrace,
  });

  final String? message;
  final StackTrace? stackTrace;
}

class RateLimitedException extends AppException {
  RateLimitedException(this.statusCode)
      : super(message: 'Rate limited ($statusCode)...');

  final int? statusCode;
}

class RateLimitedWithFallbackException extends AppException {
  RateLimitedWithFallbackException(this.statusCode)
      : super(
          message: 'Rate limited ($statusCode), fetching from API instead...',
        );

  final int? statusCode;
}

class PossibleParsingException extends AppException {
  PossibleParsingException({
    required this.itemId,
  }) : super(message: 'Possible parsing failure...');

  final int itemId;
}

class GenericException extends AppException {
  GenericException() : super(message: 'Something went wrong...');
}
