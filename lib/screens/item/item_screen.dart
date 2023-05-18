import 'package:equatable/equatable.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/screens/item/widgets/widgets.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ItemScreenArgs extends Equatable {
  const ItemScreenArgs({
    required this.item,
    this.onlyShowTargetComment = false,
    this.useCommentCache = false,
    this.targetComments,
  });

  final Item item;
  final bool onlyShowTargetComment;
  final List<Comment>? targetComments;

  /// when a user is trying to view a sub-thread from a main thread, we don't
  /// need to fetch comments from [StoriesRepository] since we have some, if not
  /// all, comments cached in [CommentCache].
  final bool useCommentCache;

  @override
  List<Object?> get props => <Object?>[
        item,
        onlyShowTargetComment,
        targetComments,
        useCommentCache,
      ];
}

class ItemScreen extends StatefulWidget {
  const ItemScreen({
    required this.item,
    required this.parentComments,
    super.key,
    this.splitViewEnabled = false,
  });

  static const String routeName = '/item';

  static Route<dynamic> route(ItemScreenArgs args) {
    return MaterialPageRoute<ItemScreen>(
      settings: const RouteSettings(name: routeName),
      builder: (BuildContext context) => RepositoryProvider<CollapseCache>(
        create: (_) => CollapseCache(),
        lazy: false,
        child: MultiBlocProvider(
          providers: <BlocProvider<dynamic>>[
            BlocProvider<CommentsCubit>(
              create: (BuildContext context) => CommentsCubit(
                filterCubit: context.read<FilterCubit>(),
                isOfflineReading:
                    context.read<StoriesBloc>().state.isOfflineReading,
                item: args.item,
                collapseCache: context.read<CollapseCache>(),
                defaultFetchMode:
                    context.read<PreferenceCubit>().state.fetchMode,
                defaultCommentsOrder:
                    context.read<PreferenceCubit>().state.order,
              )..init(
                  onlyShowTargetComment: args.onlyShowTargetComment,
                  targetAncestors: args.targetComments,
                  useCommentCache: args.useCommentCache,
                ),
            ),
          ],
          child: ItemScreen(
            item: args.item,
            parentComments: args.targetComments ?? <Comment>[],
          ),
        ),
      ),
    );
  }

  static Widget build(BuildContext context, ItemScreenArgs args) {
    return WillPopScope(
      onWillPop: () async {
        if (context.read<SplitViewCubit>().state.expanded) {
          context.read<SplitViewCubit>().zoom();
          return false;
        } else {
          return true;
        }
      },
      child: RepositoryProvider<CollapseCache>(
        create: (_) => CollapseCache(),
        lazy: false,
        child: MultiBlocProvider(
          key: ValueKey<ItemScreenArgs>(args),
          providers: <BlocProvider<dynamic>>[
            BlocProvider<CommentsCubit>(
              create: (BuildContext context) => CommentsCubit(
                filterCubit: context.read<FilterCubit>(),
                isOfflineReading:
                    context.read<StoriesBloc>().state.isOfflineReading,
                item: args.item,
                collapseCache: context.read<CollapseCache>(),
                defaultFetchMode:
                    context.read<PreferenceCubit>().state.fetchMode,
                defaultCommentsOrder:
                    context.read<PreferenceCubit>().state.order,
              )..init(
                  onlyShowTargetComment: args.onlyShowTargetComment,
                  targetAncestors: args.targetComments,
                ),
            ),
          ],
          child: ItemScreen(
            item: args.item,
            parentComments: args.targetComments ?? <Comment>[],
            splitViewEnabled: true,
          ),
        ),
      ),
    );
  }

  final bool splitViewEnabled;
  final Item item;
  final List<Comment> parentComments;

  @override
  _ItemScreenState createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> with RouteAware {
  final TextEditingController commentEditingController =
      TextEditingController();
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  final Throttle storyLinkTapThrottle = Throttle(
    delay: _storyLinkTapThrottleDelay,
  );
  final Throttle featureDiscoveryDismissThrottle = Throttle(
    delay: _featureDiscoveryDismissThrottleDelay,
  );
  final GlobalKey fontSizeIconButtonKey = GlobalKey();

  static const Duration _storyLinkTapThrottleDelay = Duration(seconds: 2);
  static const Duration _featureDiscoveryDismissThrottleDelay =
      Duration(seconds: 1);

  @override
  void didPop() {
    super.didPop();
    if (context.read<EditCubit>().state.text.isNullOrEmpty) {
      context.read<EditCubit>().onReplyBoxClosed();
    }
  }

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        FeatureDiscovery.discoverFeatures(
          context,
          <String>{
            Constants.featurePinToTop,
            Constants.featureAddStoryToFavList,
            Constants.featureOpenStoryInWebView,
            Constants.featureJumpUpButton,
            Constants.featureJumpDownButton,
          },
        );
      })
      ..addPostFrameCallback((_) {
        final ModalRoute<dynamic>? route = ModalRoute.of(context);

        if (route == null) return;

        locator
            .get<RouteObserver<ModalRoute<dynamic>>>()
            .subscribe(this, route);
      });

    commentEditingController.text = context.read<EditCubit>().state.text ?? '';
  }

  @override
  void dispose() {
    commentEditingController.dispose();
    storyLinkTapThrottle.dispose();
    featureDiscoveryDismissThrottle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (BuildContext context, AuthState authState) {
        return MultiBlocListener(
          listeners: <BlocListener<dynamic, dynamic>>[
            BlocListener<PostCubit, PostState>(
              listener: (BuildContext context, PostState postState) {
                if (postState.status == PostStatus.successful) {
                  Navigator.popUntil(
                    context,
                    (Route<dynamic> route) =>
                        route.settings.name == ItemScreen.routeName,
                  );
                  final String verb =
                      context.read<EditCubit>().state.replyingTo == null
                          ? 'updated'
                          : 'submitted';
                  final String msg = 'Comment $verb! ${Constants.happyFace}';
                  HapticFeedbackUtil.light();
                  showSnackBar(content: msg);
                  context.read<EditCubit>().onReplySubmittedSuccessfully();
                  context.read<PostCubit>().reset();
                } else if (postState.status == PostStatus.failure) {
                  Navigator.popUntil(
                    context,
                    (Route<dynamic> route) =>
                        route.settings.name == ItemScreen.routeName,
                  );
                  showErrorSnackBar();
                  context.read<PostCubit>().reset();
                }
              },
            ),
          ],
          child: BlocListener<EditCubit, EditState>(
            listenWhen: (EditState previous, EditState current) {
              return previous.replyingTo != current.replyingTo ||
                  previous.itemBeingEdited != current.itemBeingEdited ||
                  commentEditingController.text != current.text;
            },
            listener: (BuildContext context, EditState editState) {
              if (editState.replyingTo != null ||
                  editState.itemBeingEdited != null) {
                if (editState.text == null) {
                  commentEditingController.clear();
                } else {
                  final String text = editState.text!;
                  commentEditingController
                    ..text = text
                    ..selection = TextSelection.fromPosition(
                      TextPosition(offset: text.length),
                    );
                }
              } else {
                commentEditingController.clear();
              }
            },
            child: widget.splitViewEnabled
                ? Material(
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: MainView(
                            itemScrollController: itemScrollController,
                            itemPositionsListener: itemPositionsListener,
                            commentEditingController: commentEditingController,
                            authState: authState,
                            topPadding: topPadding,
                            splitViewEnabled: widget.splitViewEnabled,
                            onMoreTapped: onMoreTapped,
                            onRightMoreTapped: onRightMoreTapped,
                            onReplyTapped: showReplyBox,
                          ),
                        ),
                        BlocBuilder<SplitViewCubit, SplitViewState>(
                          buildWhen: (
                            SplitViewState previous,
                            SplitViewState current,
                          ) =>
                              previous.expanded != current.expanded,
                          builder: (
                            BuildContext context,
                            SplitViewState state,
                          ) {
                            return Positioned(
                              top: Dimens.zero,
                              left: Dimens.zero,
                              right: Dimens.zero,
                              child: CustomAppBar(
                                backgroundColor: Theme.of(context)
                                    .canvasColor
                                    .withOpacity(0.6),
                                item: widget.item,
                                splitViewEnabled: state.enabled,
                                expanded: state.expanded,
                                onZoomTap: context.read<SplitViewCubit>().zoom,
                                onFontSizeTap: onFontSizeTapped,
                                fontSizeIconButtonKey: fontSizeIconButtonKey,
                              ),
                            );
                          },
                        ),
                        Positioned(
                          right: Dimens.pt12,
                          bottom: Dimens.pt36,
                          child: CustomFloatingActionButton(
                            itemScrollController: itemScrollController,
                            itemPositionsListener: itemPositionsListener,
                          ),
                        ),
                      ],
                    ),
                  )
                : Scaffold(
                    extendBodyBehindAppBar: true,
                    resizeToAvoidBottomInset: true,
                    appBar: CustomAppBar(
                      backgroundColor:
                          Theme.of(context).canvasColor.withOpacity(0.6),
                      item: widget.item,
                      onFontSizeTap: onFontSizeTapped,
                      fontSizeIconButtonKey: fontSizeIconButtonKey,
                    ),
                    body: MainView(
                      itemScrollController: itemScrollController,
                      itemPositionsListener: itemPositionsListener,
                      commentEditingController: commentEditingController,
                      authState: authState,
                      topPadding: topPadding,
                      splitViewEnabled: widget.splitViewEnabled,
                      onMoreTapped: onMoreTapped,
                      onRightMoreTapped: onRightMoreTapped,
                      onReplyTapped: showReplyBox,
                    ),
                    floatingActionButton: CustomFloatingActionButton(
                      itemScrollController: itemScrollController,
                      itemPositionsListener: itemPositionsListener,
                    ),
                  ),
          ),
        );
      },
    );
  }

  void showReplyBox() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ReplyBox(
              textEditingController: commentEditingController,
              onSendTapped: onSendTapped,
              onCloseTapped: () {
                context.read<EditCubit>().onReplyBoxClosed();
                commentEditingController.clear();
              },
              onChanged: context.read<EditCubit>().onTextChanged,
            ),
            SizedBox(
              height: MediaQuery.of(context).viewInsets.bottom,
            )
          ],
        );
      },
    );
  }

  void onFontSizeTapped() {
    const Offset offset = Offset.zero;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final RenderBox? box =
        fontSizeIconButtonKey.currentContext?.findRenderObject() as RenderBox?;

    if (box == null) return;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(offset, ancestor: overlay),
        box.localToGlobal(
          box.size.bottomRight(Offset.zero) + offset,
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<FontSize>(
      context: context,
      position: position,
      items: <PopupMenuItem<FontSize>>[
        for (final FontSize fontSize in FontSize.values)
          PopupMenuItem<FontSize>(
            value: fontSize,
            child: Text(
              fontSize.description,
              style: TextStyle(
                fontSize: fontSize.fontSize,
                color:
                    context.read<PreferenceCubit>().state.fontSize == fontSize
                        ? Palette.deepOrange
                        : null,
              ),
            ),
            onTap: () {
              HapticFeedbackUtil.light();
              locator.get<AppReviewService>().requestReview();
              context.read<PreferenceCubit>().update(
                    FontSizePreference(),
                    to: fontSize.index,
                  );
            },
          ),
      ],
    );
  }

  void onRightMoreTapped(Comment comment) {
    HapticFeedbackUtil.light();
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: ColoredBox(
            color: Theme.of(context).canvasColor,
            child: Material(
              color: Palette.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.av_timer),
                    title: const Text('View ancestors'),
                    onTap: () {
                      Navigator.pop(context);
                      onTimeMachineActivated(comment);
                    },
                    enabled:
                        comment.level > 0 && !(comment.dead || comment.deleted),
                  ),
                  ListTile(
                    leading: const Icon(Icons.list),
                    title: const Text('View in separate thread'),
                    onTap: () {
                      locator.get<AppReviewService>().requestReview();

                      Navigator.pop(context);
                      goToItemScreen(
                        args: ItemScreenArgs(
                          item: comment,
                          useCommentCache: true,
                        ),
                        forceNewScreen: true,
                      );
                    },
                    enabled: !(comment.dead || comment.deleted),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void onTimeMachineActivated(Comment comment) {
    final Size size = MediaQuery.of(context).size;
    final DeviceScreenType deviceType = getDeviceType(size);
    final double widthFactor =
        deviceType != DeviceScreenType.mobile ? 0.6 : 0.9;
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return TimeMachineDialog(
          comment: comment,
          size: size,
          deviceType: deviceType,
          widthFactor: widthFactor,
        );
      },
    );
  }

  void onSendTapped() {
    final AuthBloc authBloc = context.read<AuthBloc>();
    final PostCubit postCubit = context.read<PostCubit>();
    final EditState editState = context.read<EditCubit>().state;
    final Item? replyingTo = editState.replyingTo;
    final Item? itemEdited = editState.itemBeingEdited;

    if (authBloc.state.isLoggedIn) {
      final String text = commentEditingController.text;
      if (text.isEmpty) {
        return;
      }

      if (itemEdited != null) {
        postCubit.edit(text: text, id: itemEdited.id);
      } else if (replyingTo != null) {
        postCubit.post(text: text, to: replyingTo.id);
      }
    } else {
      onLoginTapped();
    }
  }
}
