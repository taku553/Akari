import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/open_in_new_tab.dart';
import '../../../core/widgets/max_width_container.dart';
import 'legal_iframe.dart';

/// assets/legal 配下のHTML（唯一の原本）をWebViewで表示する共通画面
class LegalDocumentScreen extends StatefulWidget {
  final String title;
  final String fileName;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.fileName,
  });

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.disabled)
        ..loadFlutterAsset('assets/legal/${widget.fileName}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.backgroundLight,
      appBar: AppBar(
        backgroundColor: context.palette.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.title,
          style: TextStyle(
            color: context.palette.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: kIsWeb
            ? [
                IconButton(
                  tooltip: '新しいタブで開く',
                  icon: Icon(
                    Icons.open_in_new,
                    color: context.palette.textPrimary,
                  ),
                  onPressed: () => openRouteInNewTab(widget.fileName),
                ),
              ]
            : null,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.palette.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: MaxWidthContainer(
        child: kIsWeb
            ? buildLegalIframe(Uri.base.resolve(widget.fileName).toString())
            : WebViewWidget(controller: _controller!),
      ),
    );
  }
}
