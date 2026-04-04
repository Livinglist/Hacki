import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/screens/widgets/spring_curve.dart';
import 'package:hacki/styles/dimens.dart';
import 'package:hacki/styles/sized_boxes.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewBottomSheet extends StatefulWidget {
  const WebViewBottomSheet({
    required this.initialUrl,
    required this.onCloseTapped,
    required this.onDragHandleTapped,
    super.key,
  });

  final String initialUrl;
  final VoidCallback onCloseTapped;
  final VoidCallback onDragHandleTapped;

  @override
  State<WebViewBottomSheet> createState() => _WebViewBottomSheetState();
}

class _WebViewBottomSheetState extends State<WebViewBottomSheet>
    with SingleTickerProviderStateMixin {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final TextEditingController _urlController = TextEditingController();
  late final WebViewController _controller;
  late final AnimationController _animController;
  late final Animation<double> _rotationAnim;
  static const double _minChildSize = 0.1;
  static const double _maxChildSize = 0.9;
  bool _isLoading = true;
  bool _canGoBack = false;
  bool _canGoForward = false;
  double _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _loadingProgress = 0;
              _urlController.text = url;
            });
          },
          onProgress: (int progress) {
            setState(() => _loadingProgress = progress / 100.0);
          },
          onPageFinished: (String url) async {
            final bool canBack = await _controller.canGoBack();
            final bool canFwd = await _controller.canGoForward();
            setState(() {
              _isLoading = false;
              _loadingProgress = 1.0;
              _canGoBack = canBack;
              _canGoForward = canFwd;
              _urlController.text = url;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));

    _animController = AnimationController(
      duration: AppDurations.ms300,
      vsync: this,
    );
    _rotationAnim = Tween<double>(begin: 0, end: 0.5).animate(_animController);
    _sheetController.addListener(() {
      final double newSize = _sheetController.size;
      final double scrollPosition =
          ((newSize - _minChildSize) / (_maxChildSize - _minChildSize))
              .clamp(0.0, 1.0);

      _animController.animateTo(scrollPosition, duration: Duration.zero);
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _loadUrl(String url) {
    _controller.loadRequest(Uri.parse(widget.initialUrl));
  }

  void _refresh() => _controller.reload();

  @override
  Widget build(BuildContext context) {
    final bool isWebViewBottomSheetEnabled =
        context.select<PreferenceCubit, bool>(
      (PreferenceCubit cubit) => cubit.state.isWebViewBottomSheetEnabled,
    );
    if (!isWebViewBottomSheetEnabled) {
      return const SizedBox.shrink();
    }
    return DraggableScrollableSheet(
      controller: _sheetController,
      snapAnimationDuration: AppDurations.ms200,
      initialChildSize: _minChildSize,
      minChildSize: _minChildSize,
      maxChildSize: _maxChildSize,
      snap: true,
      snapSizes: const <double>[_minChildSize, 0.5, _maxChildSize],
      builder: (BuildContext context, ScrollController scrollController) {
        return Material(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(Dimens.pt20),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withValues(
                        alpha: 0.18,
                      ),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    widget.onDragHandleTapped();
                    if (_sheetController.isAttached) {
                      final double animateToSize =
                          _sheetController.size == _minChildSize
                              ? _maxChildSize
                              : _minChildSize;
                      _sheetController.animateTo(
                        animateToSize,
                        duration: AppDurations.ms500,
                        curve: SpringCurve.overDamped,
                      );
                    }
                  },
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      children: <Widget>[
                        SizedBoxes.pt8,
                        RotationTransition(
                          turns: _rotationAnim,
                          child: const Icon(
                            Icons.keyboard_arrow_up_rounded,
                          ),
                        ),
                        _UrlBar(
                          controller: _urlController,
                          isLoading: _isLoading,
                          loadingProgress: _loadingProgress,
                          canGoBack: _canGoBack,
                          canGoForward: _canGoForward,
                          onBack: () => _controller.goBack(),
                          onForward: () => _controller.goForward(),
                          onRefresh: _refresh,
                          onClose: () {
                            if (_sheetController.isAttached) {
                              if (_sheetController.size == _minChildSize) {
                                widget.onCloseTapped();
                              } else {
                                _sheetController.animateTo(
                                  _minChildSize,
                                  duration: AppDurations.ms300,
                                  curve: Curves.easeOutCubic,
                                );
                              }
                            }
                          },
                          onSubmit: _loadUrl,
                        ),
                        SizedBoxes.pt8,
                      ],
                    ),
                  ),
                ),
                Expanded(
                  key: ValueKey<double>(
                    _sheetController.isAttached
                        ? _sheetController.size
                        : _minChildSize,
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(Dimens.pt20),
                    ),
                    child: WebViewWidget(controller: _controller),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UrlBar extends StatefulWidget {
  const _UrlBar({
    required this.controller,
    required this.isLoading,
    required this.loadingProgress,
    required this.canGoBack,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
    required this.onRefresh,
    required this.onClose,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isLoading;
  final double loadingProgress;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onRefresh;
  final VoidCallback onClose;
  final ValueChanged<String> onSubmit;

  @override
  State<_UrlBar> createState() => _UrlBarState();
}

class _UrlBarState extends State<_UrlBar> {
  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.pt8,
        vertical: Dimens.pt4,
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: TextDimens.pt18,
            ),
            onPressed: widget.canGoBack ? widget.onBack : null,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: TextDimens.pt18,
            ),
            onPressed: widget.canGoForward ? widget.onForward : null,
            visualDensity: VisualDensity.compact,
          ),
          SizedBoxes.pt4,
          Expanded(
            child: Container(
              height: Dimens.pt36,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(Dimens.pt10),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: Dimens.pt12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _displayUrl(widget.controller.text),
                      style: TextStyle(
                        fontSize: TextDimens.pt12,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBoxes.pt4,
          IconButton(
            icon: Icon(
              widget.isLoading ? Icons.close_rounded : Icons.refresh_rounded,
              size: TextDimens.pt20,
            ),
            onPressed: widget.onRefresh,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              size: TextDimens.pt20,
            ),
            onPressed: widget.onClose,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  String _displayUrl(String url) {
    try {
      final Uri uri = Uri.parse(url);
      return uri.host.isNotEmpty ? uri.host : url;
    } catch (_) {
      return url;
    }
  }
}
