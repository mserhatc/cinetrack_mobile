import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      fontSize: 14,
                      color: isDark ? Colors.white70 : AppTheme.mutedText,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Yıldız Seçici
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = (index + 1) * 2.0;
                      final isSelected = selectedRating >= starValue;
                      return IconButton(
                        icon: Icon(
                          isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: isSelected ? AppTheme.starColor : Colors.grey.shade300,
                          size: 36,
                        ),
                        onPressed: () {
                          setModalState(() => selectedRating = starValue);
                        },
                      );
                    }),
                  ),
                  Center(
                    child: Text(
                      '${selectedRating.toStringAsFixed(1)} / 10',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.starColor),
                    ),
                  ),
                  const SizedBox(height: 16),

                  ShadInput(
                    controller: reviewController,
                    maxLines: 4,
                    placeholder: const Text('Film hakkındaki düşünceleriniz...'),
                  ),
                  const SizedBox(height: 20),

                  ShadButton(
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
                          const SnackBar(content: Text('Yorumunuz kaydedildi! ⭐')),
                        );
                      }
                    },
                    backgroundColor: AppTheme.primaryColor,
                    child: const Text('Send Review', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
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
            final voteAverage = (m['vote_average'] as num?)?.toDouble() ?? 8.0;
            final releaseDate = (m['release_date'] ?? m['first_air_date'] ?? '').toString();
            final year = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';
            final genresList = (m['genres'] as List?)?.map((g) => g['name'].toString()).toList() ?? [];
            final genresString = genresList.isNotEmpty ? genresList.join(', ') : 'Drama, Feature Film';

            // Ekip & Oyuncular
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
            final isInWatchlist = watchStatus == 'plan_to_watch';

            return SafeArea(
              child: Column(
                children: [
                  // 1. Dribbble "American Beauty" Üst Başlık Çubuğu:
                  // < Geri Oku   |   Başlık & (1999 · Sam Mendes)   |   ♡ Kalp İkonu
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Geri Oku
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: titleColor),
                          onPressed: () => Navigator.pop(context),
                        ),

                        // Ortalanmış Başlık ve Yönetmen/Yıl
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: titleColor,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${year.isNotEmpty ? year : "Cinema"}${directors.isNotEmpty ? " · $directors" : ""}',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: mutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Sağ Kalp (Watchlist / Favori)
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
                  ),

                  // 2. Dribbble "American Beauty" İçerik Akışı
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // -------------------------------
                          // SECTION: Cast (Oyuncular)
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
                              height: 145,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: castList.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 14),
                                itemBuilder: (context, index) {
                                  final actor = castList[index];
                                  final actorName = actor['name'] ?? 'Unknown';
                                  final character = actor['character'] ?? '';
                                  final profilePath = actor['profile_path'];

                                  return GestureDetector(
                                    onTap: () => ActorDetailModal.show(context, actor),
                                    child: SizedBox(
                                      width: 90,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Kare / Yuvarlatılmış Sanatçı Fotoğrafı
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Container(
                                              width: 90,
                                              height: 90,
                                              color: isDark ? const Color(0xFF1E212B) : const Color(0xFFF0F1F5),
                                              child: profilePath != null
                                                  ? Image.network(
                                                      AppConstants.getPosterUrl(profilePath),
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => const Icon(
                                                        Icons.person,
                                                        color: Colors.grey,
                                                        size: 40,
                                                      ),
                                                    )
                                                  : const Icon(Icons.person, color: Colors.grey, size: 40),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          // Sanatçı İsmi (Kalın)
                                          Text(
                                            actorName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: titleColor,
                                            ),
                                          ),
                                          // Karakter Adı (Gri)
                                          Text(
                                            character.isNotEmpty ? character : 'Cast',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w400,
                                              color: mutedColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            Text('Cast details not available.', style: TextStyle(color: mutedColor, fontSize: 13)),

                          const SizedBox(height: 24),

                          // -------------------------------
                          // SECTION: Awards (Kupa İkonları & Metin)
                          // -------------------------------
                          Text(
                            'Awards',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('🏆 🏆 🏆 🏆 🏆 ', style: TextStyle(fontSize: 18)),
                              Expanded(
                                child: Text(
                                  '${voteAverage.toStringAsFixed(1)} Rating · Winner of Multi Academy & Film Awards... 5 more',
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

                          // -------------------------------
                          // SECTION: Genres (Türler)
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
                          const SizedBox(height: 6),
                          Text(
                            genresString,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : const Color(0xFF4A4E5A),
                              height: 1.4,
                            ),
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
                          Text(
                            overview,
                            maxLines: _isStorylineExpanded ? null : 4,
                            overflow: _isStorylineExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: isDark ? Colors.white70 : const Color(0xFF4A4E5A),
                            ),
                          ),
                          if (overview.length > 180) ...[
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => setState(() => _isStorylineExpanded = !_isStorylineExpanded),
                              child: Text(
                                _isStorylineExpanded ? 'Less' : 'More',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // -------------------------------
                          // SECTION: Metadata (Country, Budget, Worldwide Gross)
                          // -------------------------------
                          _buildMetaSection('Country', countryName, titleColor, mutedColor),
                          const SizedBox(height: 16),
                          _buildMetaSection('Budget', _formatCurrency(budgetNum), titleColor, mutedColor),
                          const SizedBox(height: 16),
                          _buildMetaSection('Cumulative Worldwide Gross', _formatCurrency(revenueNum), titleColor, mutedColor),

                          const SizedBox(height: 32),

                          // -------------------------------
                          // SECTION: İnceleme / Puan Butonu (ShadButton)
                          // -------------------------------
                          SizedBox(
                            width: double.infinity,
                            child: ShadButton(
                              onPressed: () => _showRatingModal(m),
                              backgroundColor: AppTheme.primaryColor,
                              leading: const Icon(Icons.star_rounded, size: 20, color: Colors.white),
                              child: const Text(
                                'Add a review',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
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

  Widget _buildMetaSection(String label, String value, Color titleColor, Color mutedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: titleColor,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            color: mutedColor,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
