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
    final pillBg = isDark ? AppTheme.darkCard : AppTheme.softGreyBg;

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 76, right: 4),
        child: GestureDetector(
          onTap: () => context.push('/new-post'),
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryGradientStart,
                  AppTheme.primaryGradientEnd,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.42),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.add_rounded, size: 32, color: Colors.white),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Üst Başlık: Sol "Feed", Sağ "TR" Hapı ve "☾" Tema Butonu (PDF Page 3)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _scrollToTop,
                    child: Text(
                      'Feed',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        color: titleColor,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      // TR Dil Seçici Hapı
                      GestureDetector(
                        onTap: () => context.read<LanguageCubit>().toggleLanguage(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: pillBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            currentLang.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: titleColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // ☾ Tema Değiştirici Yuvarlak Buton
                      GestureDetector(
                        onTap: () => context.read<ThemeCubit>().toggleTheme(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: pillBg,
                          ),
                          child: Icon(
                            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                            color: titleColor,
                            size: 19,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Akış Listesi
            Expanded(
              child: MultiBlocListener(
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
                      return const Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryColor),
                      );
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
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: titleColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'İzlediğiniz ilk filmi veya favori bir repliğinizi paylaşın.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13.5, color: AppTheme.mutedText),
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
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
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
            ),
          ],
        ),
      ),
    );
  }
}
