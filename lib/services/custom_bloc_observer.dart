import 'package:bloc/bloc.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:logger/logger.dart';

class CustomBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase<dynamic> bloc) {
    if (bloc is! CollapseCubit) {
      locator.get<Logger>().v('$bloc created');
    }

    super.onCreate(bloc);
  }

  @override
  void onEvent(
    Bloc<dynamic, dynamic> bloc,
    Object? event,
  ) {
    if (event is! StoriesEvent) {
      locator.get<Logger>().v(event);
    }

    super.onEvent(bloc, event);
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    if (bloc is! StoriesBloc) {
      locator.get<Logger>().v(transition);
    }

    super.onTransition(bloc, transition);
  }

  @override
  void onError(
    BlocBase<dynamic> bloc,
    Object error,
    StackTrace stackTrace,
  ) {
    locator.get<Logger>().e(error);
    locator.get<Logger>().e(stackTrace);

    super.onError(bloc, error, stackTrace);
  }
}
