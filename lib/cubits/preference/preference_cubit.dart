import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/repositories/repositories.dart';

part 'preference_state.dart';

class PreferenceCubit extends Cubit<PreferenceState> {
  PreferenceCubit({PreferenceRepository? storageRepository})
      : _preferenceRepository =
            storageRepository ?? locator.get<PreferenceRepository>(),
        super(const PreferenceState.init()) {
    init();
  }

  final PreferenceRepository _preferenceRepository;

  void init() {
    _preferenceRepository.shouldShowNotification
        .then((bool value) => emit(state.copyWith(showNotification: value)));
    _preferenceRepository.shouldShowComplexStoryTile.then(
      (bool value) => emit(state.copyWith(showComplexStoryTile: value)),
    );
    _preferenceRepository.shouldShowWebFirst
        .then((bool value) => emit(state.copyWith(showWebFirst: value)));
    _preferenceRepository.shouldShowEyeCandy
        .then((bool value) => emit(state.copyWith(showEyeCandy: value)));
    _preferenceRepository.trueDarkMode
        .then((bool value) => emit(state.copyWith(useTrueDark: value)));
    _preferenceRepository.readerMode
        .then((bool value) => emit(state.copyWith(useReader: value)));
    _preferenceRepository.markReadStories
        .then((bool value) => emit(state.copyWith(markReadStories: value)));
  }

  void toggleNotificationMode() {
    emit(state.copyWith(showNotification: !state.showNotification));
    _preferenceRepository.toggleNotificationMode();
  }

  void toggleDisplayMode() {
    emit(state.copyWith(showComplexStoryTile: !state.showComplexStoryTile));
    _preferenceRepository.toggleDisplayMode();
  }

  void toggleNavigationMode() {
    emit(state.copyWith(showWebFirst: !state.showWebFirst));
    _preferenceRepository.toggleNavigationMode();
  }

  void toggleEyeCandyMode() {
    emit(state.copyWith(showEyeCandy: !state.showEyeCandy));
    _preferenceRepository.toggleEyeCandyMode();
  }

  void toggleTrueDarkMode() {
    emit(state.copyWith(useTrueDark: !state.useTrueDark));
    _preferenceRepository.toggleTrueDarkMode();
  }

  void toggleReaderMode() {
    emit(state.copyWith(useReader: !state.useReader));
    _preferenceRepository.toggleReaderMode();
  }

  void toggleMarkReadStoriesMode() {
    emit(state.copyWith(markReadStories: !state.markReadStories));
    _preferenceRepository.toggleMarkReadStoriesMode();
  }
}
