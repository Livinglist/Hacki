import 'package:get_it/get_it.dart';
import 'package:hacki/config/custom_log_filter.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/services/services.dart';
import 'package:logger/logger.dart';

/// Global [GetIt.instance].
final GetIt locator = GetIt.instance;

/// Set up [GetIt] locator.
Future<void> setUpLocator() async {
  locator
    ..registerSingleton<StoriesRepository>(StoriesRepository())
    ..registerSingleton<PreferenceRepository>(PreferenceRepository())
    ..registerSingleton<SearchRepository>(SearchRepository())
    ..registerSingleton<AuthRepository>(AuthRepository())
    ..registerSingleton<PostRepository>(PostRepository())
    ..registerSingleton<SembastRepository>(SembastRepository())
    ..registerSingleton<CacheRepository>(CacheRepository())
    ..registerSingleton<CacheService>(CacheService())
    ..registerSingleton<LocalNotification>(LocalNotification())
    ..registerSingleton<Logger>(Logger(filter: CustomLogFilter()));
}
