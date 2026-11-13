import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file/file.dart' as fs;
import 'package:file/memory.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves a bundled image for image downloads, without opening any sockets.
///
/// Both NetworkImage and flutter_cache_manager's IOClient use this client.
/// Await image precaching with tester.runAsync before taking a screenshot.
Future<void> installGoldenImageHttp() async {
  final ByteData asset = await rootBundle.load('assets/images/hacki_icon.png');
  final Uint8List bytes = asset.buffer.asUint8List(
    asset.offsetInBytes,
    asset.lengthInBytes,
  );
  final HttpOverrides? previous = HttpOverrides.current;
  final BaseCacheManager previousCache =
      CachedNetworkImageProvider.defaultCacheManager;
  final fs.File image = MemoryFileSystem().file('/golden-image.png')
    ..writeAsBytesSync(bytes);
  CachedNetworkImageProvider.defaultCacheManager = _MemoryImages(image);
  HttpOverrides.global = _ImageHttpOverrides(bytes);
  PaintingBinding.instance.imageCache
    ..clear()
    ..clearLiveImages();
  addTearDown(() {
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    HttpOverrides.global = previous;
    CachedNetworkImageProvider.defaultCacheManager = previousCache;
  });
}

/// Avoids cache databases, filesystem I/O, expiry timers, and platform paths.
/// CachedNetworkImage still performs its normal decoding and presentation.
class _MemoryImages extends Fake implements BaseCacheManager {
  _MemoryImages(this.image);

  final fs.File image;

  FileInfo _info(String url) =>
      FileInfo(image, FileSource.Cache, DateTime.utc(2100), url);

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) => Stream<FileResponse>.value(_info(url));

  @override
  Future<fs.File> getSingleFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) async => image;

  @override
  Future<FileInfo?> getFileFromCache(
    String key, {
    bool ignoreMemCache = false,
  }) async => _info(key);

  @override
  Future<FileInfo?> getFileFromMemory(String key) async => _info(key);

  @override
  Future<void> emptyCache() async {}

  @override
  Future<void> removeFile(String key) async {}

  @override
  Future<void> dispose() async {}
}

class _ImageHttpOverrides extends HttpOverrides {
  _ImageHttpOverrides(this.bytes);

  final Uint8List bytes;

  @override
  HttpClient createHttpClient(SecurityContext? context) => _ImageClient(bytes);
}

class _ImageClient extends Fake implements HttpClient {
  _ImageClient(this.bytes);

  final Uint8List bytes;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _ImageRequest(bytes);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _ImageRequest(bytes);

  @override
  set autoUncompress(bool value) {}

  @override
  set connectionTimeout(Duration? value) {}

  @override
  set idleTimeout(Duration value) {}

  @override
  set userAgent(String? value) {}

  @override
  void close({bool force = false}) {}
}

class _ImageRequest extends Fake implements HttpClientRequest {
  _ImageRequest(this.bytes);

  final Uint8List bytes;

  @override
  HttpHeaders get headers => _ImageHeaders(bytes.length);

  @override
  set followRedirects(bool value) {}

  @override
  set maxRedirects(int value) {}

  @override
  set persistentConnection(bool value) {}

  @override
  set contentLength(int value) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await stream.drain<void>();
  }

  @override
  Future<HttpClientResponse> close() async => _ImageResponse(bytes);

  @override
  Future<HttpClientResponse> get done async => _ImageResponse(bytes);

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}
}

class _ImageResponse extends StreamView<List<int>>
    implements HttpClientResponse {
  _ImageResponse(Uint8List bytes)
    : contentLength = bytes.length,
      headers = _ImageHeaders(bytes.length),
      super(Stream<List<int>>.value(bytes));

  @override
  final int contentLength;

  @override
  final HttpHeaders headers;

  @override
  int get statusCode => HttpStatus.ok;

  @override
  String get reasonPhrase => 'OK';

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  List<RedirectInfo> get redirects => const <RedirectInfo>[];

  @override
  X509Certificate? get certificate => null;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected image HTTP operation: $invocation');
}

class _ImageHeaders extends Fake implements HttpHeaders {
  _ImageHeaders(this.length);

  final int length;

  Map<String, List<String>> get _values => <String, List<String>>{
    HttpHeaders.contentTypeHeader: <String>['image/png'],
    HttpHeaders.contentLengthHeader: <String>['$length'],
    HttpHeaders.cacheControlHeader: <String>['public, max-age=31536000'],
    HttpHeaders.etagHeader: <String>['golden-hacki-icon'],
  };

  @override
  ContentType get contentType => ContentType('image', 'png');

  @override
  int get contentLength => length;

  @override
  List<String>? operator [](String name) => _values[name.toLowerCase()];

  @override
  String? value(String name) => this[name]?.join(',');

  @override
  void forEach(void Function(String name, List<String> values) action) =>
      _values.forEach(action);

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}
