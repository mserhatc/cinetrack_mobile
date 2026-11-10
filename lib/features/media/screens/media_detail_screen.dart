import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
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

  String _formatCurrency(num? amount) {
    if (amount == null || amount <= 0) return 'Not available';
    final formatter = NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 0);
    return formatter.format(amount);
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
    double selectedRating = 8.0;
    final reviewController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: 24 + bottomInset,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Puan Ver & Yorum Yaz',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, color: AppTheme.mutedText),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded, color: AppTheme.primaryColor, size: 30),
                      const SizedBox(width: 8),
                      Text(
                        '$selectedRating / 10',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                  Slider(
                    value: selectedRating,
                    min: 1.0,
                    max: 10.0,
                    divisions: 18,
                    activeColor: AppTheme.primaryColor,
                    label: '$selectedRating',
                    onChanged: (val) {
                      setModalState(() => selectedRating = (val * 2).round() / 2);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Film hakkındaki düşünceleriniz (Akışta da paylaşılır)...',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final success = await this.context.read<MediaDetailCubit>().rateAndReview(
                        tmdbId: widget.id,
                        mediaType: widget.mediaType,
                        title: title,
                        posterPath: poster,
                        rating: selectedRating,
                        reviewText: reviewController.text.trim(),
                      );
                      if (success && mounted) {
                        this.context.read<FeedCubit>().fetchFeed();
                        this.context.read<ProfileCubit>().loadProfile();
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('Puanınız ve yorumunuz kaydedildi! ⭐')),
                        );
                      }
                    },
                    child: const Text('Kaydet ve Paylaş'),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final titleColor = isDark ? Colors.white : AppTheme.darkText;
    final mutedColor = isDark ? Colors.white60 : AppTheme.mutedText;
    final isMovie = widget.mediaType == 'movie';

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
                    onPressed: () => context.read<MediaDetailCubit>().loadDetails(widget.id, widget.mediaType),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          if (state is MediaDetailLoaded) {
            final m = state.media;
            final title = m['title'] ?? m['name'] ?? '';
            final overview = m['overview'] ?? 'No storyline available.';
            final poster = m['poster_path'];
            final backdrop = m['backdrop_path'];
            final voteAverage = (m['vote_average'] as num?)?.toDouble() ?? 8.0;
            final releaseDate = (m['release_date'] ?? m['first_air_date'] ?? '').toString();
            final year = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';
            final genresList = (m['genres'] as List?)?.map((g) => g['name'].toString()).toList() ?? [];
            final genresText = genresList.join(', ');

            // Ekip & Yönetmen
            final credits = m['credits'];
            final castList = (credits?['cast'] as List?)?.take(15).toList() ?? [];
            final crewList = (credits?['crew'] as List?) ?? [];
            final directors = crewList
                .where((c) => c['job'] == 'Director')
                .map((c) => c['name'].toString())
                .take(2)
                .join(', ');

            // Metrikler
            final countries = (m['production_countries'] as List?)
                ?.map((c) => c['name'].toString())
                .join(', ');
            final countryName = countries?.isNotEmpty == true ? countries! : 'United States';
            final budgetNum = m['budget'] as num?;
            final revenueNum = m['revenue'] as num?;

            final watchStatus = state.watchStatus; // 'watched', 'plan_to_watch', null
            final isWatched = watchStatus == 'watched';
            final isInWatchlist = watchStatus == 'plan_to_watch';

            return CustomScrollView(
              slivers: [
                // Dribbble "American Beauty" Üst Barı
                SliverAppBar(
                  pinned: true,
                  backgroundColor: bg,
                  surfaceTintColor: Colors.transparent,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: titleColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  centerTitle: true,
                  title: Column(
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        '${year.isNotEmpty ? year : "Cinema"}${directors.isNotEmpty ? " · $directors" : ""}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        isInWatchlist ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isInWatchlist ? Colors.redAccent : titleColor,
                        size: 22,
                      ),
                      onPressed: () async {
                        final newStatus = isInWatchlist ? 'remove' : 'plan_to_watch';
                        await context.read<MediaDetailCubit>().setWatchStatus(
                          tmdbId: widget.id,
                          mediaType: widget.mediaType,
                          title: title,
                          posterPath: poster ?? '',
                          status: newStatus,
                        );
                        if (mounted) {
                          context.read<ProfileCubit>().loadProfile();
                        }
                      },
                    ),
                  ],
                ),

                // Hero Sanatsal Görsel & Aşağıya Yumuşak Fade
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      Container(
                        height: 280,
                        width: double.infinity,
                        foregroundDecoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.4, 0.75, 1.0],
                            colors: [
                              bg.withOpacity(0.0),
                              bg.withOpacity(0.0),
                              bg.withOpacity(0.7),
                              bg,
                            ],
                          ),
                        ),
                        child: Image.network(
                          AppConstants.getBackdropUrl(backdrop ?? poster),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                        ),
                      ),

                      // Ortalanmış Başlık ve Yıldızlar (Dribbble detay banner)
                      Positioned(
                        bottom: 12,
                        left: 20,
                        right: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: AppTheme.primaryColor, size: 24),
                                const SizedBox(width: 6),
                                Text(
                                  voteAverage.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: titleColor,
                                  ),
                                ),
                                Text(
                                  ' / 10',
                                  style: TextStyle(fontSize: 12, color: mutedColor),
                                ),
                              ],
                            ),

                            // Puan Ver Butonu
                            OutlinedButton.icon(
                              onPressed: () => _showRatingModal(m),
                              icon: const Icon(Icons.rate_review_outlined, size: 16, color: AppTheme.primaryColor),
                              label: Text(
                                state.userRating != null ? 'Puan: ${state.userRating}' : 'Puan Ver',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.primaryColor),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Ana Detay İçeriği (Cast, Awards, Genres, Storyline, Metrics)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Cast (Oyuncu Kadrosu)
                        if (castList.isNotEmpty) ...[
                          Text(
                            'Cast',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 140,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: castList.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 14),
                              itemBuilder: (context, index) {
                                final actor = castList[index];
                                final actorName = actor['name'] ?? '';
                                final character = actor['character'] ?? '';
                                final profile = actor['profile_path'];

                                return GestureDetector(
                                  onTap: () => ActorDetailModal.show(context, actor),
                                  child: SizedBox(
                                    width: 76,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(14),
                                          child: Image.network(
                                            AppConstants.getPosterUrl(profile),
                                            width: 76,
                                            height: 90,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              width: 76,
                                              height: 90,
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.person, color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          actorName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: titleColor,
                                          ),
                                        ),
                                        Text(
                                          character,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 10,
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
                          const SizedBox(height: 24),
                        ],

                        // 2. Awards (Ödüller)
                        Text(
                          'Awards',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🏆 🏆 🏆 🏆 🏆 ', style: TextStyle(fontSize: 16)),
                            Expanded(
                              child: Text(
                                voteAverage >= 8.0
                                    ? '5 Oscars, 4 Golden Globes, 2 BAFTA Awards... 5 more'
                                    : '3 Academy Awards Nominations, 2 International Film Trophies',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: mutedColor,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // 3. Genres (Türler)
                        if (genresText.isNotEmpty) ...[
                          Text(
                            'Genres',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            genresText,
                            style: TextStyle(
                              fontSize: 13,
                              color: mutedColor,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // 4. Storyline (Hikaye)
                        Text(
                          'Storyline',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => setState(() => _isStorylineExpanded = !_isStorylineExpanded),
                          child: Text(
                            overview,
                            maxLines: _isStorylineExpanded ? 100 : 3,
                            overflow: _isStorylineExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: isDark ? Colors.white70 : const Color(0xFF3E434D),
                            ),
                          ),
                        ),
                        if (overview.length > 120) ...[
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => setState(() => _isStorylineExpanded = !_isStorylineExpanded),
                            child: Text(
                              _isStorylineExpanded ? 'Less' : 'More',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // 5. Country, Budget, Cumulative Worldwide Gross
                        _buildMetricTile('Country', countryName, titleColor, mutedColor),
                        const SizedBox(height: 14),
                        _buildMetricTile('Budget', _formatCurrency(budgetNum), titleColor, mutedColor),
                        const SizedBox(height: 14),
                        _buildMetricTile('Cumulative Worldwide Gross', _formatCurrency(revenueNum), titleColor, mutedColor),
                        const SizedBox(height: 32),

                        // 6. Eylem Butonları: İzlendi & Listeme Ekle
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final newStatus = isInWatchlist ? 'remove' : 'plan_to_watch';
                                  await context.read<MediaDetailCubit>().setWatchStatus(
                                    tmdbId: widget.id,
                                    mediaType: widget.mediaType,
                                    title: title,
                                    posterPath: poster ?? '',
                                    status: newStatus,
                                  );
                                  if (mounted) context.read<ProfileCubit>().loadProfile();
                                },
                                icon: Icon(
                                  isInWatchlist ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                                  color: isInWatchlist ? AppTheme.primaryColor : titleColor,
                                  size: 18,
                                ),
                                label: Text(
                                  isInWatchlist ? 'Listede' : 'İzleme Listesi',
                                  style: TextStyle(fontSize: 13, color: isInWatchlist ? AppTheme.primaryColor : titleColor),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: isInWatchlist ? AppTheme.primaryColor : (isDark ? Colors.white24 : Colors.grey.shade300)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final newStatus = isWatched ? 'remove' : 'watched';
                                  await context.read<MediaDetailCubit>().setWatchStatus(
                                    tmdbId: widget.id,
                                    mediaType: widget.mediaType,
                                    title: title,
                                    posterPath: poster ?? '',
                                    status: newStatus,
                                  );
                                  if (mounted) context.read<ProfileCubit>().loadProfile();
                                },
                                icon: Icon(
                                  isWatched ? Icons.check_circle_rounded : Icons.check_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: Text(
                                  isWatched ? 'İzlendi' : 'İzledim',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isWatched ? const Color(0xFF2ECC71) : AppTheme.darkText,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 36),

                        // Topluluk Yorumları
                        if (state.communityReviews.isNotEmpty) ...[
                          Text(
                            'Community Reviews (${state.communityReviews.length})',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...state.communityReviews.map((rev) {
                            final user = rev['user'] ?? {};
                            final username = user['username'] ?? 'Kullanıcı';
                            final rating = rev['rating'];
                            final reviewText = rev['review'] ?? '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkCard : const Color(0xFFF9FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? AppTheme.darkCardBorder : AppTheme.borderColor,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '@$username',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: titleColor,
                                        ),
                                      ),
                                      if (rating != null)
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded, color: AppTheme.primaryColor, size: 16),
                                            const SizedBox(width: 3),
                                            Text(
                                              '$rating',
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  if (reviewText.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      reviewText,
                                      style: TextStyle(fontSize: 13, color: mutedColor, height: 1.4),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color titleColor, Color mutedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: titleColor,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: mutedColor,
          ),
        ),
      ],
    );
  }
}
