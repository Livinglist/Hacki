import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';

part 'tab_state.dart';

class TabCubit extends Cubit<TabState> with Loggable {
  TabCubit({
    required PreferenceCubit preferenceCubit,
  })  : _preferenceCubit = preferenceCubit,
        super(TabState.init()) {
    init();
  }

  final PreferenceCubit _preferenceCubit;

  void init() {
    final List<StoryType> tabs = _preferenceCubit.state.tabs;

    logInfo('updating tabs to $tabs');

    emit(state.copyWith(tabs: tabs));
  }

  void update(int startIndex, int endIndex) {
    logDebug(
      'updating ${state.tabs} by moving $startIndex to $endIndex',
    );
    final StoryType tab = state.tabs.elementAt(startIndex);
    final List<StoryType> updatedTabs = List<StoryType>.from(state.tabs)
      ..insert(endIndex, tab)
      ..removeAt(startIndex < endIndex ? startIndex : startIndex + 1);
    logDebug(updatedTabs);
    emit(state.copyWith(tabs: updatedTabs));

    // Check to make sure there's no duplicate.
    if (updatedTabs.toSet().length == StoryType.values.length) {
      _preferenceCubit.update<int>(
        TabOrderPreference(val: StoryType.convertToSettingsValue(updatedTabs)),
      );
    }
  }

  @override
  String get logIdentifier => '[TabCubit]';
}
