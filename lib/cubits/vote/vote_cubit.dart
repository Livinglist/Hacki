import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';

part 'vote_state.dart';

class VoteCubit extends Cubit<VoteState> {
  VoteCubit({
    required Item item,
    required AuthBloc authBloc,
    AuthRepository? authRepository,
    PreferenceRepository? preferenceRepository,
  })  : _authBloc = authBloc,
        _authRepository = authRepository ?? locator.get<AuthRepository>(),
        _preferenceRepository =
            preferenceRepository ?? locator.get<PreferenceRepository>(),
        super(VoteState.init(item: item)) {
    init();
  }

  final AuthBloc _authBloc;
  final AuthRepository _authRepository;
  final PreferenceRepository _preferenceRepository;
  static const int _karmaThreshold = 501;

  Future<void> init() async {
    final bool? vote = await _preferenceRepository.vote(
      submittedTo: state.item.id,
      from: _authBloc.state.username,
    );

    final Vote? parsedVote = vote == null
        ? null
        : vote
            ? Vote.up
            : Vote.down;

    emit(
      state.copyWith(
        vote: parsedVote,
      ),
    );
  }

  Future<void> upvote() async {
    if (!_authBloc.state.isLoggedIn) {
      emit(state.copyWith(status: VoteStatus.failureNotLoggedIn));
      return;
    }

    if (state.item.by == _authBloc.state.username) {
      emit(state.copyWith(status: VoteStatus.failureBeHumble));
      return;
    }

    if (state.vote == null || state.vote == Vote.down) {
      final bool success = await _authRepository.upvote(
        id: state.item.id,
        upvote: true,
      );

      if (success) {
        emit(
          state.copyWith(
            vote: Vote.up,
            status: VoteStatus.submitted,
          ),
        );

        unawaited(
          _preferenceRepository.addVote(
            username: _authBloc.state.username,
            id: state.item.id,
            vote: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: VoteStatus.failure,
          ),
        );
      }
    } else {
      await _authRepository.upvote(id: state.item.id, upvote: false);
      await _preferenceRepository.removeVote(
        username: _authBloc.state.username,
        id: state.item.id,
      );

      emit(
        state.copyWithVoteRemoved(
          status: VoteStatus.canceled,
        ),
      );
    }
  }

  Future<void> downvote() async {
    if (!_authBloc.state.isLoggedIn) {
      emit(state.copyWith(status: VoteStatus.failureNotLoggedIn));
      return;
    }

    if (state.item.by == _authBloc.state.username) {
      emit(state.copyWith(status: VoteStatus.failureBeHumble));
      return;
    }

    if (_authBloc.state.user.karma >= _karmaThreshold) {
      if (state.vote == null || state.vote == Vote.up) {
        final bool success =
            await _authRepository.downvote(id: state.item.id, downvote: true);

        if (success) {
          await _preferenceRepository.addVote(
            username: _authBloc.state.username,
            id: state.item.id,
            vote: false,
          );

          emit(
            state.copyWith(
              vote: Vote.down,
              status: VoteStatus.submitted,
            ),
          );
        }
      } else {
        await _authRepository.downvote(id: state.item.id, downvote: false);
        await _preferenceRepository.removeVote(
          username: _authBloc.state.username,
          id: state.item.id,
        );

        emit(
          state.copyWithVoteRemoved(
            status: VoteStatus.canceled,
          ),
        );
      }
    } else {
      emit(state.copyWith(status: VoteStatus.failureKarmaBelowThreshold));
    }
  }
}
