part of 'review_request_cubit.dart';

class ReviewRequestState extends Equatable {
  const ReviewRequestState({
    required this.launchCounter,
    required this.firstRecordedLaunchDate,
    required this.hasShown,
  });

  ReviewRequestState.init()
    : launchCounter = 0,
      firstRecordedLaunchDate = .now(),
      hasShown = false;

  final int launchCounter;
  final DateTime firstRecordedLaunchDate;
  final bool hasShown;

  ReviewRequestState copyWith({
    int? launchCounter,
    DateTime? firstRecordedLaunchDate,
    bool? hasShown,
  }) {
    return ReviewRequestState(
      launchCounter: launchCounter ?? this.launchCounter,
      firstRecordedLaunchDate:
          firstRecordedLaunchDate ?? this.firstRecordedLaunchDate,
      hasShown: hasShown ?? this.hasShown,
    );
  }

  @override
  List<Object?> get props => <Object?>[launchCounter, firstRecordedLaunchDate];
}
