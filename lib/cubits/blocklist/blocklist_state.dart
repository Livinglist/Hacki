part of 'blocklist_cubit.dart';

class BlocklistState extends Equatable {
  const BlocklistState({required this.blocklist});

  BlocklistState.init() : blocklist = [];

  final List<String> blocklist;

  BlocklistState copyWith({List<String>? blocklist}) {
    return BlocklistState(blocklist: blocklist ?? this.blocklist);
  }

  @override
  List<Object?> get props => [blocklist];
}
