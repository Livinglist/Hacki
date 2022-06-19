import 'package:flutter/material.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({
    super.key,
    required this.url,
  });

  final String url;

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).canvasColor,
        title: Text(
          humanize(widget.url),
          style: const TextStyle(
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      body: WebView(
        onWebViewCreated: (WebViewController controller) async {
          final String? html = await locator.get<CacheRepository>().getHtml(
                url: widget.url,
              );

          if (html != null) {
            await controller.loadHtmlString(html);
          }
        },
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
