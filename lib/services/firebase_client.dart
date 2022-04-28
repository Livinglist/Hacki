import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';

/// FirebaseClient wraps a REST client for a Firebase realtime database.
///
/// The client supports authentication and GET, PUT, POST, DELETE
/// and PATCH methods.
class FirebaseClient {
  /// Creates a new FirebaseClient with [credential] and optional [client].
  ///
  /// For credential you can either use Firebase app's secret or
  /// an authentication token.
  /// See: <https://firebase.google.com/docs/reference/rest/database/user-auth>.
  FirebaseClient(this.credential, {Client? client})
      : _client = client ?? Client();

  /// Creates a new anonymous FirebaseClient with optional [client].
  FirebaseClient.anonymous({Client? client})
      : credential = null,
        _client = client ?? Client();

  /// Auth credential.
  final String? credential;
  final Client _client;

  /// Reads data from database using a HTTP GET request.
  /// The response from a successful request contains a data being retrieved.
  ///
  /// See: <https://firebase.google.com/docs/reference/rest/database/#section-get>.
  Future<dynamic> get(dynamic uri) => send('GET', uri);

  /// Writes or replaces data in database using a HTTP PUT request.
  /// The response from a successful request contains a data being written.
  ///
  /// See: <https://firebase.google.com/docs/reference/rest/database/#section-put>.
  Future<dynamic> put(dynamic uri, dynamic json) =>
      send('PUT', uri, json: json);

  /// Pushes data to database using a HTTP POST request.
  /// The response from a successful request contains a key of the new data
  /// being added.
  ///
  /// See: <https://firebase.google.com/docs/reference/rest/database/#section-post>.
  Future<dynamic> post(dynamic uri, dynamic json) =>
      send('POST', uri, json: json);

  /// Updates specific children at a location without overwriting existing data
  /// using a HTTP PATCH request.
  /// The response from a successful request contains a data being written.
  ///
  /// See: <https://firebase.google.com/docs/reference/rest/database/#section-patch>.
  Future<dynamic> patch(dynamic uri, dynamic json) =>
      send('PATCH', uri, json: json);

  /// Deletes data from database using a HTTP DELETE request.
  /// The response from a successful request contains a JSON with `null`.
  ///
  /// See: <https://firebase.google.com/docs/reference/rest/database/#section-delete>.
  Future<void> delete(dynamic uri) => send('DELETE', uri);

  /// Creates a request with a HTTP [method], [url] and optional data.
  /// The [url] can be either a `String` or `Uri`.
  Future<Object?> send(String method, dynamic url, {dynamic json}) async {
    final Uri uri = url is String ? Uri.parse(url) : url as Uri;

    final Request request = Request(method, uri);
    if (credential != null) {
      request.headers['Authorization'] = 'Bearer $credential';
    }

    if (json != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(json);
    }

    final StreamedResponse streamedResponse = await _client.send(request);
    final Response response = await Response.fromStream(streamedResponse);

    Object? bodyJson;
    try {
      bodyJson = jsonDecode(response.body);
    } on FormatException {
      final String? contentType = response.headers['content-type'];
      if (contentType != null && !contentType.contains('application/json')) {
        throw Exception(
          "Returned value was not JSON. Did the uri end with '.json'?",
        );
      }
      rethrow;
    }

    if (response.statusCode != 200) {
      if (bodyJson is Map) {
        final dynamic error = bodyJson['error'];
        if (error != null) {
          throw FirebaseClientException(response.statusCode, error.toString());
        }
      }

      throw FirebaseClientException(response.statusCode, bodyJson.toString());
    }

    return bodyJson;
  }

  /// Closes the client and cleans up any associated resources.
  void close() => _client.close();
}

class FirebaseClientException implements Exception {
  FirebaseClientException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => '$message ($statusCode)';
}
