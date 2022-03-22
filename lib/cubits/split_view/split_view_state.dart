part of 'split_view_cubit.dart';

class SplitViewState extends Equatable {
  const SplitViewState({
    required this.story,
    required this.enabled,
  });

  const SplitViewState.init()
      : enabled = false,
        story = null;

  final bool enabled;
  final Story? story;

  SplitViewState copyWith({bool? enabled, Story? story}) {
    return SplitViewState(
      enabled: enabled ?? this.enabled,
      story: story ?? this.story,
    );
  }

  @override
  List<Object?> get props => [
        enabled,
        story,
      ];
}
