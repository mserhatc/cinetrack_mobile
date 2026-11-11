import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class MovieExplorerCard extends StatelessWidget {
  final Map<String, dynamic> media;
  final VoidCallback? onPlayTrailer;

  const MovieExplorerCard({
    super.key,
    required this.media,
    this.onPlayTrailer,
  });

  List<String> _resolveGenres(Map<String, dynamic> m) {
    final genreMap = <int, String>{
      28: 'Action',
      12: 'Adventure',
      16: 'Animation',
      35: 'Comedy',
      80: 'Crime',
      99: 'Documentary',
      18: 'Drama',
      10751: 'Family',
      14: 'Fantasy',
      36: 'History',
      27: 'Horror',
      10402: 'Music',
      9648: 'Mystery',
      10749: 'Romance',
      878: 'Sci-Fi',
      53: 'Thriller',
      10752: 'War',
      37: 'Western',
    };

    if (m['genres'] is List && (m['genres'] as List).isNotEmpty) {
      return (m['genres'] as List)
          .take(3)
          .map((g) => g is Map ? (g['name']?.toString() ?? 'Drama') : g.toString())
          .toList();
    }
    if (m['genre_ids'] is List && (m['genre_ids'] as List).isNotEmpty) {
      return (m['genre_ids'] as List)
          .take(3)
          .map((id) => genreMap[int.tryParse(id.toString()) ?? 0] ?? 'Drama')
          .toList();
    }
    return ['Sci-Fi', 'Adventure', 'Drama'];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final titleColor = isDark ? Colors.white : AppTheme.darkText;
    final mutedColor = isDark ? Colors.white60 : AppTheme.mutedText;

    final id = media['id'];
    final mediaType = media['media_type'] ?? (media['title'] != null ? 'movie' : 'tv');
    final title = media['title'] ?? media['name'] ?? 'The Martian';
    final releaseDate = (media['release_date'] ?? media['first_air_date'] ?? '2015').toString();
    final year = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '2015';
    final poster = media['poster_path'];
    final backdrop = media['backdrop_path'];
    final voteAverage = (media['vote_average'] as num?)?.toDouble() ?? 8.0;
    final directorOrSubtitle = media['director'] ?? (mediaType == 'tv' ? 'TV Series' : 'Ridley Scott');
    final genres = _resolveGenres(media);

    return GestureDetector(
      onTap: () {
        if (id != null) {
          context.push('/media/$mediaType/$id');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Arka Kart Katmanı 2 (En sağdaki teal/mavi katman - PDF Page 1)
            Positioned(
              top: 34,
              bottom: 34,
              right: 0,
              width: 40,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF5A5D9D), Color(0xFF438E96)],
                  ),
                ),
              ),
            ),

            // Arka Kart Katmanı 1 (Orta sağdaki mor/mavi katman - PDF Page 1)
            Positioned(
              top: 18,
              bottom: 18,
              right: 8,
              width: 40,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF6B5B95), Color(0xFF4C8693)],
                  ),
                ),
              ),
            ),

            // Ana Kart
            Positioned.fill(
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: cardBg,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. Arka Plan Sanatsal Degrade + Poster Görseli
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFC85A28),
                              Color(0xFFE58C45),
                              Color(0xFFF6E7D8),
                            ],
                          ),
                        ),
                      ),

                      // Dekoratif Güneş / Gezegen Dairesi (Poster yüklenirken veya arkada)
                      Positioned(
                        top: 90,
                        right: 36,
                        child: Container(
                          width: 145,
                          height: 145,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFE5B4).withValues(alpha: 0.85),
                          ),
                        ),
                      ),

                      if (poster != null || backdrop != null)
                        Image.network(
                          AppConstants.getPosterUrl(poster ?? backdrop),
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),

                      // 2. Alt Yumuşak Krem-Beyaz Geçiş Degradesi (PDF Page 1)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.38, 0.65, 0.92, 1.0],
                              colors: [
                                Colors.transparent,
                                Colors.transparent,
                                (isDark ? AppTheme.darkCard : const Color(0xFFF3E5D8)).withValues(alpha: 0.78),
                                (isDark ? AppTheme.darkCard : const Color(0xFFFAF6F2)).withValues(alpha: 0.96),
                                isDark ? AppTheme.darkCard : Colors.white,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 3. Sol Üst Puan Rozeti (★ 8.0)
                      Positioned(
                        top: 18,
                        left: 18,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: AppTheme.primaryColor, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                voteAverage.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.darkText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 4. Alt Bilgiler: Başlık, Yıl · Yönetmen, Tür Hapları, 5 Yıldız, Play Butonu, More ⌄
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 18,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Başlık
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: titleColor,
                                letterSpacing: -0.6,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Yıl · Yönetmen
                            Text(
                              '$year · $directorOrSubtitle',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: mutedColor,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Tür Hapları (Sci-Fi | Adventure | Drama)
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              alignment: WrapAlignment.center,
                              children: genres.map((genre) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.92),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    genre,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: titleColor,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),

                            // 5 Altın Yıldız (★ ★ ★ ★ ★)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 2.5),
                                  child: Icon(
                                    Icons.star_rounded,
                                    color: AppTheme.starColor,
                                    size: 20,
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 16),

                            // Yuvarlak Amber Play Butonu
                            GestureDetector(
                              onTap: onPlayTrailer ??
                                  () {
                                    if (id != null) {
                                      context.push('/media/$mediaType/$id');
                                    }
                                  },
                              child: Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.primaryGradientStart,
                                      AppTheme.primaryGradientEnd,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withValues(alpha: 0.42),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // More ⌄
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'More',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: mutedColor,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: mutedColor,
                                ),
                              ],
                            ),
                          ],
                        ),
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
}
