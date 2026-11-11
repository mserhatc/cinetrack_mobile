import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../cubit/auth_cubit.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  int _selectedColorIndex = 2; // Ortadaki altın amber varsayılan seçili (PDF Page 6)
  bool _isLoading = false;

  static const List<Color> _avatarColors = [
    Color(0xFFFCD385), // Soft Peach-Amber
    Color(0xFFBFDBFE), // Soft Blue
    Color(0xFFF5A623), // Selected Golden Amber
    Color(0xFFA7F3D0), // Soft Mint
    Color(0xFFFBCFE8), // Soft Rose
    Color(0xFFDDD6FE), // Soft Lavender
    Color(0xFFFDE08D), // Soft Yellow
    Color(0xFFBAE6FD), // Soft Cyan
  ];

  static const List<String> _avatarSeeds = [
    'https://api.dicebear.com/7.x/bottts/png?seed=CineAmber',
    'https://api.dicebear.com/7.x/bottts/png?seed=CineBlue',
    'https://api.dicebear.com/7.x/bottts/png?seed=CineGold',
    'https://api.dicebear.com/7.x/bottts/png?seed=CineMint',
    'https://api.dicebear.com/7.x/bottts/png?seed=CineRose',
    'https://api.dicebear.com/7.x/bottts/png?seed=CinePurple',
    'https://api.dicebear.com/7.x/bottts/png?seed=CineSun',
    'https://api.dicebear.com/7.x/bottts/png?seed=CineCyan',
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    final username = _usernameController.text.trim().replaceAll('@', '');
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
      username,
      avatar: _avatarSeeds[_selectedColorIndex],
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kayıt başarılı! Hoş geldiniz. ⭐'),
          backgroundColor: Color(0xFF16A34A),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final titleColor = isDark ? Colors.white : AppTheme.darkText;
    final mutedColor = isDark ? Colors.white60 : AppTheme.mutedText;
    final boxBg = isDark ? AppTheme.darkCard : AppTheme.softGreyBg;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Sağ Üst Yumuşak Dekoratif Krem Halesi (PDF Page 6)
          if (!isDark)
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFEF3C7).withValues(alpha: 0.7),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sol Üst Geri (<) Butonu
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: boxBg,
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: titleColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Turuncu Kare Film İkonu (PDF Page 6)
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFBBF24), Color(0xFFEA580C)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEA580C).withValues(alpha: 0.28),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.movie_outlined, color: Colors.white, size: 34),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Başlık & Alt Başlık
                  Text(
                    'Hesap Oluştur',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sinema topluluğuna katıl',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: mutedColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 8 Renkli Pastel Avatar Seçici Daireleri (PDF Page 6)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_avatarColors.length, (index) {
                      final isSelected = _selectedColorIndex == index;
                      final color = _avatarColors[index];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColorIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: isSelected ? 42 : 34,
                          height: isSelected ? 42 : 34,
                          padding: EdgeInsets.all(isSelected ? 3 : 0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: AppTheme.primaryColor, width: 2.2)
                                : null,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),

                  // Kullanıcı Adı * (Amber Çerçeveli Odaklı Giriş Kutusu - PDF Page 6)
                  Text(
                    'Kullanıcı Adı *',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usernameController,
                    style: TextStyle(color: titleColor, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: '@kullanici_adi',
                      filled: true,
                      fillColor: isDark ? AppTheme.darkCard : Colors.white,
                      prefixIcon: Icon(Icons.alternate_email_rounded, size: 20, color: mutedColor),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // E-posta Adresi *
                  Text(
                    'E-posta Adresi *',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: titleColor, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'email@ornek.com',
                      filled: true,
                      fillColor: boxBg,
                      prefixIcon: Icon(Icons.mail_outline_rounded, size: 20, color: mutedColor),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Şifre * (En az 6 karakter)
                  Text(
                    'Şifre * (En az 6 karakter)',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: titleColor, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      filled: true,
                      fillColor: boxBg,
                      prefixIcon: Icon(Icons.lock_outline_rounded, size: 20, color: mutedColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: mutedColor,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Kayıt Ol Butonu (PDF Page 6)
                  GestureDetector(
                    onTap: _isLoading ? null : _submitRegister,
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.primaryGradientStart,
                            AppTheme.primaryGradientEnd,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Kayıt Ol',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Alt Bağlantı: Zaten bir hesabınız var mı? Giriş Yap
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Zaten bir hesabınız var mı? ',
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/login'),
                        child: const Text(
                          'Giriş Yap',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
