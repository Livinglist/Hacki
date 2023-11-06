import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/auth/auth_bloc.dart';
import 'package:hacki/cubits/comments/comments_cubit.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';

class InThreadSearchIconButton extends StatelessWidget {
  const InThreadSearchIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      closedColor: Palette.transparent,
      openColor: Theme.of(context).canvasColor,
      closedShape: const CircleBorder(),
      closedElevation: 0,
      openElevation: 0,
      transitionType: ContainerTransitionType.fadeThrough,
      closedBuilder: (BuildContext context, void Function() action) {
        return CustomDescribedFeatureOverlay(
          tapTarget: const Icon(
            Icons.search,
            color: Palette.white,
          ),
          feature: DiscoverableFeature.searchInThread,
          child: IconButton(
            tooltip: 'Search in thread',
            icon: const Icon(Icons.search),
            onPressed: action,
          ),
        );
      },
      openBuilder: (_, void Function({Object? returnValue}) action) =>
          _InThreadSearchView(
        commentsCubit: context.read<CommentsCubit>(),
        action: action,
      ),
    );
  }
}

class _InThreadSearchView extends StatefulWidget {
  const _InThreadSearchView({
    required this.commentsCubit,
    required this.action,
  });

  final CommentsCubit commentsCubit;
  final void Function({Object? returnValue}) action;

  @override
  State<_InThreadSearchView> createState() => _InThreadSearchViewState();
}

class _InThreadSearchViewState extends State<_InThreadSearchView> {
  final ScrollController scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();
  final TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(onScroll);
    textEditingController.text = widget.commentsCubit.state.inThreadSearchQuery;
    if (textEditingController.text.isEmpty) {
      focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    scrollController
      ..removeListener(onScroll)
      ..dispose();
    focusNode.dispose();
    textEditingController.dispose();
    super.dispose();
  }

  void onScroll() => focusNode.unfocus();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CommentsCubit>.value(
      value: widget.commentsCubit,
      child: BlocBuilder<CommentsCubit, CommentsState>(
        buildWhen: (CommentsState previous, CommentsState current) =>
            previous.matchedComments != current.matchedComments ||
            previous.inThreadSearchAuthor != current.inThreadSearchAuthor,
        builder: (BuildContext context, CommentsState state) {
          final AuthState authState = context.read<AuthBloc>().state;
          return Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              backgroundColor: Theme.of(context).canvasColor,
              elevation: 0,
              leadingWidth: 0,
              leading: const SizedBox.shrink(),
              title: Padding(
                padding: const EdgeInsets.only(bottom: Dimens.pt8),
                child: Flex(
                  direction: Axis.horizontal,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        cursorColor: Theme.of(context).primaryColor,
                        autocorrect: false,
                        decoration: InputDecoration(
                          hintText: 'Search in this thread',
                          suffixText: '${state.matchedComments.length} results',
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        onChanged: (String text) => widget.commentsCubit.search(
                          text,
                          author: state.inThreadSearchAuthor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: widget.action,
                    ),
                  ],
                ),
              ),
            ),
            body: ListView(
              controller: scrollController,
              shrinkWrap: true,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const SizedBox(
                      width: Dimens.pt12,
                    ),
                    CustomChip(
                      selected: state.inThreadSearchAuthor == state.item.by,
                      label: 'by OP',
                      onSelected: (bool value) {
                        if (value) {
                          widget.commentsCubit.search(
                            state.inThreadSearchQuery,
                            author: state.item.by,
                          );
                        } else {
                          widget.commentsCubit.search(
                            state.inThreadSearchQuery,
                          );
                        }
                      },
                    ),
                    const SizedBox(
                      width: Dimens.pt12,
                    ),
                    if (authState.isLoggedIn)
                      CustomChip(
                        selected:
                            state.inThreadSearchAuthor == authState.username,
                        label: 'by me',
                        onSelected: (bool value) {
                          if (value) {
                            widget.commentsCubit.search(
                              state.inThreadSearchQuery,
                              author: authState.username,
                            );
                          } else {
                            widget.commentsCubit.search(
                              state.inThreadSearchQuery,
                            );
                          }
                        },
                      ),
                  ],
                ),
                for (final int i in state.matchedComments)
                  CommentTile(
                    index: i,
                    comment: state.comments.elementAt(i),
                    fetchMode: FetchMode.lazy,
                    actionable: false,
                    collapsable: false,
                    onTap: () {
                      widget.action();
                      widget.commentsCubit.scrollTo(
                        index: i + 1,
                        alignment: 0.2,
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
