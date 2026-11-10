import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../feed/cubit/feed_cubit.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../cubit/create_post_cubit.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quoteController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  Map<String, dynamic>? _selectedMedia;
  double _rating = 8.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _quoteController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onMediaSelected(Map<String, dynamic> media) {
    setState(() {
      _selectedMedia = media;
    });
    Navigator.of(context).pop();
  }

  void _showMediaSearchDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BlocProvider.value(
          value: context.read<CreatePostCubit>(),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final theme = Theme.of(context);
              return Container(
                height: MediaQuery.of(context).size.height * 0.8,
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Film veya dizi ara...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            context.read<CreatePostCubit>().searchMedia('');
                          },
                        ),
                      ),
                      onChanged: (val) {
                        context.read<CreatePostCubit>().searchMedia(val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: BlocBuilder<CreatePostCubit, CreatePostState>(
                        builder: (context, state) {
                          if (state is CreatePostSearching) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (state is CreatePostSearchResults) {
                            final list = state.results;
                            if (list.isEmpty) {
                              return const Center(child: Text('Sonuç bulunamadı.'));
                            }
                            return ListView.separated(
                              itemCount: list.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = list[index];
                                final title = item['title'] ?? item['name'] ?? 'İsimsiz';
                                final poster = item['poster_path'];
                                final type = item['media_type'] == 'tv' ? 'Dizi' : 'Film';
                                final year = (item['release_date'] ?? item['first_air_date'] ?? '').toString();

                                return ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: poster != null
                                        ? Image.network(
                                            AppConstants.getPosterUrl(poster),
                                            width: 45,
                                            height: 65,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 45,
                                            height: 65,
                                            color: Colors.grey.shade800,
                                            child: const Icon(Icons.movie, size: 20),
                                          ),
                                  ),
                                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('$type • ${year.length >= 4 ? year.substring(0, 4) : ''}'),
                                  trailing: const Icon(Icons.add_circle_outline, color: Colors.redAccent),
                                  onTap: () => _onMediaSelected(item),
                                );
                              },
                            );
                          }
                          return const Center(
                            child: Text('Aramak için film veya dizi adı yazın.'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _resetForm() {
    _selectedMedia = null;
    _quoteController.clear();
    _contentController.clear();
    _searchController.clear();
    _rating = 8.0;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _submitPost() async {
    final authCubit = context.read<AuthCubit>();
    if (!authCubit.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce giriş yapın.')),
      );
      context.push('/login');
      return;
    }

    final isQuote = _tabController.index == 0;
    final quoteText = _quoteController.text.trim();
    final content = _contentController.text.trim();

    if (isQuote && quoteText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir replik yazın.')),
      );
      return;
    }

    if (!isQuote && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen yorumunuzu yazın.')),
      );
      return;
    }

    final success = await context.read<CreatePostCubit>().createPost(
      postType: isQuote ? 'quote' : 'review',
      tmdbId: _selectedMedia != null ? int.tryParse(_selectedMedia!['id'].toString()) : null,
      mediaType: _selectedMedia != null ? (_selectedMedia!['media_type'] ?? 'movie') : 'movie',
      title: _selectedMedia != null ? (_selectedMedia!['title'] ?? _selectedMedia!['name']) : null,
      posterPath: _selectedMedia != null ? _selectedMedia!['poster_path'] : null,
      quoteText: isQuote ? quoteText : null,
      content: content.isNotEmpty ? content : (isQuote ? 'Bu repliği paylaştı.' : ''),
      rating: !isQuote ? _rating : null,
    );

    if (success && mounted) {
      _resetForm();
      context.read<FeedCubit>().fetchFeed();
      context.read<ProfileCubit>().loadProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paylaşımınız başarıyla yayınlandı! 🎉')),
      );
      context.go('/feed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final authState = context.watch<AuthCubit>().state;

    if (authState is! Authenticated) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.translate('new_post'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  loc.translate('must_login'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.push('/login'),
                  child: Text(loc.translate('login')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('new_post')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Formu Temizle',
            onPressed: _resetForm,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          tabs: [
            Tab(icon: const Icon(Icons.format_quote), text: loc.translate('post_quote')),
            Tab(icon: const Icon(Icons.rate_review), text: loc.translate('post_review')),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Seçilen Film / Dizi Kutusu veya Ekleme Butonu
            if (_selectedMedia == null)
              OutlinedButton.icon(
                onPressed: _showMediaSearchDialog,
                icon: const Icon(Icons.movie_creation_outlined),
                label: Text(loc.translate('search_media')),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        AppConstants.getPosterUrl(_selectedMedia!['poster_path']),
                        width: 50,
                        height: 75,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedMedia!['title'] ?? _selectedMedia!['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedMedia!['media_type'] == 'tv' ? 'Dizi' : 'Film',
                            style: TextStyle(color: theme.textTheme.bodySmall?.color),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.redAccent),
                      onPressed: () => setState(() => _selectedMedia = null),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 18),

            // Tab View İçerikleri
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                final isQuote = _tabController.index == 0;

                if (isQuote) {
                  // Replik Paylaşım Alanı
                  return Column(
                    children: [
                      TextField(
                        controller: _quoteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: loc.translate('write_quote'),
                          prefixIcon: const Icon(Icons.format_quote),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _contentController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Replik hakkında yorumunuz veya sahne detayı (isteğe bağlı)...',
                          prefixIcon: Icon(Icons.comment_outlined),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Yorum ve Puan Alanı
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Puan Seçici
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Puanınız:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  '$_rating / 10',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _rating,
                        min: 1.0,
                        max: 10.0,
                        divisions: 18, // 0.5 aralıklarla
                        activeColor: Colors.amber,
                        label: '$_rating',
                        onChanged: (val) => setState(() => _rating = (val * 2).round() / 2),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _contentController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: loc.translate('write_review'),
                          prefixIcon: const Icon(Icons.rate_review_outlined),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 24),

            // Paylaş Butonu
            BlocBuilder<CreatePostCubit, CreatePostState>(
              builder: (context, state) {
                final isSubmitting = state is CreatePostSubmitting;
                return ElevatedButton(
                  onPressed: isSubmitting ? null : _submitPost,
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(loc.translate('share')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

