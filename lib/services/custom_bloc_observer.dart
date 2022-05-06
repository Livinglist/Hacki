import 'package:bloc/bloc.dart';
import 'package:hacki/config/locator.dart';
import 'package:logger/logger.dart';

class CustomBlocObserver extends BlocObserver {
  @override
  void onEvent(
    Bloc<dynamic, dynamic> bloc,
    Object? event,
  ) {
    locator.get<Logger>().d(event);
    super.onEvent(bloc, event);
  }

  @override
  void onError(
    BlocBase<dynamic> bloc,
    Object error,
    StackTrace stackTrace,
  ) {
    locator.get<Logger>().e(error);
    super.onError(bloc, error, stackTrace);
  }
}
