import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo & Başlık
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
                'Hesap Oluştur',
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
                'Film ve dizi dünyasındaki keşiflerini kaydet.',
                style: TextStyle(fontSize: 13, color: mutedColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Avatar Seçici
              Center(
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: isDark ? AppTheme.darkCard : const Color(0xFFF2F4F7),
                        backgroundImage: (_selectedAvatar != null && _selectedAvatar!.isNotEmpty)
                            ? NetworkImage(_selectedAvatar!)
                            : null,
                        child: (_selectedAvatar == null || _selectedAvatar!.isEmpty)
                            ? Icon(Icons.person_outline_rounded, size: 40, color: mutedColor)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: bg, width: 2),
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
              TextField(
                controller: _usernameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Kullanıcı Adı *',
                  hintText: 'örn: sinemasever',
                  prefixIcon: Icon(Icons.alternate_email_rounded, size: 20, color: mutedColor),
                ),
              ),
              const SizedBox(height: 14),

              // Ad Soyad
              TextField(
                controller: _fullNameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Ad Soyad',
                  hintText: 'örn: Serhat Çakır',
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 20, color: mutedColor),
                ),
              ),
              const SizedBox(height: 14),

              // E-posta
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'E-posta *',
                  hintText: 'ornek@email.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded, size: 20, color: mutedColor),
                ),
              ),
              const SizedBox(height: 14),

              // Şifre
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitRegister(),
                decoration: InputDecoration(
                  labelText: 'Şifre * (En az 6 karakter)',
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
              const SizedBox(height: 24),

              // Kayıt Ol Butonu
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRegister,
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
                          'Kayıt Ol',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Zaten hesabım var
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Zaten hesabınız var mı? ',
                    style: TextStyle(color: mutedColor, fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/login'),
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
    );
  }
}
