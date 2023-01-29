import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/config/custom_log_filter.dart';
import 'package:hacki/config/file_output.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/services/services.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

/// Global [GetIt.instance].
final GetIt locator = GetIt.instance;

/// Set up [GetIt] locator.
Future<void> setUpLocator() async {
  final Directory tempDir = await getTemporaryDirectory();
  final File outputFile = File('${tempDir.path}/${Constants.logFilename}');
  locator
    ..registerSingleton<Logger>(
      Logger(
        filter: CustomLogFilter(),
        printer: kReleaseMode
            ? SimplePrinter()
            : PrettyPrinter(
                methodCount: 0,
              ),
        output: MultiOutput(
          <LogOutput>[
            ConsoleOutput(),
            CustomFileOutput(
              file: outputFile,
              overrideExisting: true,
            ),
          ],
        ),
      ),
    )
    ..registerSingleton<StoriesRepository>(StoriesRepository())
    ..registerSingleton<PreferenceRepository>(PreferenceRepository())
    ..registerSingleton<SearchRepository>(SearchRepository())
    ..registerSingleton<AuthRepository>(AuthRepository())
    ..registerSingleton<PostRepository>(PostRepository())
    ..registerSingleton<SembastRepository>(SembastRepository())
    ..registerSingleton<OfflineRepository>(OfflineRepository())
    ..registerSingleton<DraftCache>(DraftCache())
    ..registerSingleton<CommentCache>(CommentCache())
    ..registerSingleton<LocalNotification>(LocalNotification())
    ..registerSingleton<RouteObserver<ModalRoute<dynamic>>>(
      RouteObserver<ModalRoute<dynamic>>(),
    );
}
