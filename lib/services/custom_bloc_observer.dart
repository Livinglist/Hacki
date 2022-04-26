import 'package:bloc/bloc.dart';
import 'package:hacki/extensions/extensions.dart' show ObjectExtension;

class CustomBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    bloc.log(identifier: 'Bloc Created:');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    event?.log(identifier: 'Bloc Event:');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    change.log(identifier: 'Bloc Changed:');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    error.log(identifier: 'Bloc Error:');
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    bloc.log(identifier: 'Bloc Closed:');
  }
}
