import 'package:hacki/config/constants.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';

/// Controls the visibility of an [ItemScreenWebView].
///
/// Held by the owning screen so the sheet can be revealed both from within
/// (drag handle / close button) and from the outside (e.g. tapping a story's
/// url in the header).
class ItemScreenWebViewController extends ChangeNotifier {
  bool _isVisible = true;

  bool get isVisible => _isVisible;

  /// Reveals the sheet if it is currently hidden.
  void show() {
    if (_isVisible) return;
    _isVisible = true;
    notifyListeners();
  }

  /// Flips the sheet between visible and hidden.
  void toggle() {
    _isVisible = !_isVisible;
    notifyListeners();
  }
}

/// The draggable web view bottom sheet shown on the item screen for a story's
/// linked url. It slides just out of view when hidden instead of being removed
/// from the tree, so its state is preserved.
class ItemScreenWebView extends StatelessWidget {
  const ItemScreenWebView({
    required this.url,
    required this.controller,
    super.key,
  });

  final String url;
  final ItemScreenWebViewController controller;

  static const double _offsetInvisible = 0.1;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        return Positioned.fill(
          child: AnimatedSlide(
            offset: Offset(0, controller.isVisible ? 0 : _offsetInvisible),
            duration: AppDurations.ms200,
            child: WebViewBottomSheet(
              initialUrl: url,
              isVisible: controller.isVisible,
              onDragHandleTapped: controller.show,
              onCloseTapped: controller.toggle,
            ),
          ),
        );
      },
    );
  }
}
