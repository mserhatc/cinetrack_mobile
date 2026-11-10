import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/avatar_picker_dialog.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../feed/cubit/feed_cubit.dart';
import '../../feed/widgets/post_card.dart';
import '../cubit/profile_cubit.dart';

class ProfileScreen extends StatefulWidget {
  final int? targetUserId;

  const ProfileScreen({super.key, this.targetUserId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Giriş / Kayıt Toggle durumu (Giriş yapılmamışken sekme içinde formlar)
  bool _isLoginTab = true;

  // Login Controller'ları
  final _loginUserInputController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _obscureLoginPassword = true;

  // Register Controller'ları
  final _regUsernameController = TextEditingController();
  final _regFullNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  bool _obscureRegPassword = true;
  String? _regAvatar;

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

  void _loadProfileData() {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated || widget.targetUserId != null) {
      context.read<ProfileCubit>().loadProfile(userId: widget.targetUserId);
    }
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
          backgroundColor: Color(0xFF2ECC71),
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
          backgroundColor: Color(0xFF2ECC71),
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
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showEditProfileModal(BuildContext context, Map<String, dynamic> user) {
    final theme = Theme.of(context);
    final fullNameController = TextEditingController(text: user['full_name'] ?? user['username'] ?? '');
    final bioController = TextEditingController(text: user['bio'] ?? '');
    String currentAvatar = user['avatar'] ?? '';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                        decoration: BoxDecoration(
                          color: Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Profili Düzenle',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Avatar Seç / Değiştir
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final picked = await AvatarPickerDialog.show(context, initialAvatar: currentAvatar);
                              if (picked != null) {
                                setModalState(() {
                                  currentAvatar = picked;
                                });
                              }
                            },
                            child: CircleAvatar(
                              radius: 44,
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                              backgroundImage: currentAvatar.isNotEmpty ? NetworkImage(currentAvatar) : null,
                              child: currentAvatar.isEmpty
                                  ? const Icon(Icons.person, size: 44, color: Colors.grey)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () async {
                                final picked = await AvatarPickerDialog.show(context, initialAvatar: currentAvatar);
                                if (picked != null) {
                                  setModalState(() {
                                    currentAvatar = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: TextButton.icon(
                        onPressed: () async {
                          final picked = await AvatarPickerDialog.show(context, initialAvatar: currentAvatar);
                          if (picked != null) {
                            setModalState(() {
                              currentAvatar = picked;
                            });
                          }
                        },
                        icon: const Icon(Icons.image_outlined, size: 16),
                        label: const Text('Fotoğrafı Değiştir', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ad Soyad
                    TextField(
                      controller: fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Ad Soyad',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Biyografi
                    TextField(
                      controller: bioController,
                      maxLines: 3,
                      maxLength: 255,
                      decoration: const InputDecoration(
                        labelText: 'Biyografi',
                        hintText: 'Kendinizi ve film zevkinizi anlatın...',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Kaydet Butonu
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              setModalState(() => isSaving = true);
                              final updatedName = fullNameController.text.trim();
                              final updatedBio = bioController.text.trim();

                              final success = await context.read<AuthCubit>().updateProfile(
                                fullName: updatedName,
                                bio: updatedBio,
                                avatar: currentAvatar,
                              );

                              if (success && mounted) {
                                context.read<ProfileCubit>().updateProfileLocally({
                                  'full_name': updatedName,
                                  'bio': updatedBio,
                                  'avatar': currentAvatar,
                                });
                                context.read<ProfileCubit>().loadProfile();
                                context.read<FeedCubit>().fetchFeed();

                                Navigator.pop(sheetContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Profiliniz güncellendi!')),
                                );
                              } else if (mounted) {
                                setModalState(() => isSaving = false);
                                ScaffoldMessenger.of(context).showSnackBar(
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
    final loc = AppLocalizations.of(context);
    final authState = context.watch<AuthCubit>().state;
    final currentUserId = authState is Authenticated ? int.tryParse(authState.user['id']?.toString() ?? '') : null;
    final isMe = widget.targetUserId == null || (currentUserId != null && widget.targetUserId == currentUserId);
    final isLoggedIn = authState is Authenticated;

    // 1. DURUM: Giriş Yapılmamışsa ve kendi profiliyse doğrudan giriş ve kayıt formları
    if (isMe && !isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.translate('profile')),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // İkon ve Başlık
                Icon(Icons.movie_filter_rounded, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                const Text(
                  'CineTrack Topluluğu',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Profilinizi görmek, film ve dizileri takip etmek ve paylaşımlarınızı yönetmek için giriş yapın veya hesap oluşturun.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13.5),
                ),
                const SizedBox(height: 24),

                // Sekme Seçici: Giriş Yap / Kayıt Ol
                Container(
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF1E212D)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isLoginTab = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isLoginTab ? theme.colorScheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              loc.translate('login'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isLoginTab ? Colors.white : theme.textTheme.bodyMedium?.color,
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
                              color: !_isLoginTab ? theme.colorScheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              loc.translate('register'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !_isLoginTab ? Colors.white : theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // GİRİŞ YAP FORMU
                if (_isLoginTab) ...[
                  TextField(
                    controller: _loginUserInputController,
                    decoration: InputDecoration(
                      labelText: '${loc.translate('username')} / ${loc.translate('email')}',
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _loginPasswordController,
                    obscureText: _obscureLoginPassword,
                    decoration: InputDecoration(
                      labelText: loc.translate('password'),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureLoginPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _handleInlineLogin,
                    child: Text(loc.translate('login')),
                  ),
                ]
                // KAYIT OL FORMU
                else ...[
                  // Avatar Seçimi
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final picked = await AvatarPickerDialog.show(context, initialAvatar: _regAvatar);
                            if (picked != null) setState(() => _regAvatar = picked);
                          },
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                            backgroundImage: _regAvatar != null && _regAvatar!.isNotEmpty
                                ? NetworkImage(_regAvatar!)
                                : null,
                            child: _regAvatar == null || _regAvatar!.isEmpty
                                ? Icon(Icons.person, size: 36, color: theme.colorScheme.primary)
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        final picked = await AvatarPickerDialog.show(context, initialAvatar: _regAvatar);
                        if (picked != null) setState(() => _regAvatar = picked);
                      },
                      icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                      label: Text(
                        _regAvatar == null ? 'Profil Fotoğrafı Seç (İsteğe bağlı)' : 'Fotoğrafı Değiştir',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _regUsernameController,
                    decoration: InputDecoration(
                      labelText: loc.translate('username'),
                      prefixIcon: const Icon(Icons.alternate_email),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _regFullNameController,
                    decoration: InputDecoration(
                      labelText: loc.translate('full_name'),
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _regEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: loc.translate('email'),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _regPasswordController,
                    obscureText: _obscureRegPassword,
                    decoration: InputDecoration(
                      labelText: loc.translate('password'),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureRegPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _handleInlineRegister,
                    child: Text(loc.translate('register')),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    // 2. DURUM: Giriş Yapılmışsa Kullanıcıya Ait Profil ve Akış Ekranı (veya Hedef Profil)
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (isMe) return Text(loc.translate('profile'));
            if (state is ProfileLoaded) {
              return Text('@${state.user['username'] ?? 'Kullanıcı'}');
            }
            return const Text('Kullanıcı Profili');
          },
        ),
        actions: [
          if (isMe)
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              tooltip: loc.translate('logout'),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(loc.translate('logout')),
                    content: const Text('Oturumunuzu kapatmak istediğinize emin misiniz?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        child: const Text('Çıkış Yap'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await context.read<AuthCubit>().logout();
                  if (!mounted) return;
                  context.read<FeedCubit>().fetchFeed();
                  context.go('/feed');
                }
              },
            ),
        ],
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
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
            final username = user['username'] ?? '';
            final fullName = user['full_name'];
            final bio = user['bio'];

            final followersCount = stats['followers'] ?? 0;
            final followingCount = stats['following'] ?? 0;
            final watchedMoviesCount = stats['watched_movies'] ?? 0;
            final watchedShowsCount = stats['watched_shows'] ?? 0;

            return RefreshIndicator(
              onRefresh: () async => _loadProfileData(),
              child: CustomScrollView(
                slivers: [
                  // ÜST BÖLÜM: Profil Bilgileri & 4 Tıklanabilir İstatistik
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Profil Fotoğrafı, İsim, Bio
                          Row(
                            children: [
                              GestureDetector(
                                onTap: isMe ? () => _showEditProfileModal(context, user) : null,
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                                      backgroundImage: (avatar != null && avatar.toString().isNotEmpty)
                                          ? NetworkImage(avatar)
                                          : null,
                                      child: (avatar == null || avatar.toString().isEmpty)
                                          ? Text(
                                              username.isNotEmpty ? username[0].toUpperCase() : '?',
                                              style: TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.primary,
                                              ),
                                            )
                                          : null,
                                    ),
                                    if (isMe)
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                                          ),
                                          child: const Icon(Icons.edit, size: 13, color: Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fullName != null && fullName.toString().isNotEmpty ? fullName : username,
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '@$username',
                                      style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 14),
                                    ),
                                    if (bio != null && bio.toString().isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        bio,
                                        style: const TextStyle(fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (isMe) ...[
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _showEditProfileModal(context, user),
                                icon: const Icon(Icons.edit_note_rounded, size: 18),
                                label: const Text('Profili Düzenle', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                          if (!isMe) ...[
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (!isLoggedIn) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Takip edebilmek için lütfen önce giriş yapın.')),
                                    );
                                    return;
                                  }
                                  final ok = await context.read<ProfileCubit>().toggleFollow(userId);
                                  if (ok && mounted) {
                                    context.read<FeedCubit>().fetchFeed();
                                  }
                                },
                                icon: Icon(
                                  stats['is_following'] == true
                                      ? Icons.person_remove_rounded
                                      : Icons.person_add_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  stats['is_following'] == true ? 'Takibi Bırak' : 'Takip Et',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: stats['is_following'] == true
                                      ? (theme.brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade300)
                                      : theme.colorScheme.primary,
                                  foregroundColor: stats['is_following'] == true
                                      ? (theme.brightness == Brightness.dark ? Colors.white : Colors.black87)
                                      : Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),

                          // İSTENEN 4 TIKLANABİLİR KART / BUTON:
                          // 1) Takipçilerim, 2) Takip Ettiklerim, 3) İzlediğim Filmler, 4) İzlediğim Diziler
                          Row(
                            children: [
                              // 1. Takipçilerim
                              _buildProfileMetricCard(
                                context,
                                count: followersCount,
                                label: 'Takipçi',
                                icon: Icons.people_alt_outlined,
                                color: Colors.blueAccent,
                                onTap: () => context.push('/user-list/followers/$userId'),
                              ),
                              const SizedBox(width: 8),

                              // 2. Takip Ettiklerim
                              _buildProfileMetricCard(
                                context,
                                count: followingCount,
                                label: 'Takip Edilen',
                                icon: Icons.person_add_alt_outlined,
                                color: Colors.tealAccent,
                                onTap: () => context.push('/user-list/following/$userId'),
                              ),
                              const SizedBox(width: 8),

                              // 3. İzlediğim Filmler
                              _buildProfileMetricCard(
                                context,
                                count: watchedMoviesCount,
                                label: 'İzlenen Film',
                                icon: Icons.movie_outlined,
                                color: Colors.amber,
                                onTap: () => context.push('/watched-list/movie/$userId'),
                              ),
                              const SizedBox(width: 8),

                              // 4. İzlediğim Diziler
                              _buildProfileMetricCard(
                                context,
                                count: watchedShowsCount,
                                label: 'İzlenen Dizi',
                                icon: Icons.tv_outlined,
                                color: Colors.deepPurpleAccent,
                                onTap: () => context.push('/watched-list/tv/$userId'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                          const Divider(height: 1),
                          const SizedBox(height: 12),

                          // BANA AİT AKIŞ BAŞLIĞI
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.dynamic_feed_rounded, size: 22, color: theme.colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    isMe ? 'Bana Ait Akış (${posts.length})' : 'Paylaşımları (${posts.length})',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, size: 20),
                                tooltip: 'Akışı Yenile',
                                onPressed: _loadProfileData,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // BANA AİT AKIŞ EKRANI (POSTLAR)
                  if (posts.isEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.movie_creation_outlined, size: 54, color: Colors.grey.shade600),
                            const SizedBox(height: 12),
                            Text(
                              isMe ? 'Henüz bir paylaşımınız yok!' : 'Bu kullanıcının henüz bir paylaşımı yok.',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isMe
                                  ? 'Film replikleri veya izlediğiniz dizi/filmler hakkında düşüncelerinizi paylaşmaya başlayın.'
                                  : 'Kullanıcının paylaşımları burada görünecektir.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13),
                            ),
                            if (isMe) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => context.go('/new-post'),
                                icon: const Icon(Icons.add),
                                label: const Text('İlk Paylaşımını Yap'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = posts[index];
                          final postId = int.tryParse(post['id'].toString()) ?? 0;
                          return PostCard(
                            key: ValueKey(postId),
                            post: post,
                            onLikeToggle: () {
                              context.read<FeedCubit>().toggleLike(postId);
                              _loadProfileData();
                            },
                            onCommentAdd: (_) {
                              final currentCount = int.tryParse(post['comments_count']?.toString() ?? '0') ?? 0;
                              setState(() {
                                post['comments_count'] = (currentCount + 1).toString();
                              });
                              context.read<ProfileCubit>().updatePostCommentCount(postId, currentCount + 1);
                              context.read<FeedCubit>().updateCommentCount(postId, currentCount + 1);
                            },
                            onPostDeleted: (deletedId) {
                              context.read<ProfileCubit>().removePostLocally(deletedId);
                              context.read<FeedCubit>().removePostLocally(deletedId);
                            },
                            onPostUpdated: (updatedPost) {
                              context.read<ProfileCubit>().updatePostLocally(updatedPost);
                              context.read<FeedCubit>().updatePostLocally(updatedPost);
                            },
                          );
                        },
                        childCount: posts.length,
                      ),
                    ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  // Tıklanabilir İstatistik Kartı Widget'ı (Movie Explorer Minimalist Tarzı)
  Widget _buildProfileMetricCard(
    BuildContext context, {
    required dynamic count,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF171922) : const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF232634) : const Color(0xFFEEEEF2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 6),
              Text(
                count.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isDark ? Colors.white : const Color(0xFF14171A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8A90A0),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
