import 'package:dio/dio.dart';

class CachedResponse<T> extends Response<T> {
  CachedResponse({
    required super.requestOptions,
    super.data,
  }) : setDateTime = DateTime.now();

  factory CachedResponse.fromResponse(Response<T> response) {
    return CachedResponse<T>(
      requestOptions: response.requestOptions,
      data: response.data,
    );
  }

  final DateTime setDateTime;
}
