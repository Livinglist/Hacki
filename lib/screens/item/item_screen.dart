// ignore_for_file: comment_references

import 'package:equatable/equatable.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/main.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/item/widgets/widgets.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_builder/responsive_builder.dart';

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
  /// need to fetch comments from [StoryRepository] since we have some, if not
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
    super.key,
    this.splitViewEnabled = false,
    required this.item,
    required this.parentComments,
  });

  static const String routeName = '/item';

  static Route<dynamic> route(ItemScreenArgs args) {
    return MaterialPageRoute<ItemScreen>(
      settings: const RouteSettings(name: routeName),
      builder: (BuildContext context) => RepositoryProvider<CollapseCache>(
        create: (BuildContext context) => CollapseCache(),
        lazy: false,
        child: MultiBlocProvider(
          providers: <BlocProvider<dynamic>>[
            BlocProvider<CommentsCubit>(
              create: (BuildContext context) => CommentsCubit(
                offlineReading:
                    context.read<StoriesBloc>().state.offlineReading,
                item: args.item,
                collapseCache: context.read<CollapseCache>(),
                defaultFetchMode:
                    context.read<PreferenceCubit>().state.fetchMode,
                defaultCommentsOrder:
                    context.read<PreferenceCubit>().state.order,
              )..init(
                  onlyShowTargetComment: args.onlyShowTargetComment,
                  targetParents: args.targetComments,
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
        create: (BuildContext context) => CollapseCache(),
        lazy: false,
        child: MultiBlocProvider(
          key: ValueKey<ItemScreenArgs>(args),
          providers: <BlocProvider<dynamic>>[
            BlocProvider<CommentsCubit>(
              create: (BuildContext context) => CommentsCubit(
                offlineReading:
                    context.read<StoriesBloc>().state.offlineReading,
                item: args.item,
                collapseCache: context.read<CollapseCache>(),
                defaultFetchMode:
                    context.read<PreferenceCubit>().state.fetchMode,
                defaultCommentsOrder:
                    context.read<PreferenceCubit>().state.order,
              )..init(
                  onlyShowTargetComment: args.onlyShowTargetComment,
                  targetParents: args.targetComments,
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
  final ScrollController scrollController = ScrollController();
  final RefreshController refreshController = RefreshController(
    initialLoadStatus: LoadStatus.idle,
    initialRefreshStatus: RefreshStatus.refreshing,
  );
  final FocusNode focusNode = FocusNode();
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
        if (!isTesting) {
          FeatureDiscovery.discoverFeatures(
            context,
            const <String>{
              Constants.featurePinToTop,
              Constants.featureAddStoryToFavList,
              Constants.featureOpenStoryInWebView,
            },
          );
        }
      })
      ..addPostFrameCallback((_) {
        final ModalRoute<dynamic>? route = ModalRoute.of(context);

        if (route == null) return;

        locator
            .get<RouteObserver<ModalRoute<dynamic>>>()
            .subscribe(this, route);
      });

    scrollController.addListener(() {
      FocusScope.of(context).requestFocus(FocusNode());
      if (commentEditingController.text.isEmpty) {
        context.read<EditCubit>().onScrolled();
      }
    });

    commentEditingController.text = context.read<EditCubit>().state.text ?? '';
  }

  @override
  void dispose() {
    refreshController.dispose();
    commentEditingController.dispose();
    scrollController.dispose();
    storyLinkTapThrottle.dispose();
    featureDiscoveryDismissThrottle.dispose();
    focusNode.dispose();
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
                  final String verb =
                      context.read<EditCubit>().state.replyingTo == null
                          ? 'updated'
                          : 'submitted';
                  final String msg = 'Comment $verb! ${Constants.happyFace}';
                  focusNode.unfocus();
                  HapticFeedback.lightImpact();
                  showSnackBar(content: msg);
                  context.read<EditCubit>().onReplySubmittedSuccessfully();
                  context.read<PostCubit>().reset();
                } else if (postState.status == PostStatus.failure) {
                  showSnackBar(
                    content: 'Something went wrong...'
                        '${Constants.sadFace}',
                    label: 'Okay',
                    action: ScaffoldMessenger.of(context).hideCurrentSnackBar,
                  );
                  context.read<PostCubit>().reset();
                }
              },
            ),
          ],
          child: BlocListener<CommentsCubit, CommentsState>(
            listenWhen: (CommentsState previous, CommentsState current) =>
                previous.status != current.status,
            listener: (BuildContext context, CommentsState state) {
              if (state.status != CommentsStatus.loading) {
                refreshController
                  ..refreshCompleted()
                  ..loadComplete();
              }
            },
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
                              scrollController: scrollController,
                              refreshController: refreshController,
                              commentEditingController:
                                  commentEditingController,
                              authState: authState,
                              focusNode: focusNode,
                              topPadding: topPadding,
                              splitViewEnabled: widget.splitViewEnabled,
                              onMoreTapped: onMoreTapped,
                              onStoryLinkTapped: onStoryLinkTapped,
                              onLoginTapped: onLoginTapped,
                              onRightMoreTapped: onRightMoreTapped,
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
                                  scrollController: scrollController,
                                  onBackgroundTap: onFeatureDiscoveryDismissed,
                                  onDismiss: onFeatureDiscoveryDismissed,
                                  splitViewEnabled: state.enabled,
                                  expanded: state.expanded,
                                  onZoomTap:
                                      context.read<SplitViewCubit>().zoom,
                                  onFontSizeTap: onFontSizeTapped,
                                  fontSizeIconButtonKey: fontSizeIconButtonKey,
                                ),
                              );
                            },
                          ),
                          Positioned(
                            bottom: Dimens.zero,
                            left: Dimens.zero,
                            right: Dimens.zero,
                            child: ReplyBox(
                              splitViewEnabled: true,
                              focusNode: focusNode,
                              textEditingController: commentEditingController,
                              onSendTapped: onSendTapped,
                              onCloseTapped: () {
                                context.read<EditCubit>().onReplyBoxClosed();
                                commentEditingController.clear();
                                focusNode.unfocus();
                              },
                              onChanged:
                                  context.read<EditCubit>().onTextChanged,
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
                        scrollController: scrollController,
                        onBackgroundTap: onFeatureDiscoveryDismissed,
                        onDismiss: onFeatureDiscoveryDismissed,
                        onFontSizeTap: onFontSizeTapped,
                        fontSizeIconButtonKey: fontSizeIconButtonKey,
                      ),
                      body: MainView(
                        scrollController: scrollController,
                        refreshController: refreshController,
                        commentEditingController: commentEditingController,
                        authState: authState,
                        focusNode: focusNode,
                        topPadding: topPadding,
                        splitViewEnabled: widget.splitViewEnabled,
                        onMoreTapped: onMoreTapped,
                        onStoryLinkTapped: onStoryLinkTapped,
                        onLoginTapped: onLoginTapped,
                        onRightMoreTapped: onRightMoreTapped,
                      ),
                      bottomSheet: ReplyBox(
                        focusNode: focusNode,
                        textEditingController: commentEditingController,
                        onSendTapped: onSendTapped,
                        onCloseTapped: () {
                          context.read<EditCubit>().onReplyBoxClosed();
                          commentEditingController.clear();
                          focusNode.unfocus();
                        },
                        onChanged: context.read<EditCubit>().onTextChanged,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> onFeatureDiscoveryDismissed() {
    featureDiscoveryDismissThrottle.run(() {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).clearSnackBars();
      showSnackBar(content: 'Tap on icon to continue');
    });
    return Future<bool>.value(false);
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
              HapticFeedback.lightImpact();
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
    const double bottomSheetHeight = 140;

    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: bottomSheetHeight,
          color: Theme.of(context).canvasColor,
          child: Material(
            color: Palette.transparent,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.av_timer),
                  title: const Text('View parents'),
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
          onStoryLinkTapped: onStoryLinkTapped,
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
