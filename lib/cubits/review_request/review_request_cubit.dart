import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'review_request_state.dart';

class ReviewRequestCubit extends HydratedCubit<ReviewRequestState> {
  ReviewRequestCubit() : super(ReviewRequestState.init()) {
    _incrementLaunchCounter();
  }

  void _incrementLaunchCounter() =>
      emit(state.copyWith(launchCounter: state.launchCounter + 1));

  static const int _askWhen = 100;
  static const String _launchCounterKey = 'launchCounterKey';
  static const String _firstRecordedLaunchDateKey =
      'firstRecordedLaunchDateKey';

  bool get feelingLucky => _askWhen == state.launchCounter;

  void markAsShown() => emit(state.copyWith(hasShown: true));

  void reset() => emit(state.copyWith(launchCounter: _askWhen));

  @override
  ReviewRequestState? fromJson(Map<String, dynamic> json) {
    return state.copyWith(
      launchCounter: json[_launchCounterKey] as int? ?? 0,
      firstRecordedLaunchDate: DateTime.fromMillisecondsSinceEpoch(
        json[_firstRecordedLaunchDateKey] as int? ??
            DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Map<String, dynamic>? toJson(ReviewRequestState state) {
    return <String, dynamic>{
      _launchCounterKey: state.launchCounter,
      _firstRecordedLaunchDateKey:
          state.firstRecordedLaunchDate.millisecondsSinceEpoch,
    };
  }
}
