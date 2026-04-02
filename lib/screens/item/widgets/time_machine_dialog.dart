import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/comment_tile.dart';
import 'package:hacki/screens/widgets/story_tile.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/link_utils.dart';
import 'package:responsive_builder/responsive_builder.dart';

class TimeMachineDialog extends StatelessWidget {
  const TimeMachineDialog({
    required this.comment,
    required this.rootItem,
    required this.deviceType,
    super.key,
  });

  final Comment comment;
  final Item rootItem;
  final DeviceScreenType deviceType;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TimeMachineCubit>.value(
      value: TimeMachineCubit()..activateTimeMachine(comment),
      child: BlocBuilder<TimeMachineCubit, TimeMachineState>(
        builder: (BuildContext context, TimeMachineState state) {
          return Material(
            color: Palette.transparent,
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.circular(
                    Dimens.pt4,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  right: Dimens.pt4,
                ),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const SizedBox(
                          width: Dimens.pt8,
                        ),
                        Text(
                          'Ancestors:',
                          style: TextTheme.of(context).titleMedium,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: Dimens.pt24,
                          ),
                          onPressed: () => context.pop(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    Expanded(
                      child: ListView(
                        children: <Widget>[
                          switch (rootItem) {
                            Story() => StoryTile(
                                shouldShowWebPreview: false,
                                shouldShowPreviewImage: false,
                                shouldShowMetadata: true,
                                shouldShowFavicon: true,
                                shouldShowUrl: true,
                                isExpandedTileEnabled: false,
                                isImageLeftAligned: context
                                    .read<PreferenceCubit>()
                                    .state
                                    .isPreviewImageLeftAligned,
                                story: rootItem as Story,
                                onTap: () {
                                  final String url = rootItem.url.isNotEmpty
                                      ? rootItem.url
                                      : '''${Constants.hackerNewsItemLinkPrefix}${rootItem.id}''';
                                  LinkUtils.launch(
                                    url,
                                    context,
                                    shouldUseHackiForHnLink: false,
                                  );
                                },
                              ),
                            Comment() => CommentTile(
                                comment: rootItem as Comment,
                                isActionable: false,
                                isCollapsable: false,
                                fetchMode: FetchMode.eager,
                              ),
                            Item() => const SizedBox.shrink(),
                          },
                          for (final int i in 0.to(
                            state.ancestors.length,
                          )) ...<Widget>[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                for (final int _ in 0.to(i, inclusive: false))
                                  SizedBoxes.pt6,
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: Dimens.pt6,
                                    left: Dimens.pt6,
                                  ),
                                  child: Icon(
                                    Icons.subdirectory_arrow_right_rounded,
                                    size: TextDimens.pt18,
                                    color: i == state.ancestors.length
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                ),
                                Expanded(
                                  child: CommentTile(
                                    comment: i == state.ancestors.length
                                        ? comment
                                        : state.ancestors.elementAt(i),
                                    isActionable: false,
                                    isCollapsable: false,
                                    fetchMode: FetchMode.eager,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(
                              height: Dimens.zero,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
