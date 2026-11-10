import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../cubit/feed_cubit.dart';
import '../../profile/cubit/profile_cubit.dart';
import 'comments_modal.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback onLikeToggle;
  final Function(String comment)? onCommentAdd;
  final Function(Map<String, dynamic> updatedPost)? onPostUpdated;
  final Function(int postId)? onPostDeleted;

  const PostCard({
    super.key,
    required this.post,
    required this.onLikeToggle,
    this.onCommentAdd,
    this.onPostUpdated,
    this.onPostDeleted,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late Map<String, dynamic> _post;
  final ApiClient _api = ApiClient();

  @override
  void initState() {
    super.initState();
    _post = Map<String, dynamic>.from(widget.post);
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      _post = Map<String, dynamic>.from(widget.post);
    }
  }

  Future<void> _showEditPostDialog() async {
    final isQuote = _post['post_type'] == 'quote';
    final quoteController = TextEditingController(text: _post['quote_text'] ?? '');
    final contentController = TextEditingController(text: _post['content'] ?? '');
    double currentRating = double.tryParse(_post['rating']?.toString() ?? '') ?? 8.0;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Paylaşımı Düzenle', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isQuote) ...[
                    const Text('Replik Metni', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: quoteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Replik girin...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  const Text('Düşünceleriniz / Yorumunuz', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Açıklama veya yorumunuz...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_post['rating'] != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Puanınız:', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('${currentRating.toStringAsFixed(1)} / 10', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                      ],
                    ),
                    Slider(
                      value: currentRating,
                      min: 1.0,
                      max: 10.0,
                      divisions: 18,
                      label: currentRating.toStringAsFixed(1),
                      activeColor: Colors.amber,
                      onChanged: (val) {
                        setDialogState(() => currentRating = val);
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && mounted) {
      final postId = _post['id'];
      try {
        final body = <String, dynamic>{
          'content': contentController.text.trim(),
        };
        if (isQuote) body['quote_text'] = quoteController.text.trim();
        if (_post['rating'] != null) body['rating'] = currentRating;

        final res = await _api.put('/feed/post/$postId', body: body);
        if (res['status'] == true && res['data'] != null && mounted) {
          final updated = Map<String, dynamic>.from(res['data']);
          setState(() {
            _post = updated;
          });

          // Global state'leri anında senkronize et
          context.read<FeedCubit>().updatePostLocally(updated);
          context.read<ProfileCubit>().updatePostLocally(updated);
          widget.onPostUpdated?.call(updated);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paylaşım başarıyla güncellendi.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  Future<void> _showDeletePostDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paylaşımı Sil'),
        content: const Text('Bu paylaşımı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final postId = int.tryParse(_post['id'].toString()) ?? 0;
      try {
        final res = await _api.delete('/feed/post/$postId');
        if (res['status'] == true && mounted) {
          // Global state'leri anında senkronize et
          context.read<FeedCubit>().removePostLocally(postId);
          context.read<ProfileCubit>().removePostLocally(postId);
          widget.onPostDeleted?.call(postId);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paylaşım silindi.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isQuote = _post['post_type'] == 'quote';
    final hasPoster = _post['poster_path'] != null && _post['poster_path'].toString().isNotEmpty;
    final tmdbId = _post['tmdb_id'];
    final mediaType = _post['media_type'] ?? 'movie';
    final isLiked = _post['is_liked'] == true;
    final likesCount = _post['likes_count'] ?? '0';
    final commentsCount = _post['comments_count'] ?? '0';

    final authState = context.watch<AuthCubit>().state;
    final isLoggedIn = authState is Authenticated;
    final currentUserId = isLoggedIn ? (int.tryParse(authState.user['id']?.toString() ?? '') ?? 0) : 0;
    final postUserId = int.tryParse(_post['user_id']?.toString() ?? '') ?? 0;
    final isMyPost = isLoggedIn && currentUserId > 0 && (currentUserId == postUserId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kullanıcı Başlığı (Tıklandığında Profile gider)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      final userId = _post['user_id'];
                      if (userId != null) {
                        context.push('/profile/$userId');
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                            backgroundImage: (_post['avatar'] != null && _post['avatar'].toString().isNotEmpty)
                                ? NetworkImage(_post['avatar'])
                                : null,
                            child: (_post['avatar'] == null || _post['avatar'].toString().isEmpty)
                                ? Text(
                                    (_post['username'] ?? '?')[0].toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _post['full_name']?.isNotEmpty == true
                                      ? _post['full_name']
                                      : (_post['username'] ?? 'Kullanıcı'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  '@${_post['username'] ?? 'anonim'}',
                                  style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Etiket: Replik mi Yorum mu
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isQuote
                        ? Colors.amber.withOpacity(0.15)
                        : Colors.redAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isQuote ? Icons.format_quote : Icons.rate_review,
                        size: 14,
                        color: isQuote ? Colors.amber : Colors.redAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isQuote ? loc.translate('quotes') : loc.translate('reviews'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isQuote ? Colors.amber : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),

                // Kendi Postu İse Düzenle / Sil Menüsü
                if (isMyPost) ...[
                  const SizedBox(width: 2),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (val) {
                      if (val == 'edit') _showEditPostDialog();
                      if (val == 'delete') _showDeletePostDialog();
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Düzenle'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text('Sil', style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // Replik İçeriği
            if (isQuote && _post['quote_text'] != null && _post['quote_text'].toString().isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF222533)
                      : Colors.amber.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: const Border(left: BorderSide(color: Colors.amber, width: 4)),
                ),
                child: Text(
                  '“${_post['quote_text']}”',
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),

            // Kullanıcı Yorumu veya Ek Açıklaması
            if (_post['content'] != null && _post['content'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _post['content'],
                  style: const TextStyle(fontSize: 14.5, height: 1.4),
                ),
              ),

            // İlişkili Film / Dizi Kartı (Poster + Başlık + Puan)
            if (_post['title'] != null && _post['title'].toString().isNotEmpty)
              InkWell(
                onTap: tmdbId != null
                    ? () => context.push('/media/$mediaType/$tmdbId')
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF13151D)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF262835)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: hasPoster
                            ? Image.network(
                                AppConstants.getPosterUrl(_post['poster_path']),
                                width: 55,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 55,
                                  height: 80,
                                  color: Colors.grey.shade800,
                                  child: const Icon(Icons.movie, color: Colors.white54),
                                ),
                              )
                            : Container(
                                width: 55,
                                height: 80,
                                color: Colors.grey.shade800,
                                child: const Icon(Icons.movie, color: Colors.white54),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _post['title'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mediaType == 'tv' ? 'Dizi' : 'Film',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                            if (_post['rating'] != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_post['rating']} / 10',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white54),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Alt Butonlar: Beğen, Yorum, Paylaş
            Row(
              children: [
                // Beğeni Butonu
                InkWell(
                  onTap: widget.onLikeToggle,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : theme.iconTheme.color,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          likesCount.toString(),
                          style: TextStyle(
                            fontWeight: isLiked ? FontWeight.bold : FontWeight.normal,
                            color: isLiked ? Colors.red : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Yorum Butonu
                InkWell(
                  onTap: () {
                    final postId = int.parse(_post['id'].toString());
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useRootNavigator: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => CommentsModal(
                        postId: postId,
                        postUserId: postUserId,
                        onCommentAdded: () {
                          final currentCount = int.tryParse(_post['comments_count']?.toString() ?? '0') ?? 0;
                          setState(() {
                            _post['comments_count'] = (currentCount + 1).toString();
                          });
                          widget.onCommentAdd?.call('');
                        },
                        onCommentCountChanged: (newCount) {
                          setState(() {
                            _post['comments_count'] = newCount.toString();
                          });
                          context.read<FeedCubit>().updateCommentCount(postId, newCount);
                          context.read<ProfileCubit>().updatePostCommentCount(postId, newCount);
                        },
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 20, color: theme.iconTheme.color),
                        const SizedBox(width: 6),
                        Text(commentsCount.toString()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
