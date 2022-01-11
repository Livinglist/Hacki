import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/repositories/repositories.dart';

part 'preference_state.dart';

class PreferenceCubit extends Cubit<PreferenceState> {
  PreferenceCubit({StorageRepository? storageRepository})
      : _storageRepository =
            storageRepository ?? locator.get<StorageRepository>(),
        super(const PreferenceState.init()) {
    init();
  }

  final StorageRepository _storageRepository;

  void init() {
    _storageRepository.shouldShowComplexStoryTile
        .then((value) => emit(state.copyWith(showComplexStoryTile: value)));
    _storageRepository.shouldShowWebFirst
        .then((value) => emit(state.copyWith(showWebFirst: value)));
    _storageRepository.shouldShowEyeCandy
        .then((value) => emit(state.copyWith(showEyeCandy: value)));
  }

  void toggleDisplayMode() {
    emit(state.copyWith(showComplexStoryTile: !state.showComplexStoryTile));
    _storageRepository.toggleDisplayMode();
  }

  void toggleNavigationMode() {
    emit(state.copyWith(showWebFirst: !state.showWebFirst));
    _storageRepository.toggleNavigationMode();
  }

  void toggleEyeCandyMode() {
    emit(state.copyWith(showEyeCandy: !state.showEyeCandy));
    _storageRepository.toggleEyeCandyMode();
  }
}
