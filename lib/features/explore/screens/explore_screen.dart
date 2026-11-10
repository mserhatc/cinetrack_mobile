import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../cubit/explore_cubit.dart';
import '../widgets/movie_explorer_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.94);
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    context.read<ExploreCubit>().fetchItems(category: 'trending');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _currentPage = 0;
    });
    context.read<ExploreCubit>().fetchItems(category: category);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Üst Başlık & Arama Çubuğu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (_isSearching)
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Film veya Dizi ara...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              setState(() {
                                _isSearching = false;
                                _searchController.clear();
                              });
                              context.read<ExploreCubit>().fetchItems();
                            },
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onSubmitted: (query) {
                          if (query.trim().isNotEmpty) {
                            context.read<ExploreCubit>().search(query.trim());
                          }
                        },
                      ),
                    )
                  else ...[
                    // Logo / Başlık
                    Row(
                      children: [
                        Text(
                          'Movie',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : AppTheme.darkText,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Explorer',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white70 : AppTheme.mutedText,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Arama Açma Butonu
                    IconButton(
                      icon: Icon(
                        Icons.search_rounded,
                        color: isDark ? Colors.white : AppTheme.darkText,
                        size: 24,
                      ),
                      onPressed: () {
                        setState(() => _isSearching = true);
                      },
                    ),
                  ],
                ],
              ),
            ),

            // Kategori Hap Butonları (Trending, Movies, TV)
            if (!_isSearching)
              BlocBuilder<ExploreCubit, ExploreState>(
                builder: (context, state) {
                  final activeCategory = state is ExploreLoaded ? state.activeCategory : 'trending';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildCategoryChip('Trending', 'trending', activeCategory == 'trending', isDark),
                          const SizedBox(width: 8),
                          _buildCategoryChip('Movies', 'movies', activeCategory == 'movies', isDark),
                          const SizedBox(width: 8),
                          _buildCategoryChip('TV Shows', 'tv', activeCategory == 'tv', isDark),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // Ana İçerik: Movie Explorer Kart Swiper (PageView)
            Expanded(
              child: BlocBuilder<ExploreCubit, ExploreState>(
                builder: (context, state) {
                  if (state is ExploreLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryColor),
                    );
                  }

                  if (state is ExploreError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(state.message, style: TextStyle(color: isDark ? Colors.white70 : AppTheme.mutedText)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context.read<ExploreCubit>().fetchItems(),
                            child: const Text('Tekrar Dene'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is ExploreLoaded) {
                    final items = state.items;
                    if (items.isEmpty) {
                      return Center(
                        child: Text(
                          'Sonuç bulunamadı.',
                          style: TextStyle(color: isDark ? Colors.white70 : AppTheme.mutedText),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: items.length,
                            onPageChanged: (index) {
                              setState(() => _currentPage = index);
                            },
                            itemBuilder: (context, index) {
                              final media = items[index];
                              return MovieExplorerCard(
                                media: media,
                                onPlayTrailer: () {
                                  final id = media['id'];
                                  final mediaType = media['media_type'] ?? (media['title'] != null ? 'movie' : 'tv');
                                  context.push('/media/$mediaType/$id');
                                },
                              );
                            },
                          ),
                        ),

                        // Sayfa Göstergesi Çizgisi (Subtle progress indicator)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12, top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${_currentPage + 1} / ${items.length}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white38 : AppTheme.mutedText,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String title, String key, bool isSelected, bool isDark) {
    return GestureDetector(
      onTap: () => _onCategorySelected(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : AppTheme.darkText)
              : (isDark ? AppTheme.darkCard : const Color(0xFFF4F5F8)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? AppTheme.darkText : Colors.white)
                : (isDark ? Colors.white60 : AppTheme.mutedText),
          ),
        ),
      ),
    );
  }
}
