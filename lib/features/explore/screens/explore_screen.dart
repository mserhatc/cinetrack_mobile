import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/theme/app_theme.dart';
import '../cubit/explore_cubit.dart';
import '../widgets/movie_explorer_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.90);
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
    final activeBg = isDark ? Colors.white : const Color(0xFF111111);
    final activeText = isDark ? const Color(0xFF111111) : Colors.white;
    final inactiveBorder = isDark ? AppTheme.darkCardBorder : AppTheme.inputBorderColor;
    final inactiveText = isDark ? Colors.white70 : const Color(0xFF111111);

    return GestureDetector(
      onTap: () => _onCategorySelected(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isSelected ? activeBg : inactiveBorder,
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? activeText : inactiveText,
          ),
        ),
      ),
    );
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
            // Üst Kategori Pill'leri ve Arama Butonu
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 16, top: 12, bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _isSearching
                        ? ShadInput(
                            controller: _searchController,
                            placeholder: const Text('Film, dizi veya oyuncu ara...'),
                            leading: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(Icons.search, size: 18, color: mutedColor),
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
                                const SizedBox(width: 8),
                                _buildCategoryPill('Top Rated', 'top_rated', isDark),
                                const SizedBox(width: 8),
                                _buildCategoryPill('Now', 'now_playing', isDark),
                                const SizedBox(width: 8),
                                _buildCategoryPill('Upcoming', 'upcoming', isDark),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
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

            // Kart Alanı (Dribbble Movie Explorer Tam Ekran Deneyimi)
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
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(state.message, style: TextStyle(color: mutedColor)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => context.read<ExploreCubit>().fetchItems(category: _selectedCategory),
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
                        return Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 12),
                          child: MovieExplorerCard(
                            media: items[index],
                          ),
                        );
                      },
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
}
