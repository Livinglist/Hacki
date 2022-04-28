import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/repositories/repositories.dart';

part 'preference_state.dart';

class PreferenceCubit extends Cubit<PreferenceState> {
  PreferenceCubit({PreferenceRepository? storageRepository})
      : _storageRepository =
            storageRepository ?? locator.get<PreferenceRepository>(),
        super(const PreferenceState.init()) {
    init();
  }

  final PreferenceRepository _storageRepository;

  void init() {
    _storageRepository.shouldShowNotification
        .then((bool value) => emit(state.copyWith(showNotification: value)));
    _storageRepository.shouldShowComplexStoryTile.then(
      (bool value) => emit(state.copyWith(showComplexStoryTile: value)),
    );
    _storageRepository.shouldShowWebFirst
        .then((bool value) => emit(state.copyWith(showWebFirst: value)));
    _storageRepository.shouldShowEyeCandy
        .then((bool value) => emit(state.copyWith(showEyeCandy: value)));
    _storageRepository.trueDarkMode
        .then((bool value) => emit(state.copyWith(useTrueDark: value)));
    _storageRepository.readerMode
        .then((bool value) => emit(state.copyWith(useReader: value)));
    _storageRepository.markReadStories
        .then((bool value) => emit(state.copyWith(markReadStories: value)));
  }

  void toggleNotificationMode() {
    emit(state.copyWith(showNotification: !state.showNotification));
    _storageRepository.toggleNotificationMode();
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

  void toggleTrueDarkMode() {
    emit(state.copyWith(useTrueDark: !state.useTrueDark));
    _storageRepository.toggleTrueDarkMode();
  }

  void toggleReaderMode() {
    emit(state.copyWith(useReader: !state.useReader));
    _storageRepository.toggleReaderMode();
  }

  void toggleMarkReadStoriesMode() {
    emit(state.copyWith(markReadStories: !state.markReadStories));
    _storageRepository.toggleMarkReadStoriesMode();
  }
}
