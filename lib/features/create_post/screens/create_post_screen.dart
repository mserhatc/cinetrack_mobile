import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../feed/cubit/feed_cubit.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../cubit/create_post_cubit.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  int _selectedTab = 0; // 0: Quote, 1: Review
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quoteController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  Map<String, dynamic>? _selectedMedia;
  double _rating = 8.0;

  @override
  void dispose() {
    _searchController.dispose();
    _quoteController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onMediaSelected(Map<String, dynamic> media) {
    setState(() {
      _selectedMedia = media;
    });
    Navigator.of(context).pop();
  }

  void _showMediaSearchDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final sheetBg = isDark ? AppTheme.darkCard : Colors.white;
        final titleColor = isDark ? Colors.white : AppTheme.darkText;

        return BlocProvider.value(
          value: context.read<CreatePostCubit>(),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: BoxDecoration(
                  color: sheetBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    ShadInput(
                      controller: _searchController,
                      placeholder: const Text('Film veya dizi ara...'),
                      leading: const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.search_rounded, size: 20),
                      ),
                      trailing: GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          context.read<CreatePostCubit>().searchMedia('');
                        },
                        child: const Icon(Icons.clear, size: 18),
                      ),
                      onChanged: (val) {
                        context.read<CreatePostCubit>().searchMedia(val);
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: BlocBuilder<CreatePostCubit, CreatePostState>(
                        builder: (context, state) {
                          if (state is CreatePostSearching) {
                            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                          }
                          if (state is CreatePostSearchResults) {
                            final list = state.results;
                            if (list.isEmpty) {
                              return Center(
                                child: Text('Sonuç bulunamadı.', style: TextStyle(color: AppTheme.mutedText)),
                              );
                            }
                            return ListView.separated(
                              itemCount: list.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = list[index];
                                final title = item['title'] ?? item['name'] ?? 'İsimsiz';
                                final poster = item['poster_path'];
                                final type = item['media_type'] == 'tv' ? 'Dizi' : 'Film';
                                final year = (item['release_date'] ?? item['first_air_date'] ?? '').toString();

                                return InkWell(
                                  onTap: () => _onMediaSelected(item),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF14151C) : AppTheme.mediaCardBg,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark ? AppTheme.darkCardBorder : AppTheme.borderColor,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: poster != null
                                              ? Image.network(
                                                  AppConstants.getPosterUrl(poster),
                                                  width: 44,
                                                  height: 64,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Container(
                                                    width: 44,
                                                    height: 64,
                                                    color: AppTheme.placeholderColor,
                                                    child: const Icon(Icons.movie, color: Colors.grey),
                                                  ),
                                                )
                                              : Container(
                                                  width: 44,
                                                  height: 64,
                                                  color: AppTheme.placeholderColor,
                                                  child: const Icon(Icons.movie, color: Colors.grey),
                                                ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: titleColor),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '$type • ${year.length >= 4 ? year.substring(0, 4) : ''}',
                                                style: TextStyle(color: AppTheme.mutedText, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withValues(alpha: 0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.add, color: AppTheme.primaryColor, size: 18),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                          return Center(
                            child: Text(
                              'Aramak için bir film veya dizi adı yazın.',
                              style: TextStyle(color: AppTheme.mutedText, fontSize: 14),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _resetForm() {
    setState(() {
      _selectedMedia = null;
      _quoteController.clear();
      _contentController.clear();
      _searchController.clear();
      _rating = 8.0;
    });
  }

  Future<void> _submitPost() async {
    final authCubit = context.read<AuthCubit>();
    if (!authCubit.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce giriş yapın.')),
      );
      context.push('/login');
      return;
    }

    final isQuote = _selectedTab == 0;
    final quoteText = _quoteController.text.trim();
    final content = _contentController.text.trim();

    if (isQuote && quoteText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir replik yazın.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (!isQuote && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen düşüncelerinizi / yorumunuzu yazın.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final success = await context.read<CreatePostCubit>().createPost(
      postType: isQuote ? 'quote' : 'review',
      tmdbId: _selectedMedia != null ? int.tryParse(_selectedMedia!['id'].toString()) : null,
      mediaType: _selectedMedia != null ? (_selectedMedia!['media_type'] ?? 'movie') : 'movie',
      title: _selectedMedia != null ? (_selectedMedia!['title'] ?? _selectedMedia!['name']) : null,
      posterPath: _selectedMedia != null ? _selectedMedia!['poster_path'] : null,
      quoteText: isQuote ? quoteText : null,
      content: content.isNotEmpty ? content : (isQuote ? 'Bu repliği paylaştı.' : ''),
      rating: !isQuote ? _rating : null,
    );

    if (success && mounted) {
      _resetForm();
      context.read<FeedCubit>().fetchFeed();
      context.read<ProfileCubit>().loadProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paylaşımınız yayınlandı! ⭐'),
          backgroundColor: Color(0xFF2ECC71),
        ),
      );
      context.go('/feed');
    }
  }

  Widget _buildPill(String title, int index, bool isDark) {
    final isSelected = _selectedTab == index;
    final activeBg = isDark ? Colors.white : const Color(0xFF111111);
    final activeText = isDark ? const Color(0xFF111111) : Colors.white;
    final inactiveBorder = isDark ? AppTheme.darkCardBorder : AppTheme.inputBorderColor;
    final inactiveText = isDark ? Colors.white70 : const Color(0xFF111111);

    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isSelected ? activeBg : inactiveBorder,
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? activeText : inactiveText,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final titleColor = isDark ? Colors.white : AppTheme.darkText;
    final mutedColor = isDark ? Colors.white60 : AppTheme.mutedText;

    final loc = AppLocalizations.of(context);
    final authState = context.watch<AuthCubit>().state;

    if (authState is! Authenticated) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: titleColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Yeni Paylaşım', style: TextStyle(color: titleColor, fontWeight: FontWeight.w800)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, size: 54, color: AppTheme.primaryColor),
                const SizedBox(height: 16),
                Text(
                  loc.translate('must_login'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: titleColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.push('/login'),
                  child: Text(loc.translate('login')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: titleColor),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Yeni Paylaşım',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: titleColor, letterSpacing: -0.3),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, size: 22, color: titleColor),
            tooltip: 'Temizle',
            onPressed: _resetForm,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Kategori Hapları (.pill .pill.on: Replik Paylaş | İnceleme & Puan)
              Row(
                children: [
                  _buildPill('Replik Paylaş', 0, isDark),
                  const SizedBox(width: 8),
                  _buildPill('İnceleme & Puan', 1, isDark),
                ],
              ),
              const SizedBox(height: 18),

              // 2. Film / Dizi Seçim Alanı (.in style="border-style:dashed")
              if (_selectedMedia == null)
                InkWell(
                  onTap: _showMediaSearchDialog,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF14151C) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppTheme.darkCardBorder : AppTheme.inputBorderColor,
                        width: 1,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.movie_creation_outlined, color: mutedColor, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Film veya Dizi Seç (İsteğe Bağlı)',
                          style: TextStyle(
                            fontSize: 14,
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF14151C) : AppTheme.mediaCardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryColor, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          AppConstants.getPosterUrl(_selectedMedia!['poster_path']),
                          width: 44,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 44,
                            height: 64,
                            color: AppTheme.placeholderColor,
                            child: const Icon(Icons.movie, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedMedia!['title'] ?? _selectedMedia!['name'] ?? '',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: titleColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedMedia!['media_type'] == 'tv' ? 'Dizi' : 'Film',
                              style: TextStyle(color: mutedColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                        onPressed: () => setState(() => _selectedMedia = null),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 18),

              // 3. Form Alanları (.l ve .in)
              if (_selectedTab == 0) ...[
                // Replik Metni
                Text(
                  'Replik Metni',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: titleColor),
                ),
                const SizedBox(height: 6),
                ShadInput(
                  controller: _quoteController,
                  maxLines: 4,
                  placeholder: const Text('Unutulmaz bir film repliği yazın…'),
                ),
                const SizedBox(height: 14),

                // Kişisel Notunuz
                Text(
                  'Kişisel Notunuz',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: titleColor),
                ),
                const SizedBox(height: 6),
                ShadInput(
                  controller: _contentController,
                  maxLines: 3,
                  placeholder: const Text('Sahne veya karakter hakkında notunuz…'),
                ),
              ] else ...[
                // Puan Seçici
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Puanınız',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: titleColor),
                    ),
                    Text(
                      '${_rating.toStringAsFixed(1)} / 10',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Slider(
                  value: _rating,
                  min: 1.0,
                  max: 10.0,
                  divisions: 18,
                  activeColor: AppTheme.primaryColor,
                  label: _rating.toStringAsFixed(1),
                  onChanged: (val) => setState(() => _rating = val),
                ),
                const SizedBox(height: 10),

                // İnceleme & Eleştiri
                Text(
                  'İnceleme & Düşünceleriniz',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: titleColor),
                ),
                const SizedBox(height: 6),
                ShadInput(
                  controller: _contentController,
                  maxLines: 4,
                  placeholder: const Text('Film hakkındaki detaylı düşünceleriniz ve eleştiriniz…'),
                ),
              ],

              const SizedBox(height: 28),

              // 4. Yayınla Butonu (.am style)
              BlocBuilder<CreatePostCubit, CreatePostState>(
                builder: (context, state) {
                  final isSubmitting = state is CreatePostSubmitting;
                  return SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ShadButton(
                      onPressed: isSubmitting ? null : _submitPost,
                      backgroundColor: AppTheme.primaryColor,
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Yayınla',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
