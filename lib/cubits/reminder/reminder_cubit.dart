import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/repositories/repositories.dart';

part 'reminder_state.dart';

class ReminderCubit extends Cubit<ReminderState> {
  ReminderCubit({PreferenceRepository? preferenceRepository})
    : _preferenceRepository =
          preferenceRepository ?? locator.get<PreferenceRepository>(),
      super(const ReminderState.init()) {
    unawaited(init());
  }

  final PreferenceRepository _preferenceRepository;

  Future<void> init() async {
    final List<ConnectivityResult> status = await Connectivity()
        .checkConnectivity();
    if (status.contains(ConnectivityResult.none)) {
      return;
    } else {
      await _preferenceRepository.lastReadStoryId.then((int? value) {
        emit(state.copyWith(storyId: value));
      });
    }
  }

  void onDismiss() {
    emit(state.copyWith(hasShown: true));
  }

  void updateLastReadStoryId(int? storyId) {
    _preferenceRepository.updateLastReadStoryId(storyId);
  }

  void removeLastReadStoryId() {
    _preferenceRepository.updateLastReadStoryId(null);
  }
}
