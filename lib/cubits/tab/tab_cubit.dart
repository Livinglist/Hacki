import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';

part 'tab_state.dart';

class TabCubit extends Cubit<TabState> {
  TabCubit({
    required PreferenceCubit preferenceCubit,
  })  : _preferenceCubit = preferenceCubit,
        super(TabState.init());

  final PreferenceCubit _preferenceCubit;

  void init() {
    final List<StoryType> tabs = _preferenceCubit.state.tabs;

    emit(state.copyWith(tabs: tabs));
  }

  void update(StoryType a, StoryType b) {
    final int indexA = a.index;
    final int indexB = b.index;
    final List<StoryType> updatedTabs = List<StoryType>.from(state.tabs!)
      ..swap(indexA, indexB);
    emit(state.copyWith(tabs: updatedTabs));

    // TODO(jiaqi): sync to pref settings.
  }
}
