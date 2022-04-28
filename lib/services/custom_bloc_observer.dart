import 'package:bloc/bloc.dart';
import 'package:hacki/extensions/extensions.dart' show ObjectExtension;

class CustomBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    bloc.log(identifier: 'Bloc Created:');
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    event?.log(identifier: 'Bloc Event:');
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    change.log(identifier: 'Bloc Changed:');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    error.log(identifier: 'Bloc Error:');
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    bloc.log(identifier: 'Bloc Closed:');
  }
}
