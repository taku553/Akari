import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ゲストモード（ログインなしで使用中）かどうかを管理するProvider。
/// LoginScreen で「まずは試してみる」を押したら true になり、
/// 設定画面から「アカウントを作成」または「ログイン」を押したら false に戻る。
final isGuestModeProvider = StateProvider<bool>((ref) => false);

/// ゲストモードを終了してログイン画面を開く際、
/// ログインフォームを最初に表示するか（true）、新規登録フォームを表示するか（false）を管理するProvider。
final guestExitToLoginProvider = StateProvider<bool>((ref) => false);

/// ゲストモードの設定画面からログイン画面に来た場合に true になるProvider。
/// このフラグが true のとき、ログイン画面にゲストモードへ戻るボタンを表示する。
final isFromGuestModeProvider = StateProvider<bool>((ref) => false);
