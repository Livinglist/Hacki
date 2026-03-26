import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/repositories/repositories.dart';

part 'tips_state.dart';

extension on Tips {
  String get completionStatusKey => '${name}_tips_completed';
}

class TipsCubit extends Cubit<TipsState> {
  TipsCubit({
    PreferenceRepository? preferenceRepository,
  })  : _preferenceRepository =
            preferenceRepository ?? locator.get<PreferenceRepository>(),
        super(const TipsState.init()) {
    unawaited(init());
  }

  final PreferenceRepository _preferenceRepository;

  Future<void> init() async {
    final Set<Tips> completedTips = <Tips>{};
    for (final Tips tips in Tips.values) {
      final String key = tips.completionStatusKey;
      final bool? hasCompleted = await _preferenceRepository.getBool(key);
      if (hasCompleted ?? false) {
        completedTips.add(tips);
      }
    }
    emit(
      state.copyWith(
        completedTips: completedTips,
      ),
    );
  }

  Future<void> reset() async {
    for (final Tips tips in Tips.values) {
      final String key = tips.completionStatusKey;
      _preferenceRepository.setBool(key, false);
    }
    emit(
      state.copyWith(
        completedTips: const <Tips>{},
      ),
    );
  }

  void completeTips(Tips tips) {
    final String key = tips.completionStatusKey;
    _preferenceRepository.setBool(key, true);
    final Set<Tips> updatedCompletedTips = <Tips>{...state.completedTips, tips};
    emit(
      state.copyWith(
        completedTips: updatedCompletedTips,
      ),
    );
  }
}
