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
                                      color: isDark ? const Color(0xFF13151D) : const Color(0xFFF7F8FA),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark ? AppTheme.darkCardBorder : AppTheme.borderColor,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: poster != null
                                              ? Image.network(
                                                  AppConstants.getPosterUrl(poster),
                                                  width: 48,
                                                  height: 68,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  width: 48,
                                                  height: 68,
                                                  color: Colors.grey.shade300,
                                                  child: const Icon(Icons.movie, size: 24, color: Colors.grey),
                                                ),
                                        ),
                                        const SizedBox(width: 14),
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
                                            color: AppTheme.primaryColor.withOpacity(0.12),
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: titleColor, letterSpacing: -0.3),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, size: 22, color: titleColor),
            tooltip: 'Temizle',
            onPressed: _resetForm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Movie Explorer Tarzı Kategori Hapları (Replik Paylaş / İnceleme Yaz)
            Row(
              children: [
                _buildTabChip('Replik Paylaş', 0, _selectedTab == 0, isDark),
                const SizedBox(width: 8),
                _buildTabChip('İnceleme & Puan', 1, _selectedTab == 1, isDark),
              ],
            ),
            const SizedBox(height: 20),

            // Seçilen Film / Dizi Kutusu veya Ekleme Butonu
            if (_selectedMedia == null)
              InkWell(
                onTap: _showMediaSearchDialog,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppTheme.darkCardBorder : AppTheme.borderColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.movie_creation_outlined, color: AppTheme.primaryColor, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Film veya Dizi Seç (İsteğe Bağlı)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5), width: 1.5),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        AppConstants.getPosterUrl(_selectedMedia!['poster_path']),
                        width: 48,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedMedia!['title'] ?? _selectedMedia!['name'] ?? '',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: titleColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedMedia!['media_type'] == 'tv' ? 'Dizi' : 'Film',
                            style: TextStyle(color: mutedColor, fontSize: 13),
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

            const SizedBox(height: 20),

            // Replik mi İnceleme mi?
            if (_selectedTab == 0) ...[
              ShadInput(
                controller: _quoteController,
                maxLines: 3,
                placeholder: const Text('Unutulmaz bir film repliği yazın...'),
                leading: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.format_quote_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              ShadInput(
                controller: _contentController,
                maxLines: 2,
                placeholder: const Text('Sahne veya karakter hakkında notunuz (isteğe bağlı)...'),
                leading: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.edit_note_rounded, size: 20),
                ),
              ),
            ] else ...[
              // Puan Seçici (Amber)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppTheme.darkCardBorder : AppTheme.borderColor,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Puanınız:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: titleColor)),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: AppTheme.starColor, size: 22),
                            const SizedBox(width: 4),
                            Text(
                              '$_rating / 10',
                              style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.starColor, fontSize: 17),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _rating,
                      min: 1.0,
                      max: 10.0,
                      divisions: 18,
                      activeColor: AppTheme.primaryColor,
                      label: '$_rating',
                      onChanged: (val) => setState(() => _rating = (val * 2).round() / 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ShadInput(
                controller: _contentController,
                maxLines: 4,
                placeholder: const Text('Film hakkındaki detaylı düşünceleriniz ve eleştiriniz...'),
                leading: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.rate_review_outlined, size: 20),
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Paylaş Butonu (ShadButton)
            BlocBuilder<CreatePostCubit, CreatePostState>(
              builder: (context, state) {
                final isSubmitting = state is CreatePostSubmitting;
                return SizedBox(
                  height: 52,
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
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(String title, int index, bool isSelected, bool isDark) {
    if (isSelected) {
      return ShadButton(
        onPressed: () => setState(() => _selectedTab = index),
        backgroundColor: isDark ? Colors.white : AppTheme.darkText,
        foregroundColor: isDark ? AppTheme.darkBg : Colors.white,
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      );
    }
    return ShadButton.outline(
      onPressed: () => setState(() => _selectedTab = index),
      child: Text(title, style: TextStyle(color: isDark ? Colors.white70 : AppTheme.mutedText)),
    );
  }
}
