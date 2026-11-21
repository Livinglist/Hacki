part of 'pin_cubit.dart';

class PinState extends Equatable {
  const PinState({
    required this.pinnedItemsIds,
    required this.pinnedItems,
    required this.status,
  });

  PinState.init()
    : pinnedItemsIds = <int>[],
      pinnedItems = <Item>[],
      status = Status.idle;

  final List<int> pinnedItemsIds;
  final List<Item> pinnedItems;
  final Status status;

  PinState copyWith({
    List<int>? pinnedItemsIds,
    List<Item>? pinnedItems,
    Status? status,
  }) {
    return PinState(
      pinnedItemsIds: pinnedItemsIds ?? this.pinnedItemsIds,
      pinnedItems: pinnedItems ?? this.pinnedItems,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => <Object?>[pinnedItemsIds, pinnedItems, status];
}
