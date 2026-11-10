import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../feed/cubit/feed_cubit.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../cubit/media_detail_cubit.dart';

class MediaDetailScreen extends StatefulWidget {
  final String mediaType; // 'movie' or 'tv'
  final int id;

  const MediaDetailScreen({super.key, required this.mediaType, required this.id});

  @override
  State<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends State<MediaDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MediaDetailCubit>().loadDetails(widget.id, widget.mediaType);
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
                left: 20,
                right: 20,
                top: 20,
                bottom: 20 + bottomInset,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Puan Ver & Yorum Yaz: $title',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        '$selectedRating / 10',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber),
                      ),
                    ],
                  ),
                  Slider(
                    value: selectedRating,
                    min: 1.0,
                    max: 10.0,
                    divisions: 18,
                    activeColor: Colors.amber,
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
    final loc = AppLocalizations.of(context);
    final isMovie = widget.mediaType == 'movie';

    return Scaffold(
      body: BlocBuilder<MediaDetailCubit, MediaDetailState>(
        builder: (context, state) {
          if (state is MediaDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MediaDetailError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
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
            final overview = m['overview'] ?? '';
            final backdrop = m['backdrop_path'];
            final poster = m['poster_path'];
            final voteAverage = (m['vote_average'] ?? 0.0).toStringAsFixed(1);
            final releaseDate = (m['release_date'] ?? m['first_air_date'] ?? '').toString();
            final year = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';
            final genres = (m['genres'] as List?)?.map((g) => g['name']).join(', ') ?? '';
            final credits = m['credits'];
            final castList = (credits?['cast'] as List?)?.take(10).toList() ?? [];

            final watchStatus = state.watchStatus; // 'watched', 'plan_to_watch', null
            final isWatched = watchStatus == 'watched';
            final isInWatchlist = watchStatus == 'plan_to_watch';

            return CustomScrollView(
              slivers: [
                // Backdrop AppBar
                SliverAppBar(
                  expandedHeight: 250,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          AppConstants.getBackdropUrl(backdrop),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.black),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black87, Colors.transparent],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Detay Bilgileri
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Başlık ve Poster
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                AppConstants.getPosterUrl(poster),
                                width: 90,
                                height: 135,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${isMovie ? "Film" : "Dizi"} • $year',
                                    style: TextStyle(color: theme.textTheme.bodySmall?.color),
                                  ),
                                  if (genres.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      genres,
                                      style: TextStyle(fontSize: 12, color: theme.colorScheme.primary),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$voteAverage / 10',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Eylem Butonları: İzleme Listesi, İzlendi, Puan Ver
                        Row(
                          children: [
                            // İzleme Listesi (Plan to watch)
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
                                  if (mounted) {
                                    context.read<ProfileCubit>().loadProfile();
                                  }
                                },
                                icon: Icon(
                                  isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
                                  color: isInWatchlist ? Colors.amber : null,
                                ),
                                label: Text(
                                  isInWatchlist ? loc.translate('in_watchlist') : loc.translate('add_watchlist'),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: BorderSide(
                                    color: isInWatchlist ? Colors.amber : theme.dividerColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // İzlendi Olarak İşaretle
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
                                  if (mounted) {
                                    context.read<ProfileCubit>().loadProfile();
                                  }
                                },
                                icon: Icon(
                                  isWatched ? Icons.check_circle : Icons.check_circle_outline,
                                  color: isWatched ? Colors.greenAccent : Colors.white,
                                ),
                                label: Text(
                                  isWatched ? loc.translate('watched') : loc.translate('mark_watched'),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isWatched ? Colors.green.shade900 : theme.colorScheme.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Puan Ver & Yorum Yap Butonu
                        OutlinedButton.icon(
                          onPressed: () => _showRatingModal(m),
                          icon: const Icon(Icons.star_rate_rounded, color: Colors.amber),
                          label: Text(
                            state.userRating != null
                                ? 'Puanınız: ${state.userRating} / 10 (Değiştir)'
                                : loc.translate('rate'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            side: const BorderSide(color: Colors.amber),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Özet
                        const Text('Özet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          overview.isNotEmpty ? overview : 'Bu yapım için henüz özet bulunmuyor.',
                          style: const TextStyle(fontSize: 14.5, height: 1.5),
                        ),

                        const SizedBox(height: 24),

                        // Oyuncu Kadrosu
                        if (castList.isNotEmpty) ...[
                          const Text('Oyuncular', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 120,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: castList.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final actor = castList[index];
                                final profile = actor['profile_path'];
                                return SizedBox(
                                  width: 80,
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 32,
                                        backgroundImage: profile != null
                                            ? NetworkImage(AppConstants.getPosterUrl(profile))
                                            : null,
                                        child: profile == null ? const Icon(Icons.person) : null,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        actor['name'] ?? '',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Topluluk Yorumları
                        Text(
                          'Topluluk Yorumları (${state.communityReviews.length})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (state.communityReviews.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'Bu film için henüz topluluk yorumu yapılmamış. İlk yorumu sen yap!',
                              style: TextStyle(color: theme.textTheme.bodySmall?.color),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.communityReviews.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final rev = state.communityReviews[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: (rev['avatar'] != null && rev['avatar'].toString().isNotEmpty)
                                      ? NetworkImage(rev['avatar'])
                                      : null,
                                  child: (rev['avatar'] == null || rev['avatar'].toString().isEmpty)
                                      ? Text((rev['username'] ?? '?')[0].toUpperCase())
                                      : null,
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      rev['full_name']?.isNotEmpty == true ? rev['full_name'] : rev['username'],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${rev['rating']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(rev['review_text'] ?? ''),
                                ),
                              );
                            },
                          ),
                      ],
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

