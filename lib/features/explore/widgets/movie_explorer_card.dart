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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final titleColor = isDark ? Colors.white : AppTheme.darkText;
    final subtitleColor = isDark ? Colors.white60 : AppTheme.mutedText;

    final id = media['id'];
    final mediaType = media['media_type'] ?? (media['title'] != null ? 'movie' : 'tv');
    final title = media['title'] ?? media['name'] ?? 'Untitled';
    final releaseDate = (media['release_date'] ?? media['first_air_date'] ?? '').toString();
    final year = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';
    final poster = media['poster_path'];
    final backdrop = media['backdrop_path'];
    final voteAverage = (media['vote_average'] as num?)?.toDouble() ?? 7.5;
    
    // TMDB vote (0-10) scaled to 5 stars
    final starCount = (voteAverage / 2).clamp(1.0, 5.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;

        return Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: cardBg,
          ),
          child: Column(
            children: [
              // 1. Üst Sanatsal Görsel & Aşağıya Doğru Kusursuz Beyaz Degrade
              Expanded(
                flex: 12,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Arka Plan Poster / Backdrop
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Image.network(
                          AppConstants.getPosterUrl(poster ?? backdrop),
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.movie_outlined, size: 64, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Yumuşak Beyaz Geçiş Gradyanı (Fade to Card Background)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.45, 0.75, 1.0],
                            colors: [
                              cardBg.withOpacity(0.0),
                              cardBg.withOpacity(0.0),
                              cardBg.withOpacity(0.7),
                              cardBg,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Başlık, Yönetmen/Yıl, Yıldızlar ve Play Butonu
              Expanded(
                flex: 8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Film Başlığı
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Yıl ve Alt Bilgi (2015 · Ridley Scott tarzı)
                      Text(
                        year.isNotEmpty ? '$year · ${mediaType == "tv" ? "TV Series" : "Cinema"}' : 'Cinema Feature',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 5'li Yıldız Derecelendirmesi
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starIndex = index + 1;
                          final isFilled = starCount >= starIndex;
                          final isHalf = !isFilled && starCount >= (starIndex - 0.5);

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Icon(
                              isFilled
                                  ? Icons.star_rounded
                                  : (isHalf ? Icons.star_half_rounded : Icons.star_outline_rounded),
                              color: isFilled || isHalf ? AppTheme.starColor : (isDark ? Colors.white24 : Colors.grey.shade300),
                              size: 18,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),

                      // İkonik Amber Play / Detay Butonu
                      GestureDetector(
                        onTap: () {
                          if (onPlayTrailer != null) {
                            onPlayTrailer!();
                          } else {
                            context.push('/media/$mediaType/$id');
                          }
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // "More" ve Aşağı Ok Göstergesi
                      InkWell(
                        onTap: () => context.push('/media/$mediaType/$id'),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'More',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: subtitleColor,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: subtitleColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

