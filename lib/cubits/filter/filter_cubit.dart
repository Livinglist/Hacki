import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/repositories/repositories.dart';

part 'filter_state.dart';

class FilterCubit extends Cubit<FilterState> {
  FilterCubit({PreferenceRepository? preferenceRepository})
      : _preferenceRepository =
            preferenceRepository ?? locator.get<PreferenceRepository>(),
        super(FilterState.init()) {
    init();
  }

  final PreferenceRepository _preferenceRepository;

  void init() {
    _preferenceRepository.filterKeywords.then(
      (List<String> keywords) => emit(
        state.copyWith(
          keywords: keywords.toSet(),
        ),
      ),
    );
  }

  void addKeyword(String keyword) {
    final Set<String> updated = Set<String>.from(state.keywords)..add(keyword);
    emit(state.copyWith(keywords: updated));
    _preferenceRepository.updateFilterKeywords(updated.toList(growable: false));
  }

  void removeKeyword(String keyword) {
    final Set<String> updated = Set<String>.from(state.keywords)
      ..remove(keyword);
    emit(state.copyWith(keywords: updated));
    _preferenceRepository.updateFilterKeywords(updated.toList(growable: false));
  }
}
