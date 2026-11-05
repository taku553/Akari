import 'package:web/web.dart' as web;

/// Web版: 静的HTMLページ（例: terms.html）を新規タブで開く
void openRouteInNewTab(String path) {
  web.window.open('${web.window.location.origin}/$path', '_blank');
}
