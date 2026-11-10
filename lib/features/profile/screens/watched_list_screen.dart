import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../cubit/profile_cubit.dart';

class WatchedListScreen extends StatefulWidget {
  final String mediaType; // 'movie' or 'tv'
  final int userId;

  const WatchedListScreen({super.key, required this.mediaType, required this.userId});

  @override
  State<WatchedListScreen> createState() => _WatchedListScreenState();
}

class _WatchedListScreenState extends State<WatchedListScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    final cubit = context.read<ProfileCubit>();
    List<Map<String, dynamic>> list;
    if (widget.mediaType == 'movie') {
      list = await cubit.getWatchedMovies(widget.userId);
    } else {
      list = await cubit.getWatchedShows(widget.userId);
    }
    if (mounted) {
      setState(() {
        _items = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final titleColor = isDark ? Colors.white : AppTheme.darkText;
    final mutedColor = isDark ? Colors.white60 : AppTheme.mutedText;

    final loc = AppLocalizations.of(context);
    final isMovie = widget.mediaType == 'movie';
    final title = isMovie ? loc.translate('watched_movies') : loc.translate('watched_shows');

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: titleColor),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: titleColor,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _items.isEmpty
              ? Center(
                  child: Text(
                    isMovie ? 'Henüz izlenen film yok.' : 'Henüz izlenen dizi yok.',
                    style: TextStyle(color: mutedColor, fontSize: 14),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final poster = item['poster_path'];
                    final rating = item['rating'];
                    final tmdbId = item['tmdb_id'];

                    return InkWell(
                      onTap: () => context.push('/media/${widget.mediaType}/$tmdbId'),
                      borderRadius: BorderRadius.circular(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              AppConstants.getPosterUrl(poster),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: isDark ? AppTheme.darkCard : Colors.grey.shade200,
                                child: Icon(Icons.movie, color: mutedColor),
                              ),
                            ),
                            if (rating != null)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: ShadBadge(
                                  backgroundColor: Colors.black.withValues(alpha: 0.7),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, color: AppTheme.starColor, size: 12),
                                      const SizedBox(width: 2),
                                      Text(
                                        '$rating',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
                                  ),
                                ),
                                child: Text(
                                  item['title'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
