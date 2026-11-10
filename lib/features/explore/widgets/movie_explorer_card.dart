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
    final mutedColor = isDark ? Colors.white60 : AppTheme.mutedText;

    final id = media['id'];
    final mediaType = media['media_type'] ?? (media['title'] != null ? 'movie' : 'tv');
    final title = media['title'] ?? media['name'] ?? 'Untitled';
    final releaseDate = (media['release_date'] ?? media['first_air_date'] ?? '').toString();
    final year = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';
    final poster = media['poster_path'];
    final backdrop = media['backdrop_path'];

    // Director or subtitle
    final directorOrSubtitle = media['director'] ?? (mediaType == 'tv' ? 'Dizi' : 'Sinema');

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
            if (id != null) {
              context.push('/media/$mediaType/$id');
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: cardBg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Poster / Arka Plan Görseli
                  Image.network(
                    AppConstants.getPosterUrl(poster ?? backdrop),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFC4552B), Color(0xFFF2A65A)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.movie_outlined, size: 64, color: Colors.white),
                      ),
                    ),
                  ),

                  // 2. Alt Beyaz / Koyu Degrade (Dribbble & HTML spec)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: constraints.maxHeight * 0.62,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            cardBg.withValues(alpha: 0.0),
                            cardBg.withValues(alpha: 0.7),
                            cardBg,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. İçerik Bilgileri: Başlık, Yıl/Yönetmen, 5 Yıldız, Amber Play Butonu, "More ⌄"
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Başlık (The Martian)
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
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Yıl · Yönetmen
                        Text(
                          '$year${year.isNotEmpty ? " · " : ""}$directorOrSubtitle',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: mutedColor,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // ★★★★★ Altın Yıldızlar
                        Text(
                          '★★★★★',
                          style: const TextStyle(
                            color: AppTheme.starColor,
                            fontSize: 20,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Dairesel Amber Play / Aksiyon Butonu
                        GestureDetector(
                          onTap: onPlayTrailer ?? () {
                            if (id != null) {
                              context.push('/media/$mediaType/$id');
                            }
                          },
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppTheme.primaryGradientStart,
                                  AppTheme.primaryGradientEnd,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
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

                        // "More ⌄" Linki
                        Text(
                          'More ⌄',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
