import 'package:dio/dio.dart';

class CachedResponse<T> extends Response<T> {
  CachedResponse({
    required super.requestOptions,
    super.data,
    super.statusCode,
  }) : setDateTime = DateTime.now();

  factory CachedResponse.fromResponse(Response<T> response) {
    return CachedResponse<T>(
      requestOptions: response.requestOptions,
      data: response.data,
      statusCode: response.statusCode,
    );
  }

  final DateTime setDateTime;
}
