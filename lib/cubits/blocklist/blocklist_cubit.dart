import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/repositories/repositories.dart';

part 'blocklist_state.dart';

class BlocklistCubit extends Cubit<BlocklistState> {
  BlocklistCubit({PreferenceRepository? storageRepository})
      : _preferenceRepository =
            storageRepository ?? locator.get<PreferenceRepository>(),
        super(BlocklistState.init()) {
    init();
  }

  final PreferenceRepository _preferenceRepository;

  void init() {
    _preferenceRepository.blocklist.then(
      (List<String> blocklist) => emit(state.copyWith(blocklist: blocklist)),
    );
  }

  void addToBlocklist(String username) {
    final List<String> updated = List<String>.from(state.blocklist)
      ..add(username);
    emit(state.copyWith(blocklist: updated));
    _preferenceRepository.updateBlocklist(updated);
  }

  void removeFromBlocklist(String username) {
    final List<String> updated = List<String>.from(state.blocklist)
      ..remove(username);
    emit(state.copyWith(blocklist: updated));
    _preferenceRepository.updateBlocklist(updated);
  }
}
