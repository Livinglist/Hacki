import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/utils/haptic_feedback_utils.dart';

part 'vote_state.dart';

class VoteCubit extends Cubit<VoteState> {
  VoteCubit({
    required Item item,
    required AuthBloc authBloc,
    bool shouldInitialize = true,
    AuthRepository? authRepository,
    PreferenceRepository? preferenceRepository,
  })  : _authBloc = authBloc,
        _authRepository = authRepository ?? locator.get<AuthRepository>(),
        _preferenceRepository =
            preferenceRepository ?? locator.get<PreferenceRepository>(),
        super(VoteState.init(item: item)) {
    if (shouldInitialize) {
      unawaited(init());
    }
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

  Future<bool> upvote({bool cancelIfVoted = true}) async {
    if (!_authBloc.state.isLoggedIn) {
      HapticFeedbackUtils.error();
      emit(state.copyWith(status: VoteStatus.failureNotLoggedIn));
      return false;
    }

    if (state.item.by == _authBloc.state.username) {
      HapticFeedbackUtils.error();
      emit(state.copyWith(status: VoteStatus.failureBeHumble));
      return false;
    }

    if (state.item.dead || state.item.deleted || state.item.by.isEmpty) {
      HapticFeedbackUtils.error();
      emit(state.copyWith(status: VoteStatus.failure));
      return false;
    }

    if (state.vote == null || state.vote == Vote.down) {
      final bool success = await _authRepository.upvote(
        id: state.item.id,
        upvote: true,
      );

      if (success) {
        HapticFeedbackUtils.success();
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

        return true;
      } else {
        HapticFeedbackUtils.error();

        emit(
          state.copyWith(
            status: VoteStatus.failure,
          ),
        );

        return false;
      }
    } else if (cancelIfVoted) {
      await _authRepository.upvote(id: state.item.id, upvote: false);
      await _preferenceRepository.removeVote(
        username: _authBloc.state.username,
        id: state.item.id,
      );

      HapticFeedbackUtils.success();
      emit(
        state.copyWithVoteRemoved(
          status: VoteStatus.canceled,
        ),
      );

      return true;
    }

    return true;
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

          HapticFeedbackUtils.success();
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

        HapticFeedbackUtils.success();
        emit(
          state.copyWithVoteRemoved(
            status: VoteStatus.canceled,
          ),
        );
      }
    } else {
      HapticFeedbackUtils.error();
      emit(state.copyWith(status: VoteStatus.failureKarmaBelowThreshold));
    }
  }
}
