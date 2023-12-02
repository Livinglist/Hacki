import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hacki/config/custom_log_filter.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/utils/utils.dart';
import 'package:logger/logger.dart';

/// Global [GetIt.instance].
final GetIt locator = GetIt.instance;

/// Set up [GetIt] locator.
Future<void> setUpLocator() async {
  final File logOutputFile = await LogUtil.initLogFile();

  locator
    ..registerSingleton<Logger>(
      Logger(
        filter: CustomLogFilter(),
        printer: LogUtil.logPrinter,
        output: LogUtil.logOutput(logOutputFile),
      ),
    )
    ..registerSingleton<SembastRepository>(SembastRepository())
    ..registerSingleton<HackerNewsRepository>(HackerNewsRepository())
    ..registerSingleton<HackerNewsWebRepository>(HackerNewsWebRepository())
    ..registerSingleton<PreferenceRepository>(PreferenceRepository())
    ..registerSingleton<SearchRepository>(SearchRepository())
    ..registerSingleton<AuthRepository>(AuthRepository())
    ..registerSingleton<PostRepository>(PostRepository())
    ..registerSingleton<OfflineRepository>(OfflineRepository())
    ..registerSingleton<DraftCache>(DraftCache())
    ..registerSingleton<CommentCache>(CommentCache())
    ..registerSingleton<LocalNotificationService>(LocalNotificationService())
    ..registerSingleton(AppReviewService())
    ..registerSingleton<RouteObserver<ModalRoute<dynamic>>>(
      RouteObserver<ModalRoute<dynamic>>(),
    );
}
