import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/models/models.dart';

part 'split_view_state.dart';

class SplitViewCubit extends Cubit<SplitViewState> {
  SplitViewCubit() : super(const SplitViewState.init());

  void updateStory(Story story) {
    emit(state.copyWith(story: story));
  }

  void enableSplitView() => emit(state.copyWith(enabled: true));

  void disableSplitView() => emit(state.copyWith(enabled: false));
}
