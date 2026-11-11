import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../cubit/explore_cubit.dart';
import '../widgets/movie_explorer_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final PageController _pageController = PageController(viewportFraction: 1.0);
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _selectedCategory = 'trending';

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
      _selectedCategory = category;
      _isSearching = false;
      _searchController.clear();
    });
    context.read<ExploreCubit>().fetchItems(category: category);
  }

  Widget _buildCategoryPill(String title, String category, bool isDark) {
    final isSelected = _selectedCategory == category && !_isSearching;
    final activeBg = isDark ? Colors.white : AppTheme.darkText;
    final activeText = isDark ? AppTheme.darkText : Colors.white;
    final inactiveBg = isDark ? AppTheme.darkCard : AppTheme.softGreyBg;
    final inactiveText = isDark ? Colors.white70 : const Color(0xFF4B5563);

    return GestureDetector(
      onTap: () => _onCategorySelected(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? activeText : inactiveText,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final titleColor = isDark ? Colors.white : AppTheme.darkText;
    final mutedColor = isDark ? Colors.white60 : AppTheme.mutedText;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Üst Kategori Hapları ve Yuvarlak Arama Butonu (PDF Page 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: _isSearching
                        ? TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: TextStyle(color: titleColor, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Film, dizi veya oyuncu ara...',
                              prefixIcon: Icon(Icons.search_rounded, size: 20, color: mutedColor),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              filled: true,
                              fillColor: isDark ? AppTheme.darkCard : AppTheme.softGreyBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (query) {
                              if (query.trim().isNotEmpty) {
                                context.read<ExploreCubit>().search(query.trim());
                              }
                            },
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                _buildCategoryPill('Trending', 'trending', isDark),
                                const SizedBox(width: 10),
                                _buildCategoryPill('Top Rated', 'top_rated', isDark),
                                const SizedBox(width: 10),
                                _buildCategoryPill('Now Playing', 'now_playing', isDark),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  // Sağ Yuvarlak Arama İkon Butonu
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchController.clear();
                          context.read<ExploreCubit>().fetchItems(category: _selectedCategory);
                        }
                      });
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? AppTheme.darkCard : AppTheme.softGreyBg,
                      ),
                      child: Icon(
                        _isSearching ? Icons.close_rounded : Icons.search_rounded,
                        color: titleColor,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tam Ekran Kart Destesi (Floating Bottom Nav üstünde)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 92),
                child: BlocBuilder<ExploreCubit, ExploreState>(
                  builder: (context, state) {
                    if (state is ExploreLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryColor),
                      );
                    }

                    if (state is ExploreError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(state.message, style: TextStyle(color: mutedColor)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () =>
                                    context.read<ExploreCubit>().fetchItems(category: _selectedCategory),
                                child: const Text('Tekrar Dene'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (state is ExploreLoaded) {
                      final items = state.items;
                      if (items.isEmpty) {
                        return Center(
                          child: Text('İçerik bulunamadı.', style: TextStyle(color: mutedColor)),
                        );
                      }

                      return PageView.builder(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return MovieExplorerCard(
                            media: items[index],
                          );
                        },
                      );
                    }

                    return const SizedBox();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
