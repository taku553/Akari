import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'auth_service.dart';
import 'guest_mode_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  /// true（デフォルト）: ログインフォーム表示、false: 新規登録フォーム表示
  final bool initialIsLogin;
  /// ゲストモードの設定画面から遷移してきた場合 true。戻るボタンを表示する。
  final bool fromGuestMode;
  const LoginScreen({super.key, this.initialIsLogin = true, this.fromGuestMode = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true; // true: ログイン, false: 新規登録
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialIsLogin;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = ref.read(authServiceProvider);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isLogin) {
        await authService.signInWithEmail(email, password);
      } else {
        await authService.signUpWithEmail(email, password);
      }
      // 認証成功 → authStateProvider が変化し、自動的にホーム画面に遷移
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = '予期しないエラーが発生しました';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'このメールアドレスは登録されていません';
      case 'wrong-password':
      case 'invalid-credential':
        return 'メールアドレスまたはパスワードが正しくありません';
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています';
      case 'weak-password':
        return 'パスワードは6文字以上で入力してください';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません';
      case 'too-many-requests':
        return '試行回数が多すぎます。しばらく待ってから再試行してください';
      default:
        return 'エラーが発生しました ($code)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      // ゲストモードから来た場合のみ戻るボタンを表示
      appBar: widget.fromGuestMode
          ? AppBar(
              backgroundColor: const Color(0xFFF7F8FA),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Color(0xFF4A5568)),
                tooltip: 'ゲストモードに戻る',
                onPressed: () {
                  // ゲストモードへ戻る・フラグをリセット
                  ref.read(isFromGuestModeProvider.notifier).state = false;
                  ref.read(guestExitToLoginProvider.notifier).state = false;
                  ref.read(isGuestModeProvider.notifier).state = true;
                },
              ),
            )
          : null,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ロゴ（文字入り）
                  Center(
                    child: SvgPicture.asset(
                      'assets/images/akari_logo_full.svg',
                      width: 160,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isLogin ? 'ログイン' : '新規登録',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF718096),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // エラーメッセージ
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // メールアドレス
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'メールアドレス',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'メールアドレスを入力してください';
                      }
                      if (!value.contains('@')) {
                        return '有効なメールアドレスを入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // パスワード
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'パスワード',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'パスワードを入力してください';
                      }
                      if (!_isLogin && value.length < 6) {
                        return 'パスワードは6文字以上で入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // ログイン/登録ボタン
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF87171),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isLogin ? 'ログイン' : '登録',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 切り替えリンク
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _errorMessage = null;
                            });
                          },
                    child: Text(
                      _isLogin ? 'アカウントをお持ちでない方はこちら' : '既にアカウントをお持ちの方はこちら',
                      style: const TextStyle(
                        color: Color(0xFF718096),
                        fontSize: 13,
                      ),
                    ),
                  ),

                  // ─── ゲストモード ───────────────────────────
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'または',
                          style: TextStyle(
                            color: Color(0xFFA0AEC0),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // データ保存の注意書き
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: const Text(
                      '⚠️ ゲストモードのデータはこのデバイスにのみ保存されます。'
                      'アカウントを作成するとクラウドに保存でき、複数デバイスでデータを引き継げます。',
                      style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ゲストモードボタン
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              ref
                                  .read(isGuestModeProvider.notifier)
                                  .state = true;
                            },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'まずは試してみる（ログイン不要）',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
