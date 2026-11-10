import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/theme/app_theme.dart';
import '../cubit/auth_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    final login = _loginController.text.trim();
    final pass = _passwordController.text;

    if (login.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen kullanıcı adı / e-posta ve şifrenizi girin.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authCubit = context.read<AuthCubit>();
    final success = await authCubit.login(login, pass);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giriş başarılı! Hoş geldiniz. ⭐'),
          backgroundColor: Color(0xFF2ECC71),
        ),
      );
      context.go('/profile');
    } else {
      final state = authCubit.state;
      String errorMsg = 'Giriş yapılamadı. Bilgilerinizi kontrol edin.';
      if (state is Unauthenticated && state.message != null && state.message!.isNotEmpty) {
        errorMsg = state.message!;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final titleColor = isDark ? Colors.white : AppTheme.darkText;
    final mutedColor = isDark ? Colors.white60 : AppTheme.mutedText;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: titleColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ShadCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.movie_filter_rounded, color: AppTheme.primaryColor, size: 30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hoş Geldiniz',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Film koleksiyonunu ve listeni yönetmek için giriş yap.',
                    style: TextStyle(fontSize: 13, color: mutedColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // ShadInput: Giriş Alanı
                  Text(
                    'Kullanıcı Adı veya E-posta',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: titleColor),
                  ),
                  const SizedBox(height: 6),
                  ShadInput(
                    controller: _loginController,
                    placeholder: const Text('kullanici_adi veya email@ornek.com'),
                    leading: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(Icons.person_outline_rounded, size: 18, color: mutedColor),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ShadInput: Şifre Alanı
                  Text(
                    'Şifre',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: titleColor),
                  ),
                  const SizedBox(height: 6),
                  ShadInput(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    placeholder: const Text('••••••••'),
                    leading: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(Icons.lock_outline_rounded, size: 18, color: mutedColor),
                    ),
                    trailing: GestureDetector(
                      onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                      child: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18,
                        color: mutedColor,
                      ),
                    ),
                    onSubmitted: (_) => _submitLogin(),
                  ),
                  const SizedBox(height: 26),

                  // ShadButton: Giriş Butonu
                  ShadButton(
                    onPressed: _isLoading ? null : _submitLogin,
                    backgroundColor: AppTheme.primaryColor,
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Giriş Yap',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Kayıt Ol Yönlendirmesi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hesabınız yok mu? ',
                        style: TextStyle(color: mutedColor, fontSize: 13),
                      ),
                      ShadButton.link(
                        onPressed: () => context.push('/register'),
                        child: const Text(
                          'Kayıt Ol',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
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
