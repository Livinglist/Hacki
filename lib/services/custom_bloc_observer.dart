import 'package:bloc/bloc.dart';
import 'package:hacki/config/locator.dart';
import 'package:logger/logger.dart';

class CustomBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase<dynamic> bloc) {
    locator.get<Logger>().v('$bloc created');
    super.onCreate(bloc);
  }

  @override
  void onEvent(
    Bloc<dynamic, dynamic> bloc,
    Object? event,
  ) {
    locator.get<Logger>().v(event);
    super.onEvent(bloc, event);
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    locator.get<Logger>().v(transition);
    super.onTransition(bloc, transition);
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
