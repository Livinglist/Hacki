part of 'reminder_cubit.dart';

class ReminderState extends Equatable {
  const ReminderState({
    required this.storyId,
    required this.hasShown,
  });

  const ReminderState.init()
      : storyId = null,
        hasShown = false;

  final int? storyId;
  final bool hasShown;

  ReminderState copyWith({
    int? storyId,
    bool? hasShown,
  }) {
    return ReminderState(
      storyId: storyId ?? this.storyId,
      hasShown: hasShown ?? this.hasShown,
    );
  }

  @override
  List<Object?> get props => <Object?>[storyId, hasShown];
}
