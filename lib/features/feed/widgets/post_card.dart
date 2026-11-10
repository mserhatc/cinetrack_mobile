import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
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

    final result = await showShadDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return ShadDialog(
            title: const Text('Paylaşımı Düzenle'),
            actions: [
              ShadButton.outline(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
              ShadButton(
                onPressed: () => Navigator.pop(ctx, true),
                backgroundColor: AppTheme.primaryColor,
                child: const Text('Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isQuote) ...[
                    const Text('Replik Metni', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    ShadInput(
                      controller: quoteController,
                      maxLines: 3,
                      placeholder: const Text('Replik girin...'),
                    ),
                    const SizedBox(height: 14),
                  ],
                  const Text('Düşünceleriniz / Yorumunuz', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  ShadInput(
                    controller: contentController,
                    maxLines: 4,
                    placeholder: const Text('Açıklama veya yorumunuz...'),
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
    final confirm = await showShadDialog<bool>(
      context: context,
      builder: (ctx) => ShadDialog.alert(
        title: const Text('Paylaşımı Sil'),
        description: const Text('Bu paylaşımı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          ShadButton.outline(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ShadButton.destructive(
            onPressed: () => Navigator.pop(ctx, true),
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

    final isDark = theme.brightness == Brightness.dark;
    final cardBorder = isDark ? const Color(0xFF232634) : const Color(0xFFEEEEF2);
    final titleColor = isDark ? Colors.white : const Color(0xFF14171A);
    final mutedColor = isDark ? Colors.white60 : const Color(0xFF8A90A0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ShadCard(
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
                          if (_post['avatar'] != null && _post['avatar'].toString().isNotEmpty)
                            ShadAvatar(
                              _post['avatar'].toString(),
                              size: const Size.square(40),
                              placeholder: Text(
                                (_post['username'] ?? '?')[0].toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            )
                          else
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                              ),
                              child: Center(
                                child: Text(
                                  (_post['username'] ?? '?')[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
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
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: titleColor),
                                ),
                                Text(
                                  '@${_post['username'] ?? 'anonim'}',
                                  style: TextStyle(color: mutedColor, fontSize: 12),
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
                // ShadBadge: Replik mi Yorum mu
                ShadBadge.secondary(
                  backgroundColor: isQuote
                      ? AppTheme.primaryColor.withValues(alpha: 0.12)
                      : const Color(0xFF2ECC71).withValues(alpha: 0.12),
                  foregroundColor: isQuote ? AppTheme.primaryColor : const Color(0xFF2ECC71),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isQuote ? Icons.format_quote_rounded : Icons.rate_review_outlined,
                        size: 13,
                        color: isQuote ? AppTheme.primaryColor : const Color(0xFF2ECC71),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isQuote ? loc.translate('quotes') : loc.translate('reviews'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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

            // Replik İçeriği (Movie Explorer Alıntı Kartı)
            if (isQuote && _post['quote_text'] != null && _post['quote_text'].toString().isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF13151D) : const Color(0xFFFDFBF7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border(left: BorderSide(color: AppTheme.primaryColor, width: 3.5)),
                ),
                child: Text(
                  '“${_post['quote_text']}”',
                  style: TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                    height: 1.4,
                  ),
                ),
              ),

            // Kullanıcı Yorumu veya Ek Açıklaması
            if (_post['content'] != null && _post['content'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _post['content'],
                  style: TextStyle(fontSize: 14, height: 1.45, color: isDark ? Colors.white70 : const Color(0xFF3E434D)),
                ),
              ),

            // İlişkili Film / Dizi Kartı (Movie Explorer Tarzı)
            if (_post['title'] != null && _post['title'].toString().isNotEmpty)
              InkWell(
                onTap: tmdbId != null
                    ? () => context.push('/media/$mediaType/$tmdbId')
                    : null,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF13151D) : const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder, width: 1),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: hasPoster
                            ? Image.network(
                                AppConstants.getPosterUrl(_post['poster_path']),
                                width: 52,
                                height: 75,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 52,
                                  height: 75,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.movie, color: Colors.grey),
                                ),
                              )
                            : Container(
                                width: 52,
                                height: 75,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.movie, color: Colors.grey),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _post['title'] ?? '',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: titleColor),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mediaType == 'tv' ? 'Dizi' : 'Film',
                              style: TextStyle(fontSize: 12, color: mutedColor),
                            ),
                            if (_post['rating'] != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: AppTheme.starColor, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_post['rating']} / 10',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: titleColor),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: mutedColor),
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
