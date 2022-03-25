import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/screens/screens.dart';

part 'split_view_state.dart';

class SplitViewCubit extends Cubit<SplitViewState> {
  SplitViewCubit() : super(const SplitViewState.init());

  void updateStoryScreenArgs(StoryScreenArgs args) {
    emit(state.copyWith(storyScreenArgs: args));
  }

  void enableSplitView() => emit(state.copyWith(enabled: true));

  void disableSplitView() => emit(state.copyWith(enabled: false));
}
