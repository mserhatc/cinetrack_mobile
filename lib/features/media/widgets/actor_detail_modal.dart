import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class ActorDetailModal extends StatefulWidget {
  final Map<String, dynamic> actor;

  const ActorDetailModal({super.key, required this.actor});

  static void show(BuildContext context, Map<String, dynamic> actor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ActorDetailModal(actor: actor),
    );
  }

  @override
  State<ActorDetailModal> createState() => _ActorDetailModalState();
}

class _ActorDetailModalState extends State<ActorDetailModal> {
  bool _isFavorite = false;
  bool _isBioExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final titleColor = isDark ? Colors.white : AppTheme.darkText;
    final mutedColor = isDark ? Colors.white60 : AppTheme.mutedText;

    final name = widget.actor['name'] ?? 'Unknown Artist';
    final character = widget.actor['character'] ?? '';
    final profilePath = widget.actor['profile_path'];
    final department = widget.actor['known_for_department'] ?? 'Acting';
    final popularity = widget.actor['popularity'] ?? 45.0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // 1. Dribbble "Angelina Jolie" Üst Başlık
          // < Geri   |   Angelina Jolie (Actress · 43yo)   |   ♥ Kalp
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: titleColor),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
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
                        department == 'Acting' ? 'Actress / Actor' : department,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _isFavorite ? Colors.redAccent : titleColor,
                    size: 22,
                  ),
                  onPressed: () => setState(() => _isFavorite = !_isFavorite),
                ),
              ],
            ),
          ),

          // 2. İçerik ve Görsel
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sanatçı Hero Portresi (Aşağıya Beyaz Fade)
                  Stack(
                    children: [
                      Container(
                        height: 340,
                        width: double.infinity,
                        foregroundDecoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.45, 0.75, 1.0],
                            colors: [
                              cardBg.withValues(alpha: 0.0),
                              cardBg.withValues(alpha: 0.0),
                              cardBg.withValues(alpha: 0.65),
                              cardBg,
                            ],
                          ),
                        ),
                        child: profilePath != null
                            ? Image.network(
                                AppConstants.getPosterUrl(profilePath),
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.person, size: 80, color: Colors.grey),
                                ),
                              )
                            : Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.person, size: 80, color: Colors.grey),
                              ),
                      ),
                    ],
                  ),

                  // Dribbble Bölümleri: Awards, About, Born, Height, Years Active
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Awards
                        Text(
                          'Awards',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Text('🏆 🏆 🏆 🏆 🏆 ', style: TextStyle(fontSize: 16)),
                            Expanded(
                              child: Text(
                                'Academy Award, Golden Globe & BAFTA Honoree... 12 more',
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

                        // About
                        Text(
                          'About',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$name is an acclaimed cinema artist and international screen presence known for dynamic performances and award-winning feature roles across global cinema.',
                          maxLines: _isBioExpanded ? null : 3,
                          overflow: _isBioExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.5,
                            color: isDark ? Colors.white70 : const Color(0xFF4A4E5A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => setState(() => _isBioExpanded = !_isBioExpanded),
                          child: Text(
                            _isBioExpanded ? 'Less' : 'More',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Born / Detaylar
                        _buildDetailRow('Born', 'United States', titleColor, mutedColor),
                        const SizedBox(height: 14),
                        _buildDetailRow('Height', '5\' 7" (1.70 m)', titleColor, mutedColor),
                        const SizedBox(height: 14),
                        _buildDetailRow('Known Department', department, titleColor, mutedColor),
                        if (character.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildDetailRow('Featured Role', character, titleColor, mutedColor),
                        ],
                        const SizedBox(height: 14),
                        _buildDetailRow('Popularity Score', '${popularity.toString()} pts', titleColor, mutedColor),
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color titleColor, Color mutedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 3),
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
