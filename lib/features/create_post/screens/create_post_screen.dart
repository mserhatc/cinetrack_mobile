import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
  int _selectedTab = 0; // 0: Quote (Replik Paylaş), 1: Review (İnceleme & Puan)
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quoteController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  Map<String, dynamic>? _selectedMedia;
  double _rating = 8.5;

  @override
  void initState() {
    super.initState();
    _quoteController.addListener(() {
      if (mounted) setState(() {});
    });
  }

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
                    TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Film veya dizi ara...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            context.read<CreatePostCubit>().searchMedia('');
                          },
                        ),
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
                            return const Center(
                              child: CircularProgressIndicator(color: AppTheme.primaryColor),
                            );
                          }
                          if (state is CreatePostSearchResults) {
                            final list = state.results;
                            if (list.isEmpty) {
                              return const Center(
                                child: Text(
                                  'Sonuç bulunamadı.',
                                  style: TextStyle(color: AppTheme.mutedText),
                                ),
                              );
                            }
                            return ListView.separated(
                              itemCount: list.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = list[index];
                                final title = item['title'] ?? item['name'] ?? 'İsimsiz';
                                final poster = item['poster_path'];
                                final type = item['media_type'] == 'tv' ? 'Dizi' : 'Film';
                                final year =
                                    (item['release_date'] ?? item['first_air_date'] ?? '').toString();

                                return InkWell(
                                  onTap: () => _onMediaSelected(item),
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF14151C) : AppTheme.mediaCardBg,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: poster != null
                                              ? Image.network(
                                                  AppConstants.getPosterUrl(poster),
                                                  width: 46,
                                                  height: 64,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) => Container(
                                                    width: 46,
                                                    height: 64,
                                                    color: AppTheme.placeholderColor,
                                                    child: const Icon(Icons.movie, color: Colors.grey),
                                                  ),
                                                )
                                              : Container(
                                                  width: 46,
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
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                  color: titleColor,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '$type · ${year.length >= 4 ? year.substring(0, 4) : ''}',
                                                style: const TextStyle(
                                                  color: AppTheme.mutedText,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withValues(alpha: 0.14),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            color: AppTheme.primaryColor,
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                          return const Center(
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
      _rating = 8.5;
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
        const SnackBar(
          content: Text('Lütfen düşüncelerinizi / yorumunuzu yazın.'),
          backgroundColor: Colors.redAccent,
        ),
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
          backgroundColor: Color(0xFF16A34A),
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
    final boxBg = isDark ? AppTheme.darkCard : AppTheme.softGreyBg;

    final loc = AppLocalizations.of(context);
    final authState = context.watch<AuthCubit>().state;

    if (authState is! Authenticated) {
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: boxBg,
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: titleColor),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Yeni Paylaşım',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 54, color: AppTheme.primaryColor),
                        const SizedBox(height: 16),
                        Text(
                          loc.translate('must_login'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                          ),
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
              ),
            ],
          ),
        ),
      );
    }

    final selectedTitle =
        _selectedMedia != null ? (_selectedMedia!['title'] ?? _selectedMedia!['name'] ?? '') : 'Apollo 13';
    final selectedRelease = _selectedMedia != null
        ? (_selectedMedia!['release_date'] ?? _selectedMedia!['first_air_date'] ?? '1995').toString()
        : '1995';
    final selectedYear =
        selectedRelease.length >= 4 ? selectedRelease.substring(0, 4) : '1995';
    final selectedType =
        _selectedMedia != null && _selectedMedia!['media_type'] == 'tv' ? 'Dizi' : 'Film';
    final selectedPoster = _selectedMedia?['poster_path'];

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Üst Çubuk: Sol Yuvarlak "<" Butonu ve Ortalanmış "Yeni Paylaşım" (PDF Page 5)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: boxBg,
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: titleColor),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Yeni Paylaşım',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),

            // 2. Kaydırılabilir Form İçeriği
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Segmented Toggle: Replik Paylaş | İnceleme & Puan (PDF Page 5)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: boxBg,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedTab = 0),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 0
                                      ? (isDark ? AppTheme.primaryColor : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(26),
                                  boxShadow: _selectedTab == 0
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
                                  'Replik Paylaş',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: _selectedTab == 0 ? FontWeight.w800 : FontWeight.w600,
                                    color: _selectedTab == 0 ? titleColor : mutedColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedTab = 1),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 1
                                      ? (isDark ? AppTheme.primaryColor : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(26),
                                  boxShadow: _selectedTab == 1
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
                                  'İnceleme & Puan',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: _selectedTab == 1 ? FontWeight.w800 : FontWeight.w600,
                                    color: _selectedTab == 1 ? titleColor : mutedColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seçili Film / Dizi Kartı (Turuncu Çerçeveli Kutu - PDF Page 5)
                    GestureDetector(
                      onTap: _showMediaSearchDialog,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppTheme.primaryColor, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: selectedPoster != null
                                    ? Image.network(
                                        AppConstants.getPosterUrl(selectedPoster.toString()),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedMedia != null
                                        ? selectedTitle.toString()
                                        : 'Apollo 13 (Değiştirmek için dokun)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: titleColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$selectedType · $selectedYear',
                                    style: TextStyle(color: mutedColor, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if (_selectedMedia != null) {
                                  setState(() => _selectedMedia = null);
                                } else {
                                  _showMediaSearchDialog();
                                }
                              },
                              icon: Icon(Icons.close_rounded, color: mutedColor, size: 22),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    if (_selectedTab == 0) ...[
                      // Replik Metni Başlığı
                      Text(
                        'Replik Metni',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Replik Metni Gri Kutu + Amber Tırnak İşareti + 0/280 Sayacı (PDF Page 5)
                      Container(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                        decoration: BoxDecoration(
                          color: boxBg,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '“',
                              style: TextStyle(
                                fontSize: 40,
                                height: 0.9,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            TextField(
                              controller: _quoteController,
                              maxLines: 4,
                              maxLength: 280,
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: titleColor,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Unutulmaz bir film repliği yazın...',
                                hintStyle: TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color: mutedColor,
                                ),
                                counterText: '',
                                filled: false,
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                '${_quoteController.text.length} / 280',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: mutedColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Kişisel Notunuz Başlığı
                      Text(
                        'Kişisel Notunuz',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                        decoration: BoxDecoration(
                          color: boxBg,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: TextField(
                          controller: _contentController,
                          maxLines: 3,
                          style: TextStyle(fontSize: 15, color: titleColor),
                          decoration: InputDecoration(
                            hintText: 'Sahne veya karakter hakkında...',
                            hintStyle: TextStyle(fontSize: 15, color: mutedColor),
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                    ] else ...[
                      // Puan Seçici
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Puanınız',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                            ),
                          ),
                          Text(
                            '${_rating.toStringAsFixed(1)} / 10',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _rating,
                        min: 1.0,
                        max: 10.0,
                        divisions: 18,
                        activeColor: AppTheme.primaryColor,
                        label: _rating.toStringAsFixed(1),
                        onChanged: (val) => setState(() => _rating = val),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'İnceleme & Yorumunuz',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: boxBg,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: TextField(
                          controller: _contentController,
                          maxLines: 5,
                          style: TextStyle(fontSize: 15, color: titleColor),
                          decoration: InputDecoration(
                            hintText: 'Film hakkındaki detaylı düşünceleriniz...',
                            hintStyle: TextStyle(fontSize: 15, color: mutedColor),
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // 3. Alt Sabit "Yayınla" Butonu (PDF Page 5)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: BlocBuilder<CreatePostCubit, CreatePostState>(
                builder: (context, state) {
                  final isSubmitting = state is CreatePostSubmitting;
                  return GestureDetector(
                    onTap: isSubmitting ? null : _submitPost,
                    child: Container(
                      height: 56,
                      width: double.infinity,
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
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                'Yayınla',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
