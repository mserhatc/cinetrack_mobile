import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.12),
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
                  fontSize: 26,
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
              const SizedBox(height: 32),

              // Giriş Alanı
              TextField(
                controller: _loginController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Kullanıcı Adı veya E-posta',
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 20, color: mutedColor),
                ),
              ),
              const SizedBox(height: 16),

              // Şifre Alanı
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitLogin(),
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  prefixIcon: Icon(Icons.lock_outline_rounded, size: 20, color: mutedColor),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: mutedColor,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Giriş Butonu
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Giriş Yap',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 18),

              // Kayıt Ol Yönlendirmesi
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hesabınız yok mu? ',
                    style: TextStyle(color: mutedColor, fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/register'),
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
    );
  }
}
