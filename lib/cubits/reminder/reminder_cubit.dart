import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/repositories/repositories.dart';

part 'reminder_state.dart';

class ReminderCubit extends Cubit<ReminderState> {
  ReminderCubit({PreferenceRepository? preferenceRepository})
      : _preferenceRepository =
            preferenceRepository ?? locator.get<PreferenceRepository>(),
        super(const ReminderState.init());

  final PreferenceRepository _preferenceRepository;

  void init() {
    _preferenceRepository.lastReadStoryId.then((value) {
      emit(state.copyWith(storyId: value));
    });
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
