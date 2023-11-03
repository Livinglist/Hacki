import 'package:flutter/material.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/styles/styles.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({
    required this.url,
    super.key,
  });

  static const String routeName = 'web-view';

  final String url;

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  final WebViewController controller = WebViewController();
  bool showFullUrl = false;

  @override
  void initState() {
    super.initState();

    getUrlAndLoadWebView();
  }

  Future<void> getUrlAndLoadWebView() async {
    final String? html = await locator.get<OfflineRepository>().getHtml(
          url: widget.url,
        );

    if (html != null) {
      await controller.loadHtmlString(html);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).canvasColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: GestureDetector(
          onTap: () {
            setState(() {
              showFullUrl = !showFullUrl;
            });
          },
          child: Text(
            showFullUrl
                ? humanize(widget.url)
                : Uri.parse(widget.url).authority,
            style: const TextStyle(
              fontSize: TextDimens.pt14,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: WebViewWidget(
        controller: controller,
      ),
    );
  }

  static String humanize(String link) {
    final String humanized = link
        .replaceFirst(RegExp('https?://'), '')
        .replaceFirst(RegExp(r'www\.'), '');
    return humanized;
  }
}
