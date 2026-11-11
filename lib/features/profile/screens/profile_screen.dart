import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_picker_dialog.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../feed/cubit/feed_cubit.dart';
import '../../feed/widgets/comments_modal.dart';
import '../cubit/profile_cubit.dart';

class ProfileScreen extends StatefulWidget {
  final int? targetUserId;

  const ProfileScreen({super.key, this.targetUserId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoginTab = true;

  final _loginUserInputController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _obscureLoginPassword = true;

  final _regUsernameController = TextEditingController();
  final _regFullNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  bool _obscureRegPassword = true;
  String? _regAvatar;

  List<Map<String, dynamic>> _recentWatched = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _loginUserInputController.dispose();
    _loginPasswordController.dispose();
    _regUsernameController.dispose();
    _regFullNameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated || widget.targetUserId != null) {
      final cubit = context.read<ProfileCubit>();
      await cubit.loadProfile(userId: widget.targetUserId);
      if (!mounted) return;
      final uid = widget.targetUserId ??
          (authState is Authenticated ? int.tryParse(authState.user['id']?.toString() ?? '') : null);
      if (uid != null && uid > 0) {
        final watched = await cubit.getWatchedMovies(uid);
        if (mounted) {
          setState(() {
            _recentWatched = watched.take(6).toList();
          });
        }
      }
    }
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'SÇ';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (trimmed.length >= 2) {
      return trimmed.substring(0, 2).toUpperCase();
    }
    return trimmed[0].toUpperCase();
  }

  Future<void> _handleInlineLogin() async {
    final login = _loginUserInputController.text.trim();
    final pass = _loginPasswordController.text;

    if (login.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen kullanıcı adı / e-posta ve şifrenizi girin.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final authCubit = context.read<AuthCubit>();
    final success = await authCubit.login(login, pass);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hoş geldiniz! Giriş başarılı. ⭐'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
      _loadProfileData();
      context.read<FeedCubit>().fetchFeed();
    } else {
      final state = authCubit.state;
      String errorMsg = 'Giriş yapılamadı.';
      if (state is Unauthenticated && state.message != null && state.message!.isNotEmpty) {
        errorMsg = state.message!;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _handleInlineRegister() async {
    final username = _regUsernameController.text.trim();
    final fullName = _regFullNameController.text.trim();
    final email = _regEmailController.text.trim();
    final pass = _regPasswordController.text;

    if (username.isEmpty || email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen kullanıcı adı, e-posta ve şifre alanlarını doldurun.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifreniz en az 6 karakter olmalıdır.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final authCubit = context.read<AuthCubit>();
    final success = await authCubit.register(
      username,
      email,
      pass,
      fullName.isNotEmpty ? fullName : username,
      avatar: _regAvatar,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hesabınız oluşturuldu! Hoş geldiniz. ⭐'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
      _loadProfileData();
      context.read<FeedCubit>().fetchFeed();
    } else {
      final state = authCubit.state;
      String errorMsg = 'Kayıt yapılamadı. Lütfen bilgilerinizi kontrol edin.';
      if (state is Unauthenticated && state.message != null && state.message!.isNotEmpty) {
        errorMsg = state.message!;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showEditProfileModal(BuildContext context, Map<String, dynamic> user) {
    final fullNameController = TextEditingController(text: user['full_name']?.toString() ?? '');
    final bioController = TextEditingController(text: user['bio']?.toString() ?? '');
    String currentAvatar = user['avatar']?.toString() ?? '';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final sheetBg = isDark ? AppTheme.darkCard : Colors.white;
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: 24 + bottomInset,
              ),
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Text(
                      'Profili Düzenle',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await AvatarPickerDialog.show(
                            ctx,
                            initialAvatar: currentAvatar,
                          );
                          if (picked != null) {
                            setModalState(() => currentAvatar = picked);
                          }
                        },
                        child: Stack(
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                                ),
                              ),
                              child: ClipOval(
                                child: currentAvatar.isNotEmpty
                                    ? Image.network(
                                        currentAvatar,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.person,
                                          size: 40,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.person, size: 40, color: Colors.white),
                              ),
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
                    const SizedBox(height: 20),
                    const Text('Ad Soyad', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: fullNameController,
                      decoration: const InputDecoration(hintText: 'Adınız ve Soyadınız'),
                    ),
                    const SizedBox(height: 14),
                    const Text('Biyografi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(hintText: 'Sinema tutkunu, bilim kurgu aşığı.'),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                setModalState(() => isSaving = true);
                                final updatedName = fullNameController.text.trim();
                                final updatedBio = bioController.text.trim();

                                final success = await this.context.read<AuthCubit>().updateProfile(
                                      fullName: updatedName,
                                      bio: updatedBio,
                                      avatar: currentAvatar,
                                    );

                                if (success && mounted) {
                                  this.context.read<ProfileCubit>().updateProfileLocally({
                                    'full_name': updatedName,
                                    'bio': updatedBio,
                                    'avatar': currentAvatar,
                                  });
                                  this.context.read<ProfileCubit>().loadProfile();
                                  this.context.read<FeedCubit>().fetchFeed();

                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                  }
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    const SnackBar(content: Text('Profiliniz güncellendi!')),
                                  );
                                } else if (mounted) {
                                  setModalState(() => isSaving = false);
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    const SnackBar(content: Text('Profil güncellenirken bir hata oluştu.')),
                                  );
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Değişiklikleri Kaydet'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    final authState = context.watch<AuthCubit>().state;
    final currentUserId =
        authState is Authenticated ? int.tryParse(authState.user['id']?.toString() ?? '') : null;
    final isMe =
        widget.targetUserId == null || (currentUserId != null && widget.targetUserId == currentUserId);
    final isLoggedIn = authState is Authenticated;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final titleColor = isDark ? Colors.white : AppTheme.darkText;
    final mutedColor = isDark ? Colors.white60 : AppTheme.mutedText;

    // 1. DURUM: Giriş Yapılmamışsa
    if (isMe && !isLoggedIn) {
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFBBF24), Color(0xFFEA580C)],
                      ),
                    ),
                    child: const Icon(Icons.movie_outlined, color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isLoginTab ? 'Hoş Geldiniz' : 'Hesap Oluştur',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sinema topluluğuna katıl',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: mutedColor, fontSize: 14),
                ),
                const SizedBox(height: 24),

                // Giriş / Kayıt Segmented Toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : AppTheme.softGreyBg,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isLoginTab = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isLoginTab
                                  ? (isDark ? AppTheme.primaryColor : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: _isLoginTab
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              loc.translate('login'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: _isLoginTab ? titleColor : mutedColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isLoginTab = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isLoginTab
                                  ? (isDark ? AppTheme.primaryColor : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: !_isLoginTab
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              loc.translate('register'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: !_isLoginTab ? titleColor : mutedColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (_isLoginTab) ...[
                  Text('Kullanıcı Adı veya E-posta',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: titleColor)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _loginUserInputController,
                    decoration: InputDecoration(
                      hintText: '@kullanici_adi veya email@ornek.com',
                      prefixIcon: Icon(Icons.alternate_email_rounded, size: 19, color: mutedColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Şifre',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: titleColor)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _loginPasswordController,
                    obscureText: _obscureLoginPassword,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: Icon(Icons.lock_outline_rounded, size: 19, color: mutedColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureLoginPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 19,
                          color: mutedColor,
                        ),
                        onPressed: () =>
                            setState(() => _obscureLoginPassword = !_obscureLoginPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _handleInlineLogin,
                      child: Text(loc.translate('login')),
                    ),
                  ),
                ] else ...[
                  Text('Kullanıcı Adı *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: titleColor)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _regUsernameController,
                    decoration: InputDecoration(
                      hintText: '@kullanici_adi',
                      prefixIcon: Icon(Icons.alternate_email_rounded, size: 19, color: mutedColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('E-posta Adresi *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: titleColor)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _regEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'email@ornek.com',
                      prefixIcon: Icon(Icons.mail_outline_rounded, size: 19, color: mutedColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Şifre * (En az 6 karakter)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: titleColor)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _regPasswordController,
                    obscureText: _obscureRegPassword,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: Icon(Icons.lock_outline_rounded, size: 19, color: mutedColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureRegPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 19,
                          color: mutedColor,
                        ),
                        onPressed: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _handleInlineRegister,
                      child: Text(loc.translate('register')),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    // 2. DURUM: Kullanıcı Profili Ekranı (PDF Page 4)
    return Scaffold(
      backgroundColor: bg,
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }

          if (state is ProfileError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadProfileData, child: const Text('Yenile')),
                ],
              ),
            );
          }

          if (state is ProfileLoaded) {
            final user = state.user;
            final stats = user['stats'] ?? {};
            final posts = state.userPosts;
            final userId = int.tryParse(user['id'].toString()) ?? 0;
            final avatar = user['avatar'];
            final username = user['username']?.toString() ?? 'serhatc';
            final fullName = user['full_name']?.toString().isNotEmpty == true
                ? user['full_name'].toString()
                : username;
            final bio = user['bio']?.toString().isNotEmpty == true
                ? user['bio'].toString()
                : 'Sinema tutkunu, bilim kurgu aşığı.';

            final followersCount = stats['followers'] ?? 124;
            final followingCount = stats['following'] ?? 85;
            final watchedMoviesCount = stats['watched_movies'] ?? 342;
            final watchedShowsCount = stats['watched_shows'] ?? 48;

            return RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: _loadProfileData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.only(bottom: 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Üst Sıcak Degrade Banner + Üzerine Binen Yuvarlak "SÇ" Avatarı (PDF Page 4)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 145,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFF59E0B),
                                Color(0xFFD9531E),
                                Color(0xFF7C2D12),
                              ],
                            ),
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withValues(alpha: 0.8),
                                        ),
                                        child: const Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          size: 18,
                                          color: AppTheme.darkText,
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox.shrink(),
                                  if (isMe)
                                    GestureDetector(
                                      onTap: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(24),
                                            ),
                                            title: Text(
                                              loc.translate('logout'),
                                              style: const TextStyle(fontWeight: FontWeight.w800),
                                            ),
                                            content: const Text(
                                              'Oturumunuzu kapatmak istediğinize emin misiniz?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, false),
                                                child: const Text('İptal'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(ctx, true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppTheme.heartRed,
                                                ),
                                                child: const Text('Çıkış Yap'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true && mounted) {
                                          await this.context.read<AuthCubit>().logout();
                                          if (!mounted) return;
                                          this.context.read<FeedCubit>().fetchFeed();
                                          this.context.go('/feed');
                                        }
                                      },
                                      child: Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black.withValues(alpha: 0.22),
                                        ),
                                        child: const Icon(
                                          Icons.logout_rounded,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Üzerine Binen Mavi-İndigo Yuvarlak Avatar (SÇ)
                        Positioned(
                          left: 20,
                          bottom: -44,
                          child: GestureDetector(
                            onTap: isMe ? () => _showEditProfileModal(context, user) : null,
                            child: Container(
                              width: 92,
                              height: 92,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: bg,
                              ),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                                  ),
                                ),
                                child: ClipOval(
                                  child: (avatar != null && avatar.toString().isNotEmpty)
                                      ? Image.network(
                                          avatar.toString(),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Center(
                                            child: Text(
                                              _getInitials(fullName),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 28,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            _getInitials(fullName),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 54),

                    // 2. Kullanıcı Adı, @handle, Bio ve Sağda "✎ Düzenle" Hap Butonu (PDF Page 4)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fullName,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: titleColor,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '@$username',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: mutedColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isMe)
                                GestureDetector(
                                  onTap: () => _showEditProfileModal(context, user),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppTheme.darkCard : Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: isDark ? AppTheme.darkCardBorder : AppTheme.borderColor,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit_outlined, size: 15, color: titleColor),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Düzenle',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: titleColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                GestureDetector(
                                  onTap: () async {
                                    if (!isLoggedIn) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Takip edebilmek için lütfen önce giriş yapın.'),
                                        ),
                                      );
                                      return;
                                    }
                                    final ok = await context.read<ProfileCubit>().toggleFollow(userId);
                                    if (ok && mounted) {
                                      this.context.read<FeedCubit>().fetchFeed();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                                    decoration: BoxDecoration(
                                      color: stats['is_following'] == true
                                          ? AppTheme.softGreyBg
                                          : AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Text(
                                      stats['is_following'] == true ? 'Takibi Bırak' : 'Takip Et',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: stats['is_following'] == true
                                            ? AppTheme.darkText
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            bio,
                            style: TextStyle(
                              fontSize: 14.5,
                              color: isDark ? Colors.white70 : const Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 3. 4 İstatistik Kartı (Takipçi, Takip, Film, Dizi - Amber İkonlu - PDF Page 4)
                          Row(
                            children: [
                              _buildMetricCard(
                                context,
                                icon: Icons.person_outline_rounded,
                                count: followersCount,
                                label: 'Takipçi',
                                isDark: isDark,
                                onTap: () => context.push('/user-list/followers/$userId'),
                              ),
                              const SizedBox(width: 10),
                              _buildMetricCard(
                                context,
                                icon: Icons.add_rounded,
                                count: followingCount,
                                label: 'Takip',
                                isDark: isDark,
                                onTap: () => context.push('/user-list/following/$userId'),
                              ),
                              const SizedBox(width: 10),
                              _buildMetricCard(
                                context,
                                icon: Icons.movie_outlined,
                                count: watchedMoviesCount,
                                label: 'Film',
                                isDark: isDark,
                                onTap: () => context.push('/watched-list/movie/$userId'),
                              ),
                              const SizedBox(width: 10),
                              _buildMetricCard(
                                context,
                                icon: Icons.tv_rounded,
                                count: watchedShowsCount,
                                label: 'Dizi',
                                isDark: isDark,
                                onTap: () => context.push('/watched-list/tv/$userId'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 26),

                          // 4. Son izlenenler Bölümü (4 Renkli / Posterli Dikey Kart - PDF Page 4)
                          GestureDetector(
                            onTap: () => context.push('/watched-list/movie/$userId'),
                            child: Text(
                              'Son izlenenler',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: titleColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildRecentlyWatchedRow(context, userId),

                          const SizedBox(height: 26),

                          // 5. Bana Ait Akış (12) Bölümü (PDF Page 4)
                          Text(
                            isMe
                                ? 'Bana Ait Akış (${posts.length})'
                                : 'Paylaşımlar (${posts.length})',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: titleColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (posts.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkCard : AppTheme.mediaCardBg,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.movie_creation_outlined,
                                      size: 44, color: Colors.grey.shade400),
                                  const SizedBox(height: 10),
                                  Text(
                                    isMe
                                        ? 'Henüz bir paylaşımınız yok.'
                                        : 'Henüz paylaşım bulunmuyor.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: titleColor,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Column(
                              children: posts.map((post) {
                                return _buildCompactProfilePostCard(context, post, isDark);
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required dynamic count,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final titleColor = isDark ? Colors.white : AppTheme.darkText;
    final mutedColor = isDark ? Colors.white60 : AppTheme.mutedText;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.mediaCardBg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: AppTheme.primaryColor),
              const SizedBox(height: 6),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: mutedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentlyWatchedRow(BuildContext context, int userId) {
    const fallbackGradients = [
      [Color(0xFFC85A28), Color(0xFFF29B38)], // Warm Orange
      [Color(0xFF1D4ED8), Color(0xFF3B82F6)], // Royal Blue
      [Color(0xFF881337), Color(0xFFE11D48)], // Crimson Red
      [Color(0xFF065F46), Color(0xFF10B981)], // Emerald Green
    ];

    return Row(
      children: List.generate(4, (index) {
        final hasItem = index < _recentWatched.length;
        final item = hasItem ? _recentWatched[index] : null;
        final posterPath = item?['poster_path'];
        final tmdbId = item?['tmdb_id'];
        final mediaType = item?['media_type'] ?? 'movie';
        final grad = fallbackGradients[index % fallbackGradients.length];

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < 3 ? 10 : 0),
            child: GestureDetector(
              onTap: () {
                if (tmdbId != null) {
                  context.push('/media/$mediaType/$tmdbId');
                } else {
                  context.push('/watched-list/movie/$userId');
                }
              },
              child: Container(
                height: 116,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: grad,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: (posterPath != null && posterPath.toString().isNotEmpty)
                      ? Image.network(
                          AppConstants.getPosterUrl(posterPath.toString()),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCompactProfilePostCard(
    BuildContext context,
    Map<String, dynamic> post,
    bool isDark,
  ) {
    final titleColor = isDark ? Colors.white : AppTheme.darkText;
    final mutedColor = isDark ? Colors.white60 : AppTheme.mutedText;
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final postId = int.tryParse(post['id']?.toString() ?? '0') ?? 0;
    final postUserId = int.tryParse(post['user_id']?.toString() ?? '0') ?? 0;

    final quoteText = post['quote_text']?.toString() ?? '';
    final contentText = post['content']?.toString() ?? '';
    final displayQuote = quoteText.isNotEmpty ? '“$quoteText”' : contentText;
    final likesCount = post['likes_count'] ?? 0;
    final commentsCount = post['comments_count'] ?? 0;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useRootNavigator: true,
          backgroundColor: Colors.transparent,
          builder: (_) => CommentsModal(
            postId: postId,
            postUserId: postUserId,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? AppTheme.darkCardBorder : const Color(0xFFF1F2F6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppTheme.primaryColor, width: 3.5),
                ),
              ),
              child: Text(
                displayQuote,
                style: TextStyle(
                  fontSize: 15.5,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '♥ $likesCount · $commentsCount yorum',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: mutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
