import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class ActorDetailModal extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final titleColor = isDark ? Colors.white : AppTheme.darkText;
    final mutedColor = isDark ? Colors.white60 : AppTheme.mutedText;

    final name = actor['name'] ?? 'Unknown Actor';
    final character = actor['character'] ?? '';
    final profilePath = actor['profile_path'];
    final department = actor['known_for_department'] ?? 'Acting';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Üst Sanatçı Fotoğrafı & Aşağıya Beyaz Fade
                Stack(
                  children: [
                    Container(
                      height: 320,
                      width: double.infinity,
                      foregroundDecoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.5, 0.8, 1.0],
                          colors: [
                            cardBg.withOpacity(0.0),
                            cardBg.withOpacity(0.0),
                            cardBg.withOpacity(0.7),
                            cardBg,
                          ],
                        ),
                      ),
                      child: Image.network(
                        AppConstants.getPosterUrl(profilePath),
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.person, size: 80, color: Colors.grey),
                        ),
                      ),
                    ),

                    // Kapatma ve Kalp Butonları
                    Positioned(
                      top: 16,
                      left: 16,
                      child: CircleAvatar(
                        backgroundColor: Colors.black26,
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    const Positioned(
                      top: 16,
                      right: 16,
                      child: CircleAvatar(
                        backgroundColor: Colors.black26,
                        child: Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 20),
                      ),
                    ),
                  ],
                ),

                // 2. Sanatçı İsmi ve Rol / Bilgi
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$department ${character.isNotEmpty ? "· $character" : ""}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: mutedColor,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Awards Bölümü (Dribbble şablonundaki gibi 🏆)
                      Text(
                        'Awards',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text('🏆 🏆 🏆 ', style: TextStyle(fontSize: 16)),
                          Expanded(
                            child: Text(
                              '1 Oscar, 3 Golden Globes, 1 Saturn Award... 12 more',
                              style: TextStyle(
                                fontSize: 13,
                                color: mutedColor,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // About / Biyografi Bölümü
                      Text(
                        'About',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$name is an acclaimed artist renowned for exceptional screen performances and cinematic contributions across international cinema.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: isDark ? Colors.white70 : const Color(0xFF4A4E5A),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Born / Detaylar
                      _buildDetailRow('Department', department, titleColor, mutedColor),
                      const SizedBox(height: 12),
                      _buildDetailRow('Character Role', character.isNotEmpty ? character : 'Cast Member', titleColor, mutedColor),
                      const SizedBox(height: 12),
                      _buildDetailRow('Popularity Score', '${actor['popularity'] ?? 42.5} pts', titleColor, mutedColor),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
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
