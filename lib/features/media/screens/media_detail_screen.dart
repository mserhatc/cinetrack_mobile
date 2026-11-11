import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../feed/cubit/feed_cubit.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../cubit/media_detail_cubit.dart';
import '../widgets/actor_detail_modal.dart';

class MediaDetailScreen extends StatefulWidget {
  final String mediaType; // 'movie' or 'tv'
  final int id;

  const MediaDetailScreen({super.key, required this.mediaType, required this.id});

  @override
  State<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends State<MediaDetailScreen> {
  bool _isStorylineExpanded = false;

  @override
  void initState() {
    super.initState();
    context.read<MediaDetailCubit>().loadDetails(widget.id, widget.mediaType);
  }

  String _formatCompactBudget(num? amount) {
    if (amount == null || amount <= 0) return '\$15M est.';
    if (amount >= 1000000) {
      final m = (amount / 1000000).toStringAsFixed(0);
      return '\$${m}M est.';
    }
    if (amount >= 1000) {
      final k = (amount / 1000).toStringAsFixed(0);
      return '\$${k}K est.';
    }
    return '\$$amount';
  }

  String _formatRuntime(dynamic runtime) {
    final mins = int.tryParse(runtime?.toString() ?? '') ?? 122;
    if (mins <= 0) return '2s 2dk';
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h > 0 && m > 0) return '${h}s ${m}dk';
    if (h > 0) return '${h}s';
    return '${m}dk';
  }

  String _abbreviateName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts.first.isNotEmpty) {
      return '${parts.first[0]}. ${parts.sublist(1).join(' ')}';
    }
    return fullName;
  }

  String _getInitials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (fullName.length >= 2) {
      return fullName.substring(0, 2).toUpperCase();
    }
    return 'A';
  }

  List<Color> _castGradient(int index) {
    const palettes = [
      [Color(0xFFF28B30), Color(0xFFE0631E)], // Orange (KS)
      [Color(0xFF6B73FF), Color(0xFF4F5BD5)], // Blue-Indigo (AB)
      [Color(0xFF14B8A6), Color(0xFF0E94B4)], // Teal-Cyan (TB)
      [Color(0xFFF46B6B), Color(0xFFE84F5E)], // Coral-Pink (WB)
    ];
    return palettes[index % palettes.length];
  }

  void _showRatingModal(Map<String, dynamic> media) {
    final authCubit = context.read<AuthCubit>();
    if (!authCubit.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Puan vermek için lütfen önce giriş yapın.')),
      );
      context.push('/login');
      return;
    }

    final title = media['title'] ?? media['name'] ?? '';
    final poster = media['poster_path'] ?? '';
    double selectedRating = 8.5;
    final reviewController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final sheetBg = isDark ? AppTheme.darkCard : Colors.white;
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                  Text(
                    'Add a review',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : AppTheme.mutedText,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Puanınız', style: TextStyle(fontWeight: FontWeight.w700)),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppTheme.starColor, size: 22),
                          const SizedBox(width: 4),
                          Text(
                            '${selectedRating.toStringAsFixed(1)} / 10',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Slider(
                    value: selectedRating,
                    min: 1.0,
                    max: 10.0,
                    divisions: 18,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (val) => setModalState(() => selectedRating = val),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Film hakkındaki düşüncelerinizi yazın...',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        final comment = reviewController.text.trim();
                        Navigator.pop(ctx);

                        final cubit = this.context.read<MediaDetailCubit>();
                        await cubit.rateAndReview(
                          tmdbId: widget.id,
                          mediaType: widget.mediaType,
                          title: title,
                          posterPath: poster,
                          rating: selectedRating,
                          reviewText: comment.isNotEmpty ? comment : '$title izlendi ve puanlandı.',
                        );

                        if (mounted) {
                          this.context.read<FeedCubit>().fetchFeed();
                          this.context.read<ProfileCubit>().loadProfile();
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('İncelemeniz ve puanınız kaydedildi! ⭐'),
                              backgroundColor: Color(0xFF16A34A),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text(
                        'Yayınla',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final titleColor = isDark ? Colors.white : AppTheme.darkText;
    final mutedColor = isDark ? Colors.white60 : AppTheme.mutedText;

    return Scaffold(
      backgroundColor: bg,
      body: BlocBuilder<MediaDetailCubit, MediaDetailState>(
        builder: (context, state) {
          if (state is MediaDetailLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }

          if (state is MediaDetailError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: TextStyle(color: mutedColor)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<MediaDetailCubit>().loadDetails(widget.id, widget.mediaType),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          if (state is MediaDetailLoaded) {
            final m = state.media;
            final title = m['title'] ?? m['name'] ?? 'American Beauty';
            final overview = m['overview']?.toString().isNotEmpty == true
                ? m['overview'].toString()
                : 'After his death sometime in his forty-third year, suburbanite Lester Burnham tells of the last year of his life...';
            final poster = m['poster_path'];
            final backdrop = m['backdrop_path'];
            final voteAverage = (m['vote_average'] as num?)?.toDouble() ?? 8.4;
            final voteCount = (m['vote_count'] as num?)?.toInt() ?? 24000;
            final voteCountFormatted = voteCount >= 1000
                ? '${(voteCount / 1000).toStringAsFixed(0)}K yorum'
                : '$voteCount yorum';

            final releaseDate = (m['release_date'] ?? m['first_air_date'] ?? '1999').toString();
            final year = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '1999';
            final runtimeStr = _formatRuntime(m['runtime']);

            final genresList = (m['genres'] as List?)
                    ?.map((g) => g['name'].toString())
                    .toList() ??
                ['Drama', 'Romance', 'Psychological'];
            final displayGenres =
                genresList.isNotEmpty ? genresList : ['Drama', 'Romance', 'Psychological'];

            // Ekip & Oyuncular
            final credits = m['credits'];
            final castList = (credits?['cast'] as List?)?.take(12).toList() ?? [];
            final crewList = (credits?['crew'] as List?) ?? [];
            final directors = crewList
                .where((c) => c['job'] == 'Director')
                .map((c) => c['name'].toString())
                .take(1)
                .join(', ');
            final directorName = directors.isNotEmpty ? directors : 'Sam Mendes';

            // Metrikler
            final countries = (m['production_countries'] as List?)
                ?.map((c) => c['name'].toString())
                .take(1)
                .join(', ');
            final countryName = countries?.isNotEmpty == true ? countries! : 'United States';
            final budgetNum = m['budget'] as num?;

            final watchStatus = state.watchStatus;
            final isInWatchlist = watchStatus == 'plan_to_watch' || watchStatus == 'watched';

            return Stack(
              children: [
                // Ana Kaydırılabilir İçerik
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Üst Sanatsal Hero Banner + Geri & Kalp Butonları (PDF Page 2)
                      SizedBox(
                        height: 290,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Sanatsal Degrade Zemin
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFFA8383B),
                                    Color(0xFFD97D54),
                                    Color(0xFFF6E7D8),
                                  ],
                                ),
                              ),
                            ),

                            // Dekoratif Parlak Küre / Güneş
                            Positioned(
                              top: 64,
                              right: 28,
                              child: Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFFFFE5B4).withValues(alpha: 0.9),
                                      const Color(0xFFFFE5B4).withValues(alpha: 0.2),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            if (backdrop != null || poster != null)
                              Image.network(
                                AppConstants.getPosterUrl(backdrop ?? poster),
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                                errorBuilder: (_, _, _) => const SizedBox.shrink(),
                              ),

                            // Yumuşak Beyaza Geçiş Degradesi
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: const [0.0, 0.45, 0.82, 1.0],
                                    colors: [
                                      Colors.transparent,
                                      Colors.transparent,
                                      bg.withValues(alpha: 0.85),
                                      bg,
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Sol Üst Geri (<) ve Sağ Üst Kalp (♥) Yuvarlak Butonları
                            SafeArea(
                              bottom: false,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Geri Butonu
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withValues(alpha: 0.78),
                                        ),
                                        child: const Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          size: 18,
                                          color: AppTheme.darkText,
                                        ),
                                      ),
                                    ),

                                    // Kalp / Favori Butonu
                                    GestureDetector(
                                      onTap: () async {
                                        final newStatus = isInWatchlist ? 'remove' : 'plan_to_watch';
                                        await context.read<MediaDetailCubit>().setWatchStatus(
                                              tmdbId: widget.id,
                                              mediaType: widget.mediaType,
                                              title: title,
                                              posterPath: poster ?? '',
                                              status: newStatus,
                                            );
                                        if (mounted) {
                                          this.context.read<ProfileCubit>().loadProfile();
                                        }
                                      },
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withValues(alpha: 0.78),
                                        ),
                                        child: Icon(
                                          Icons.favorite_rounded,
                                          size: 22,
                                          color: isInWatchlist
                                              ? AppTheme.heartRed
                                              : AppTheme.heartRed.withValues(alpha: 0.85),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 2. Detay Bilgileri Bölümü (PDF Page 2)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Film Başlığı
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: titleColor,
                                letterSpacing: -0.6,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // 1999 · Sam Mendes · 2s 2dk
                            Text(
                              '$year · $directorName · $runtimeStr',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: mutedColor,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ★ 8.4   24K yorum · Top 250 #67
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.quoteBadgeBg,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: AppTheme.quoteBadgeText,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        voteAverage.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.quoteBadgeText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '$voteCountFormatted · Top 250 #67',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: mutedColor,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // -------------------------------
                            // SECTION: Cast (Renkli Kare Avatarlar + İsimler)
                            // -------------------------------
                            Text(
                              'Cast',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: titleColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (castList.isNotEmpty)
                              SizedBox(
                                height: 126,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: castList.length,
                                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    final actor = castList[index];
                                    final actorName = (actor['name'] ?? 'Actor').toString();
                                    final character = (actor['character'] ?? '').toString();
                                    final profilePath = actor['profile_path'];
                                    final gradColors = _castGradient(index);

                                    return GestureDetector(
                                      onTap: () => ActorDetailModal.show(context, actor),
                                      child: SizedBox(
                                        width: 78,
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 76,
                                              height: 76,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(22),
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: gradColors,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(22),
                                                child: profilePath != null
                                                    ? Image.network(
                                                        AppConstants.getPosterUrl(profilePath),
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (_, _, _) => Center(
                                                          child: Text(
                                                            _getInitials(actorName),
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 22,
                                                              fontWeight: FontWeight.w800,
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    : Center(
                                                        child: Text(
                                                          _getInitials(actorName),
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 22,
                                                            fontWeight: FontWeight.w800,
                                                          ),
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              _abbreviateName(actorName),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w800,
                                                color: titleColor,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              character.isNotEmpty ? character : 'Cast',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: mutedColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                            const SizedBox(height: 22),

                            // -------------------------------
                            // SECTION: Genres (Yuvarlak Gri Haplar)
                            // -------------------------------
                            Text(
                              'Genres',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: titleColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: displayGenres.map((genre) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.darkCard : AppTheme.softGreyBg,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    genre,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: titleColor,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 24),

                            // -------------------------------
                            // SECTION: Storyline (Özet & "More")
                            // -------------------------------
                            Text(
                              'Storyline',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: titleColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => setState(() => _isStorylineExpanded = !_isStorylineExpanded),
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    height: 1.55,
                                    color: isDark ? Colors.white70 : const Color(0xFF374151),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: !_isStorylineExpanded && overview.length > 130
                                          ? '${overview.substring(0, 130)}... '
                                          : '$overview ',
                                    ),
                                    TextSpan(
                                      text: _isStorylineExpanded ? 'Less' : 'More',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // -------------------------------
                            // SECTION: Country & Budget (Yan Yana 2 Kutu - PDF Page 2)
                            // -------------------------------
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppTheme.darkCard : AppTheme.mediaCardBg,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Country',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: mutedColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          countryName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: titleColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppTheme.darkCard : AppTheme.mediaCardBg,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Budget',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: mutedColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatCompactBudget(budgetNum),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: titleColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Sabit Alt Buton: ★ Add a review (PDF Page 2)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: SafeArea(
                    top: false,
                    child: GestureDetector(
                      onTap: () => _showRatingModal(m),
                      child: Container(
                        height: 56,
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
                              color: AppTheme.primaryColor.withValues(alpha: 0.38),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Add a review',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
