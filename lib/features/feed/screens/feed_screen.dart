import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/language_cubit.dart';
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
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isDark = context.watch<ThemeCubit>().isDarkMode;
    final currentLang = context.watch<LanguageCubit>().state.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _scrollToTop,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.movie_filter_rounded, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 8),
              Text(
                'CINETRACK',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Dil Değiştirme Butonu
          TextButton(
            onPressed: () => context.read<LanguageCubit>().toggleLanguage(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                currentLang.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          // Tema Değiştirme Butonu (Aydınlık / Karanlık)
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip: isDark ? loc.translate('theme_light') : loc.translate('theme_dark'),
            onPressed: () => context.read<ThemeCubit>().toggleTheme(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          // Logout veya Login durumunda feed'i yeniden çek ve en başa dön
          BlocListener<AuthCubit, AuthState>(
            listener: (context, state) {
              context.read<FeedCubit>().fetchFeed();
              _scrollToTop();
            },
          ),
          // Yeni post yayınlandığında veya feed güncellendiğinde başa dön
          BlocListener<FeedCubit, FeedState>(
            listener: (context, state) {
              if (state is FeedLoaded) {
                // Eğer sayfanın tepesine yakınsa yumuşakça 0'a çek
                if (_scrollController.hasClients && _scrollController.offset < 300) {
                  _scrollToTop();
                }
              }
            },
          ),
        ],
        child: BlocBuilder<FeedCubit, FeedState>(
          builder: (context, state) {
            if (state is FeedLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is FeedError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 54, color: Colors.grey.shade600),
                    const SizedBox(height: 12),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<FeedCubit>().fetchFeed(),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              );
            }

            if (state is FeedLoaded) {
              final posts = state.posts;

              if (posts.isEmpty) {
                return Center(
                  child: Text(
                    loc.translate('no_posts_yet'),
                    style: TextStyle(color: theme.textTheme.bodySmall?.color),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await context.read<FeedCubit>().fetchFeed();
                  _scrollToTop();
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final postId = int.tryParse(post['id'].toString()) ?? 0;

                    return PostCard(
                      key: ValueKey('post_${post['id']}'),
                      post: post,
                      onLikeToggle: () => context.read<FeedCubit>().toggleLike(postId),
                      onPostDeleted: (deletedId) {
                        context.read<FeedCubit>().removePostLocally(deletedId);
                      },
                      onPostUpdated: (updatedPost) {
                        context.read<FeedCubit>().updatePostLocally(updatedPost);
                      },
                    );
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
