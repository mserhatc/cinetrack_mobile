import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/language_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../cubit/feed_cubit.dart';
import '../widgets/post_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<FeedCubit>().fetchFeed();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = context.watch<ThemeCubit>().isDarkMode;
    final currentLang = context.watch<LanguageCubit>().state.languageCode;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final titleColor = isDark ? Colors.white : AppTheme.darkText;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: GestureDetector(
          onTap: _scrollToTop,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Feed',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: titleColor,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Dil Seçici
          TextButton(
            onPressed: () => context.read<LanguageCubit>().toggleLanguage(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                currentLang.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: titleColor,
                ),
              ),
            ),
          ),
          // Tema Seçici
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: titleColor,
              size: 20,
            ),
            tooltip: isDark ? loc.translate('theme_light') : loc.translate('theme_dark'),
            onPressed: () => context.read<ThemeCubit>().toggleTheme(),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/new-post'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<AuthCubit, AuthState>(
            listener: (context, state) {
              context.read<FeedCubit>().fetchFeed();
              _scrollToTop();
            },
          ),
        ],
        child: BlocBuilder<FeedCubit, FeedState>(
          builder: (context, state) {
            if (state is FeedLoading) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
            }

            if (state is FeedError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: isDark ? Colors.white70 : AppTheme.mutedText),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<FeedCubit>().fetchFeed(),
                        child: const Text('Yenile'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is FeedLoaded) {
              final posts = state.posts;

              if (posts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.movie_creation_outlined, size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          loc.translate('no_posts_yet'),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: titleColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'İzlediğiniz ilk filmi veya favori bir repliğinizi paylaşın.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppTheme.mutedText),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/new-post'),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(loc.translate('new_post')),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                color: AppTheme.primaryColor,
                onRefresh: () async {
                  await context.read<FeedCubit>().fetchFeed();
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final postId = int.tryParse(post['id'].toString()) ?? 0;

                    return PostCard(
                      key: ValueKey(postId),
                      post: post,
                      onLikeToggle: () {
                        context.read<FeedCubit>().toggleLike(postId);
                      },
                      onCommentAdd: (comment) {
                        context.read<FeedCubit>().incrementCommentCount(postId);
                      },
                      onPostDeleted: (deletedId) {
                        context.read<FeedCubit>().fetchFeed();
                      },
                    );
                  },
                ),
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}
