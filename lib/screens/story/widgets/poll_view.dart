import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:hacki/blocs/auth/auth_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';

class PollView extends StatelessWidget {
  const PollView({
    super.key,
    required this.story,
    required this.onLoginTapped,
  });

  final Story story;
  final VoidCallback onLoginTapped;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PollCubit, PollState>(
      builder: (BuildContext context, PollState state) {
        return Column(
          children: <Widget>[
            const SizedBox(
              height: 24,
            ),
            if (state.status == PollStatus.loading) ...<Widget>[
              const LinearProgressIndicator(),
              const SizedBox(
                height: 24,
              ),
            ] else ...<Widget>[
              Row(
                children: <Widget>[
                  const SizedBox(
                    width: 24,
                  ),
                  Text(
                    'Total votes: ${state.totalVotes}',
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 12,
              ),
            ],
            for (final PollOption option in state.pollOptions)
              FadeIn(
                child: BlocProvider<VoteCubit>(
                  create: (BuildContext context) => VoteCubit(
                    item: option,
                    authBloc: context.read<AuthBloc>(),
                  ),
                  child: BlocConsumer<VoteCubit, VoteState>(
                    listenWhen: (VoteState previous, VoteState current) {
                      return previous.status != current.status;
                    },
                    listener: (BuildContext context, VoteState voteState) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      if (voteState.status == VoteStatus.submitted) {
                        showSnackBar(
                          context,
                          content: 'Vote submitted successfully.',
                        );
                      } else if (voteState.status == VoteStatus.canceled) {
                        showSnackBar(context, content: 'Vote canceled.');
                      } else if (voteState.status == VoteStatus.failure) {
                        showSnackBar(
                          context,
                          content: 'Something went wrong...',
                        );
                      } else if (voteState.status ==
                          VoteStatus.failureKarmaBelowThreshold) {
                        showSnackBar(
                          context,
                          content: "You can't downvote because"
                              ' you are karmaly broke.',
                        );
                      } else if (voteState.status ==
                          VoteStatus.failureNotLoggedIn) {
                        showSnackBar(
                          context,
                          content: 'Not logged in, no voting! (;｀O´)o',
                          action: onLoginTapped,
                          label: 'Log in',
                        );
                      } else if (voteState.status ==
                          VoteStatus.failureBeHumble) {
                        showSnackBar(
                          context,
                          content: 'No voting on your own post! (;｀O´)o',
                        );
                      }
                    },
                    builder: (BuildContext context, VoteState voteState) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          left: 12,
                          right: 24,
                          bottom: 4,
                        ),
                        child: Row(
                          children: <Widget>[
                            IconButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                context.read<VoteCubit>().upvote();
                              },
                              icon: Icon(
                                Icons.arrow_drop_up,
                                color: voteState.vote == Vote.up
                                    ? Colors.orange
                                    : Colors.grey,
                                size: 36,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    option.text,
                                  ),
                                  Text(
                                    '${option.score} votes',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 4,
                                  ),
                                  LinearProgressIndicator(
                                    value: option.ratio,
                                    color: Colors.deepOrange,
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void showSnackBar(
    BuildContext context, {
    required String content,
    VoidCallback? action,
    String? label,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.deepOrange,
        content: Text(content),
        action: action != null && label != null
            ? SnackBarAction(
                label: label,
                onPressed: action,
                textColor: Theme.of(context).textTheme.bodyText1?.color,
              )
            : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
