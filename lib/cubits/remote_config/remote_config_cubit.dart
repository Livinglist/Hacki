import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/repositories/remote_config_repository.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:logger/logger.dart';

part 'remote_config_state.dart';

class RemoteConfigCubit extends HydratedCubit<RemoteConfigState> {
  RemoteConfigCubit({
    RemoteConfigRepository? remoteConfigRepository,
    Logger? logger,
  })  : _remoteConfigRepository =
            remoteConfigRepository ?? locator.get<RemoteConfigRepository>(),
        _logger = logger ?? locator.get<Logger>(),
        super(RemoteConfigState.init()) {
    init();
  }

  final RemoteConfigRepository _remoteConfigRepository;
  final Logger _logger;
  static const String _logPrefix = '';

  void init() {
    _remoteConfigRepository
        .fetchRemoteConfig()
        .then((Map<String, dynamic> data) {
      if (data.isNotEmpty) {
        _logger.i('$_logPrefix remote config fetched: $data');
        emit(state.copyWith(data: data));
      } else {
        _logger.i('$_logPrefix empty remote config.');
      }
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
