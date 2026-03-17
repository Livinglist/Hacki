typedef AppExceptionHandler = void Function(AppException);

class AppException implements Exception {
  AppException({required this.message, this.stackTrace, this.error});

  final String? message;
  final StackTrace? stackTrace;
  final dynamic error;
}

class RateLimitedException extends AppException {
  RateLimitedException(
    this.statusCode, {
    super.error,
  }) : super(message: 'Rate limited ($statusCode)...');

  final int? statusCode;
}

class RateLimitedWithFallbackException extends AppException {
  RateLimitedWithFallbackException(
    this.statusCode, {
    super.error,
  }) : super(
          message: 'Rate limited ($statusCode), fetching from API instead...',
        );

  final int? statusCode;
}

class TooManyRequestsException extends AppException {
  TooManyRequestsException({
    required this.retryAfter,
    super.error,
  }) : super(
          message:
              '''Too many requests (429), retry after ${retryAfter.toIso8601String()}, fetching from API instead...''',
        );

  /// The time after which app can keep sending in requests.
  final DateTime retryAfter;
}

class ParsingException extends AppException {
  ParsingException({
    required this.itemId,
    super.error,
  }) : super(message: 'Possible parsing failure for item with id $itemId...');

  final int itemId;
}

class GenericException extends AppException {
  GenericException({
    super.error,
  }) : super(message: 'Something went wrong...');
}
