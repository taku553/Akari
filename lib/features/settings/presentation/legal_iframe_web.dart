import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

int _counter = 0;

/// Web版: iframeでHTMLを表示する（webview_flutterのWeb実装に依存しない）
Widget buildLegalIframe(String url) {
  final viewType = 'legal-iframe-${_counter++}';
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final iframe = web.HTMLIFrameElement()
      ..src = url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';
    return iframe;
  });
  return HtmlElementView(viewType: viewType);
}
