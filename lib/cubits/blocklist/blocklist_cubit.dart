import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/repositories/repositories.dart';

part 'blocklist_state.dart';

class BlocklistCubit extends Cubit<BlocklistState> {
  BlocklistCubit({StorageRepository? storageRepository})
      : _storageRepository =
            storageRepository ?? locator.get<StorageRepository>(),
        super(BlocklistState.init()) {
    init();
  }

  final StorageRepository _storageRepository;

  void init() {
    _storageRepository.blocklist
        .then((blocklist) => emit(state.copyWith(blocklist: blocklist)));
  }

  void addToBlocklist(String username) {
    final updated = List<String>.from(state.blocklist)..add(username);
    emit(state.copyWith(blocklist: updated));
    _storageRepository.updateBlocklist(updated);
  }

  void removeFromBlocklist(String username) {
    final updated = List<String>.from(state.blocklist)..remove(username);
    emit(state.copyWith(blocklist: updated));
    _storageRepository.updateBlocklist(updated);
  }
}
