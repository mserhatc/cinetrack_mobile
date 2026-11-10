import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_picker_dialog.dart';
import '../cubit/auth_cubit.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _selectedAvatar;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    final username = _usernameController.text.trim();
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen kullanıcı adı, e-posta ve şifre alanlarını doldurun.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifreniz en az 6 karakter olmalıdır.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authCubit = context.read<AuthCubit>();
    final success = await authCubit.register(
      username,
      email,
      password,
      fullName.isNotEmpty ? fullName : username,
      avatar: _selectedAvatar,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kayıt başarılı! Hoş geldiniz. ⭐'),
          backgroundColor: Color(0xFF2ECC71),
        ),
      );
      context.go('/profile');
    } else {
      final state = authCubit.state;
      String errorMsg = 'Kayıt yapılamadı. Lütfen bilgilerinizi kontrol edin.';
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

  Future<void> _pickAvatar() async {
    final picked = await AvatarPickerDialog.show(context, initialAvatar: _selectedAvatar);
    if (picked != null && mounted) {
      setState(() => _selectedAvatar = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
            constraints: const BoxConstraints(maxWidth: 440),
            child: ShadCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo & Başlık
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
                    'Hesap Oluştur',
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
                    'Film ve dizi dünyasındaki keşiflerini kaydet.',
                    style: TextStyle(fontSize: 13, color: mutedColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // ShadAvatar ile Avatar Seçici
                  Center(
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        children: [
                          if (_selectedAvatar != null && _selectedAvatar!.isNotEmpty)
                            ShadAvatar(
                              _selectedAvatar!,
                              size: const Size.square(80),
                              placeholder: Icon(Icons.person, size: 40, color: mutedColor),
                            )
                          else
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? const Color(0xFF1E212B) : const Color(0xFFF2F4F7),
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: Icon(Icons.person_outline_rounded, size: 40, color: mutedColor),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Kullanıcı Adı
                  Text(
                    'Kullanıcı Adı *',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: titleColor),
                  ),
                  const SizedBox(height: 6),
                  ShadInput(
                    controller: _usernameController,
                    placeholder: const Text('Örn: sinemasever'),
                    leading: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(Icons.alternate_email_rounded, size: 18, color: mutedColor),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ad Soyad
                  Text(
                    'Ad Soyad',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: titleColor),
                  ),
                  const SizedBox(height: 6),
                  ShadInput(
                    controller: _fullNameController,
                    placeholder: const Text('Örn: Serhat Çakır'),
                    leading: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(Icons.badge_outlined, size: 18, color: mutedColor),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // E-posta
                  Text(
                    'E-posta Adresi *',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: titleColor),
                  ),
                  const SizedBox(height: 6),
                  ShadInput(
                    controller: _emailController,
                    placeholder: const Text('ornek@email.com'),
                    leading: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(Icons.mail_outline_rounded, size: 18, color: mutedColor),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Şifre
                  Text(
                    'Şifre * (En az 6 karakter)',
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
                  ),
                  const SizedBox(height: 26),

                  // ShadButton: Kayıt Ol Butonu
                  ShadButton(
                    onPressed: _isLoading ? null : _submitRegister,
                    backgroundColor: AppTheme.primaryColor,
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Kayıt Ol',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Zaten Hesabım Var
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Zaten bir hesabınız var mı? ',
                        style: TextStyle(color: mutedColor, fontSize: 13),
                      ),
                      ShadButton.link(
                        onPressed: () => context.push('/login'),
                        child: const Text(
                          'Giriş Yap',
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
