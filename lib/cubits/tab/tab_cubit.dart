import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:logger/logger.dart';

part 'tab_state.dart';

class TabCubit extends Cubit<TabState> {
  TabCubit({
    required PreferenceCubit preferenceCubit,
    Logger? logger,
  })  : _preferenceCubit = preferenceCubit,
        _logger = logger ?? locator.get<Logger>(),
        super(TabState.init()) {
    init();
  }

  final PreferenceCubit _preferenceCubit;
  final Logger _logger;
  static const String _logPrefix = '[TabCubit]';

  void init() {
    final List<StoryType> tabs = _preferenceCubit.state.tabs;

    _logger.i('$_logPrefix updating tabs to $tabs');

    emit(state.copyWith(tabs: tabs));
  }

  void update(int startIndex, int endIndex) {
    _logger.d(
      '$_logPrefix updating ${state.tabs} by moving $startIndex to $endIndex',
    );
    final StoryType tab = state.tabs.elementAt(startIndex);
    final List<StoryType> updatedTabs = List<StoryType>.from(state.tabs)
      ..insert(endIndex, tab)
      ..removeAt(startIndex < endIndex ? startIndex : startIndex + 1);
    _logger.d(updatedTabs);
    emit(state.copyWith(tabs: updatedTabs));

    // Check to make sure there's no duplicate.
    if (updatedTabs.toSet().length == StoryType.values.length) {
      _preferenceCubit.update<int>(
        TabOrderPreference(val: StoryType.convertToSettingsValue(updatedTabs)),
      );
    }
  }
}
