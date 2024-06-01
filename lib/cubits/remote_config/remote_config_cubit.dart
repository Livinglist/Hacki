import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/repositories/remote_config_repository.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'remote_config_state.dart';

class RemoteConfigCubit extends HydratedCubit<RemoteConfigState> {
  RemoteConfigCubit({RemoteConfigRepository? remoteConfigRepository})
      : _remoteConfigRepository =
            remoteConfigRepository ?? locator.get<RemoteConfigRepository>(),
        super(RemoteConfigState.init()) {
    init();
  }

  final RemoteConfigRepository _remoteConfigRepository;

  void init() {
    _remoteConfigRepository
        .fetchRemoteConfig()
        .then((Map<String, dynamic> data) {
      emit(state.copyWith(data: data));
    });
  }

  @override
  RemoteConfigState? fromJson(Map<String, dynamic> json) {
    return RemoteConfigState(data: json);
  }

  @override
  Map<String, dynamic>? toJson(RemoteConfigState state) {
    return state.data;
  }
}
