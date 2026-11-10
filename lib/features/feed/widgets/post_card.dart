import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_constants.dart';
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
                        Text('${currentRating.toStringAsFixed(1)} / 10', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                      ],
                    ),
                    Slider(
                      value: currentRating,
                      min: 1.0,
                      max: 10.0,
                      divisions: 18,
                      activeColor: AppTheme.primaryColor,
                      label: currentRating.toStringAsFixed(1),
                      onChanged: (val) {
                        setDialogState(() {
                          currentRating = val;
                        });
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
      final postId = int.tryParse(_post['id'].toString()) ?? 0;
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
    final titleColor = isDark ? Colors.white : AppTheme.darkText;
    final mutedColor = isDark ? Colors.white60 : AppTheme.mutedText;
    final cardBorder = isDark ? AppTheme.darkCardBorder : AppTheme.borderColor;

    // Badge styling (.html spec)
    final badgeBg = isQuote ? AppTheme.quoteBadgeBg : AppTheme.reviewBadgeBg;
    final badgeText = isQuote ? AppTheme.quoteBadgeText : AppTheme.reviewBadgeText;
    final badgeLabel = isQuote ? 'Replik' : 'Yorum';

    // Rating value
    final ratingVal = double.tryParse(_post['rating']?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ShadCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Kullanıcı Bilgisi Satırı (.row: .av, name/username, badge)
            Row(
              children: [
                InkWell(
                  onTap: () {
                    final userId = _post['user_id'];
                    if (userId != null) {
                      context.push('/profile/$userId');
                    }
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Row(
                    children: [
                      if (_post['avatar'] != null && _post['avatar'].toString().isNotEmpty)
                        ShadAvatar(
                          _post['avatar'].toString(),
                          size: const Size.square(36),
                          placeholder: Text(
                            (_post['username'] ?? '?')[0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        )
                      else
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isQuote ? AppTheme.primaryColor : AppTheme.reviewAvatarBg,
                          ),
                          child: Center(
                            child: Text(
                              (_post['username'] ?? '?')[0].toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _post['full_name']?.isNotEmpty == true
                                ? _post['full_name']
                                : (_post['username'] ?? 'Kullanıcı'),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: titleColor,
                            ),
                          ),
                          Text(
                            '@${_post['username'] ?? 'anonim'}',
                            style: TextStyle(
                              color: mutedColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Pill Badge (Replik / Yorum)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeText,
                    ),
                  ),
                ),
                if (isMyPost) ...[
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, size: 20, color: mutedColor),
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

            // 2. Replik Alıntı Metni (border-left: 3.5px solid #F5A623)
            if (isQuote && _post['quote_text'] != null && _post['quote_text'].toString().isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 14),
                padding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppTheme.primaryColor, width: 3.5),
                  ),
                ),
                child: Text(
                  '“${_post['quote_text']}”',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                    height: 1.4,
                  ),
                ),
              ),

            // 3. Yorum / Rating yıldızları
            if (!isQuote && ratingVal != null)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Row(
                  children: [
                    const Text('★★★★★', style: TextStyle(color: AppTheme.primaryColor, fontSize: 16, letterSpacing: 1.5)),
                    const SizedBox(width: 6),
                    Text(
                      '${ratingVal.toStringAsFixed(1)}/10',
                      style: TextStyle(color: mutedColor, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

            // 4. Kullanıcı Düşüncesi / Yorum Metni
            if (_post['content'] != null && _post['content'].toString().isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: isQuote ? 0 : 4, bottom: 12),
                child: Text(
                  _post['content'],
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.white70 : const Color(0xFF22252A),
                  ),
                ),
              ),

            // 5. İlişkili Film / Dizi Kartı (.row style="background:#F7F8FA;border-radius:12px;padding:8px")
            if (_post['title'] != null && _post['title'].toString().isNotEmpty)
              InkWell(
                onTap: tmdbId != null ? () => context.push('/media/$mediaType/$tmdbId') : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF14151C) : AppTheme.mediaCardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardBorder, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: hasPoster
                            ? Image.network(
                                AppConstants.getPosterUrl(_post['poster_path']),
                                width: 52,
                                height: 75,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 52,
                                  height: 75,
                                  color: AppTheme.placeholderColor,
                                  child: const Icon(Icons.movie, color: Colors.grey, size: 28),
                                ),
                              )
                            : Container(
                                width: 52,
                                height: 75,
                                color: AppTheme.placeholderColor,
                                child: const Icon(Icons.movie, color: Colors.grey, size: 28),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _post['title'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: titleColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${mediaType == "tv" ? "Dizi" : "Film"}${_post["rating"] != null ? " · ★ ${_post["rating"]} / 10" : ""}',
                              style: TextStyle(fontSize: 12, color: mutedColor),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 20, color: mutedColor),
                    ],
                  ),
                ),
              ),

            // 6. Alt Çubuk (.g .row: ♡ 142 | 18 Yorum | Paylaş)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: cardBorder, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Beğeni
                  InkWell(
                    onTap: widget.onLikeToggle,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isLiked ? Colors.redAccent : mutedColor,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            likesCount.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isLiked ? FontWeight.w700 : FontWeight.w500,
                              color: isLiked ? Colors.redAccent : mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Yorum
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
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 17, color: mutedColor),
                          const SizedBox(width: 6),
                          Text(
                            '$commentsCount Yorum',
                            style: TextStyle(fontSize: 12, color: mutedColor),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Paylaş
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bağlantı kopyalandı! 🎬')),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined, size: 17, color: mutedColor),
                          const SizedBox(width: 6),
                          Text(
                            'Paylaş',
                            style: TextStyle(fontSize: 12, color: mutedColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
