import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:logger/logger.dart';

part 'preference_state.dart';

class PreferenceCubit extends Cubit<PreferenceState> {
  PreferenceCubit({
    PreferenceRepository? preferenceRepository,
    Logger? logger,
  })  : _preferenceRepository =
            preferenceRepository ?? locator.get<PreferenceRepository>(),
        _logger = logger ?? locator.get<Logger>(),
        super(PreferenceState.init()) {
    init();
  }

  final PreferenceRepository _preferenceRepository;
  final Logger _logger;

  void init() {
    for (final BooleanPreference p
        in Preference.allPreferences.whereType<BooleanPreference>()) {
      initPreference<bool>(p).then<bool?>((bool? value) {
        final Preference<dynamic> updatedPreference = p.copyWith(val: value);
        emit(state.copyWithPreference(updatedPreference));
        return null;
      });
    }

    for (final IntPreference p
        in Preference.allPreferences.whereType<IntPreference>()) {
      initPreference<int>(p).then<int?>((int? value) {
        final Preference<dynamic> updatedPreference = p.copyWith(val: value);
        emit(state.copyWithPreference(updatedPreference));

        return null;
      });
    }

    for (final DoublePreference p
        in Preference.allPreferences.whereType<DoublePreference>()) {
      initPreference<double>(p).then<double?>((double? value) {
        final Preference<dynamic> updatedPreference = p.copyWith(val: value);
        emit(state.copyWithPreference(updatedPreference));

        return null;
      });
    }
  }

  Future<T?> initPreference<T>(Preference<T> preference) async {
    switch (T) {
      case int:
        final int? value = await _preferenceRepository.getInt(preference.key);
        return value as T?;
      case double:
        final double? value =
            await _preferenceRepository.getDouble(preference.key);
        return value as T?;
      case bool:
        final bool? value = await _preferenceRepository.getBool(preference.key);
        return value as T?;
      default:
        throw UnimplementedError();
    }
  }

  void update<T>(Preference<T> preference) {
    _logger.i('updating $preference to ${preference.val}');

    emit(state.copyWithPreference(preference));

    switch (T) {
      case int:
        _preferenceRepository.setInt(
          preference.key,
          preference.val as int,
        );
      case double:
        _preferenceRepository.setDouble(
          preference.key,
          preference.val as double,
        );
      case bool:
        _preferenceRepository.setBool(
          preference.key,
          preference.val as bool,
        );
      default:
        throw UnimplementedError();
    }
  }
}
