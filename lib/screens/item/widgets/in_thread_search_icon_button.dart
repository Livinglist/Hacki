import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/cubits/comments/comments_cubit.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';

class InThreadSearchIconButton extends StatelessWidget {
  const InThreadSearchIconButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CommentsCubit>.value(
      value: context.read<CommentsCubit>(),
      child: IconButton(
        tooltip: 'Search in thread',
        icon: const CustomDescribedFeatureOverlay(
          tapTarget: Icon(
            Icons.search,
            color: Palette.white,
          ),
          feature: DiscoverableFeature.searchInThread,
          child: Icon(
            Icons.search,
          ),
        ),
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            backgroundColor: Theme.of(context).canvasColor,
            builder: (BuildContext _) {
              return BlocProvider<CommentsCubit>.value(
                value: context.read<CommentsCubit>(),
                child: BlocBuilder<CommentsCubit, CommentsState>(
                  buildWhen: (CommentsState previous, CommentsState current) =>
                      previous.matchedComments != current.matchedComments,
                  builder: (BuildContext context, CommentsState state) {
                    return Container(
                      height: MediaQuery.of(context).size.height - Dimens.pt120,
                      color: Theme.of(context).canvasColor,
                      child: Material(
                        child: Column(
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Dimens.pt8,
                              ),
                              child: TextField(
                                cursorColor: Theme.of(context).primaryColor,
                                autocorrect: false,
                                decoration: InputDecoration(
                                  hintText: 'Search in this thread',
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                                onChanged: context.read<CommentsCubit>().search,
                              ),
                            ),
                            Expanded(
                              child: ListView(
                                children: <Widget>[
                                  for (final int i in state.matchedComments)
                                    CommentTile(
                                      comment: state.comments.elementAt(i),
                                      fetchMode: FetchMode.lazy,
                                      actionable: false,
                                      onTap: () {
                                        context.pop();
                                        context.read<CommentsCubit>().scrollTo(
                                              index: i + 1,
                                              alignment: 0.1,
                                            );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
