import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/item/models/models.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';

class MorePopupMenu extends StatelessWidget {
  const MorePopupMenu({
    super.key,
    required this.item,
    required this.isBlocked,
    required this.onStoryLinkTapped,
    required this.onLoginTapped,
  });

  final Item item;
  final bool isBlocked;
  final ValueChanged<String> onStoryLinkTapped;
  final VoidCallback onLoginTapped;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VoteCubit>(
      create: (BuildContext context) => VoteCubit(
        item: item,
        authBloc: context.read<AuthBloc>(),
      ),
      child: BlocConsumer<VoteCubit, VoteState>(
        listenWhen: (VoteState previous, VoteState current) {
          return previous.status != current.status;
        },
        listener: (BuildContext context, VoteState voteState) {
          if (voteState.status == VoteStatus.submitted) {
            context.showSnackBar(content: 'Vote submitted successfully.');
          } else if (voteState.status == VoteStatus.canceled) {
            context.showSnackBar(content: 'Vote canceled.');
          } else if (voteState.status == VoteStatus.failure) {
            context.showErrorSnackBar();
          } else if (voteState.status ==
              VoteStatus.failureKarmaBelowThreshold) {
            context.showSnackBar(
              content: "You can't downvote because you are karmaly broke.",
            );
          } else if (voteState.status == VoteStatus.failureNotLoggedIn) {
            context.showSnackBar(
              content: 'Not logged in, no voting! (;｀O´)o',
              action: onLoginTapped,
              label: 'Log in',
            );
          } else if (voteState.status == VoteStatus.failureBeHumble) {
            context.showSnackBar(
              content: 'No voting on your own post! (;｀O´)o',
            );
          }

          Navigator.pop(
            context,
            MenuAction.upvote,
          );
        },
        builder: (BuildContext context, VoteState voteState) {
          final bool upvoted = voteState.vote == Vote.up;
          final bool downvoted = voteState.vote == Vote.down;
          return Container(
            height: item is Comment ? 430 : 450,
            color: Theme.of(context).canvasColor,
            child: Material(
              color: Palette.transparent,
              child: Column(
                children: <Widget>[
                  BlocProvider<UserCubit>(
                    create: (BuildContext context) =>
                        UserCubit()..init(userId: item.by),
                    child: BlocBuilder<UserCubit, UserState>(
                      builder: (BuildContext context, UserState state) {
                        return ListTile(
                          leading: const Icon(
                            Icons.account_circle,
                          ),
                          title: Text(item.by),
                          subtitle: Text(
                            state.user.description,
                          ),
                          onTap: () {
                            showDialog<void>(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                title: Text('About ${state.user.id}'),
                                content: state.user.about.isEmpty
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const <Widget>[
                                          Text(
                                            'empty',
                                            style: TextStyle(
                                              color: Palette.grey,
                                            ),
                                          ),
                                        ],
                                      )
                                    : SelectableLinkify(
                                        text: HtmlUtil.parseHtml(
                                          state.user.about,
                                        ),
                                        linkStyle: const TextStyle(
                                          color: Palette.orange,
                                        ),
                                        onOpen: (LinkableElement link) {
                                          if (link.url.isStoryLink) {
                                            onStoryLinkTapped.call(link.url);
                                          } else {
                                            LinkUtil.launch(link.url);
                                          }
                                        },
                                      ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      'Okay',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      FeatherIcons.chevronUp,
                      color: upvoted ? Palette.orange : null,
                    ),
                    title: Text(
                      upvoted ? 'Upvoted' : 'Upvote',
                      style: upvoted
                          ? const TextStyle(color: Palette.orange)
                          : null,
                    ),
                    subtitle:
                        item is Story ? Text(item.score.toString()) : null,
                    onTap: context.read<VoteCubit>().upvote,
                  ),
                  ListTile(
                    leading: Icon(
                      FeatherIcons.chevronDown,
                      color: downvoted ? Palette.orange : null,
                    ),
                    title: Text(
                      downvoted ? 'Downvoted' : 'Downvote',
                      style: downvoted
                          ? const TextStyle(color: Palette.orange)
                          : null,
                    ),
                    onTap: context.read<VoteCubit>().downvote,
                  ),
                  ListTile(
                    leading: const Icon(FeatherIcons.share),
                    title: const Text(
                      'Share',
                    ),
                    onTap: () => Navigator.pop(
                      context,
                      MenuAction.share,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.local_police),
                    title: const Text(
                      'Flag',
                    ),
                    onTap: () => Navigator.pop(
                      context,
                      MenuAction.flag,
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      isBlocked ? Icons.visibility : Icons.visibility_off,
                    ),
                    title: Text(
                      isBlocked ? 'Unblock' : 'Block',
                    ),
                    onTap: () => Navigator.pop(
                      context,
                      MenuAction.block,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.close),
                    title: const Text(
                      'Cancel',
                    ),
                    onTap: () => Navigator.pop(
                      context,
                      MenuAction.cancel,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
