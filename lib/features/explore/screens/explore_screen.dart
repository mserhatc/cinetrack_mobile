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
  final PageController _pageController = PageController(viewportFraction: 0.92);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final titleColor = isDark ? Colors.white : AppTheme.darkText;
    final mutedColor = isDark ? Colors.white60 : AppTheme.mutedText;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Üst Arama & Kategori Çubuğu (Minimalist)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _isSearching
                        ? Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkCard : const Color(0xFFF7F8FA),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? AppTheme.darkCardBorder : AppTheme.borderColor,
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              style: TextStyle(fontSize: 14, color: titleColor),
                              decoration: InputDecoration(
                                hintText: 'Film, dizi veya oyuncu ara...',
                                hintStyle: TextStyle(fontSize: 13, color: mutedColor),
                                prefixIcon: Icon(Icons.search, size: 20, color: mutedColor),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onSubmitted: (query) {
                                if (query.trim().isNotEmpty) {
                                  context.read<ExploreCubit>().search(query.trim());
                                }
                              },
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                _buildCategoryPill('Trending', 'trending', isDark),
                                const SizedBox(width: 8),
                                _buildCategoryPill('Top Rated', 'top_rated', isDark),
                                const SizedBox(width: 8),
                                _buildCategoryPill('Now Playing', 'now_playing', isDark),
                                const SizedBox(width: 8),
                                _buildCategoryPill('Upcoming', 'upcoming', isDark),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  // Arama Açma / Kapama Butonu
                  IconButton(
                    icon: Icon(_isSearching ? Icons.close : Icons.search_rounded, color: titleColor),
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchController.clear();
                          context.read<ExploreCubit>().fetchItems(category: _selectedCategory);
                        }
                      });
                    },
                  ),
                ],
              ),
            ),

            // Dribbble Kart Slider (PageView)
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
                          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            state.message,
                            style: TextStyle(color: mutedColor),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.read<ExploreCubit>().fetchItems(category: _selectedCategory),
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
                        child: Text('İçerik bulunamadı.', style: TextStyle(color: mutedColor)),
                      );
                    }

                    return PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return MovieExplorerCard(
                          media: item,
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String title, String key, bool isDark) {
    final isSelected = _selectedCategory == key;
    return GestureDetector(
      onTap: () => _onCategorySelected(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : AppTheme.darkText)
              : (isDark ? AppTheme.darkCard : const Color(0xFFF7F8FA)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? AppTheme.darkCardBorder : AppTheme.borderColor),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? AppTheme.darkBg : Colors.white)
                : (isDark ? Colors.white70 : AppTheme.darkText),
          ),
        ),
      ),
    );
  }
}
