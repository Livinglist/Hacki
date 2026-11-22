import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';

part 'pin_state.dart';

class PinCubit extends Cubit<PinState> {
  PinCubit({
    PreferenceRepository? preferenceRepository,
    HackerNewsRepository? hackerNewsRepository,
  }) : _preferenceRepository =
           preferenceRepository ?? locator.get<PreferenceRepository>(),
       _hackerNewsRepository =
           hackerNewsRepository ?? locator.get<HackerNewsRepository>(),
       super(PinState.init()) {
    init();
  }

  final PreferenceRepository _preferenceRepository;
  final HackerNewsRepository _hackerNewsRepository;

  void init() {
    emit(PinState.init());
    _preferenceRepository.pinnedItemsIds
        .then((List<int> ids) {
          emit(state.copyWith(pinnedItemsIds: ids));

          _hackerNewsRepository
              .fetchItemsStream(ids: ids)
              .listen(_onItemFetched);
        })
        .whenComplete(() => emit(state.copyWith(status: Status.success)));
  }

  void pinItem(Item item, {VoidCallback? onDone}) {
    if (!state.pinnedItemsIds.contains(item.id)) {
      emit(
        state.copyWith(
          pinnedItemsIds: <int>{item.id, ...state.pinnedItemsIds}.toList(),
          pinnedItems: <Item>{item, ...state.pinnedItems}.toList(),
        ),
      );
      _preferenceRepository.updatePinnedItemsIds(state.pinnedItemsIds);
      onDone?.call();
    }
  }

  void unpinItem(Item item, {VoidCallback? onDone}) {
    emit(
      state.copyWith(
        pinnedItemsIds: <int>[...state.pinnedItemsIds]..remove(item.id),
        pinnedItems: <Item>[...state.pinnedItems]
          ..removeWhere((Item pinned) => pinned.id == item.id),
      ),
    );
    _preferenceRepository.updatePinnedItemsIds(state.pinnedItemsIds);
    onDone?.call();
  }

  void removeAll() {
    emit(state.copyWith(pinnedItemsIds: <int>[], pinnedItems: <Item>[]));
    _preferenceRepository.updatePinnedItemsIds(<int>[]);
  }

  void refresh() {
    if (state.status.isLoading) return;
    init();
  }

  void _onItemFetched(Item item) {
    if (!state.pinnedItemsIds.contains(item.id)) return;
    final Map<int, Item> items = <int, Item>{
      for (final Item pinned in state.pinnedItems) pinned.id: pinned,
      item.id: item,
    };
    emit(
      state.copyWith(
        pinnedItems: <Item>[
          for (final int id in state.pinnedItemsIds)
            if (items.containsKey(id)) items[id]!,
        ],
      ),
    );
  }
}
