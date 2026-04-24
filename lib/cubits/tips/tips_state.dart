part of 'tips_cubit.dart';

enum Tips { shareScreen, itemScreen }

class TipsState extends Equatable {
  const TipsState({required this.completedTips});

  const TipsState.init() : completedTips = const <Tips>{};

  final Set<Tips> completedTips;

  bool isTipsCompleted(Tips tips) => completedTips.contains(tips);

  TipsState copyWith({Set<Tips>? completedTips}) {
    return TipsState(completedTips: completedTips ?? this.completedTips);
  }

  @override
  List<Object?> get props => <Object?>[completedTips];
}
