import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
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
        super(TabState.init());

  final PreferenceCubit _preferenceCubit;
  final Logger _logger;

  void init() {
    final List<StoryType> tabs = _preferenceCubit.state.tabs;

    _logger.i('updating tabs to $tabs');

    emit(state.copyWith(tabs: tabs));
  }

  void update(int a, int b) {
    final List<StoryType> updatedTabs = List<StoryType>.from(state.tabs)
      ..swap(a, b);
    emit(state.copyWith(tabs: updatedTabs));

    _preferenceCubit.update<int>(
      TabOrderPreference(),
      to: StoryType.convertToSettingsValue(updatedTabs),
    );
  }
}
