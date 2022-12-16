import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/comments/comments_cubit.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';

part 'preference_state.dart';

class PreferenceCubit extends Cubit<PreferenceState> {
  PreferenceCubit({PreferenceRepository? storageRepository})
      : _preferenceRepository =
            storageRepository ?? locator.get<PreferenceRepository>(),
        super(PreferenceState.init()) {
    init();
  }

  final PreferenceRepository _preferenceRepository;

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
  }

  Future<T?> initPreference<T>(Preference<T> preference) async {
    switch (T) {
      case int:
        final int? value = await _preferenceRepository.getInt(preference.key);
        return value as T?;
      case bool:
        final bool? value = await _preferenceRepository.getBool(preference.key);
        return value as T?;
      default:
        throw UnimplementedError();
    }
  }

  void toggle(BooleanPreference preference) {
    final BooleanPreference updatedPreference =
        preference.copyWith(val: !preference.val) as BooleanPreference;
    emit(state.copyWithPreference(updatedPreference));
    _preferenceRepository.setBool(preference.key, !preference.val);
  }

  void update<T>(Preference<T> preference, {required T to}) {
    final T value = to;
    final Preference<T> updatedPreference = preference.copyWith(val: value);

    emit(state.copyWithPreference(updatedPreference));

    switch (T) {
      case int:
        _preferenceRepository.setInt(preference.key, value as int);
        break;
      case bool:
        _preferenceRepository.setBool(preference.key, value as bool);
        break;
      default:
        throw UnimplementedError();
    }
  }

// void selectFetchMode(FetchMode? fetchMode) {
//   if (fetchMode == null || state.fetchMode == fetchMode) return;
//   HapticFeedback.lightImpact();
//   emit(state.copyWith(fetchMode: fetchMode));
//   _preferenceRepository.selectFetchMode(fetchMode);
// }
//
// void selectCommentsOrder(CommentsOrder? order) {
//   if (order == null || state.order == order) return;
//   HapticFeedback.lightImpact();
//   emit(state.copyWith(order: order));
//   _preferenceRepository.selectCommentsOrder(order);
// }
}
