import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (trimmed.length >= 2) {
      return trimmed.substring(0, 2).toUpperCase();
    }
    return trimmed[0].toUpperCase();
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Paylaşımı Düzenle', style: TextStyle(fontWeight: FontWeight.w800)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isQuote) ...[
                    const Text('Replik Metni', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: quoteController,
                      maxLines: 3,
                      decoration: const InputDecoration(hintText: 'Replik girin...'),
                    ),
                    const SizedBox(height: 14),
                  ],
                  const Text('Düşünceleriniz / Yorumunuz', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: const InputDecoration(hintText: 'Açıklama veya yorumunuz...'),
                  ),
                  if (_post['rating'] != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Puanınız:', style: TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                          '${currentRating.toStringAsFixed(1)} / 10',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                    Slider(
                      value: currentRating,
                      min: 1.0,
                      max: 10.0,
                      divisions: 18,
                      activeColor: AppTheme.primaryColor,
                      label: currentRating.toStringAsFixed(1),
                      onChanged: (val) => setDialogState(() => currentRating = val),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal', style: TextStyle(color: AppTheme.mutedText)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Paylaşımı Sil', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Bu paylaşımı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal', style: TextStyle(color: AppTheme.mutedText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.heartRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final titleColor = isDark ? Colors.white : AppTheme.darkText;
    final mutedColor = isDark ? Colors.white60 : AppTheme.mutedText;

    final badgeBg = isQuote ? AppTheme.quoteBadgeBg : AppTheme.reviewBadgeBg;
    final badgeText = isQuote ? AppTheme.quoteBadgeText : AppTheme.reviewBadgeText;
    final badgeLabel = isQuote ? 'Replik' : 'Yorum';

    final displayName = _post['full_name']?.toString().isNotEmpty == true
        ? _post['full_name'].toString()
        : (_post['username']?.toString() ?? 'Kullanıcı');
    final username = _post['username']?.toString() ?? 'kullanici';
    final ratingVal = double.tryParse(_post['rating']?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppTheme.darkCardBorder : const Color(0xFFF1F2F6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Üst Kullanıcı Satırı (Avatar, İsim + @username · 2s, Replik/Yorum Rozeti - PDF Page 3)
          Row(
            children: [
              InkWell(
                onTap: () {
                  final userId = _post['user_id'];
                  if (userId != null) {
                    context.push('/profile/$userId');
                  }
                },
                borderRadius: BorderRadius.circular(24),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isQuote ? AppTheme.quoteAvatarBg : AppTheme.reviewAvatarBg,
                      ),
                      child: ClipOval(
                        child: (_post['avatar'] != null && _post['avatar'].toString().isNotEmpty)
                            ? Image.network(
                                _post['avatar'].toString(),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Center(
                                  child: Text(
                                    _getInitials(displayName),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  _getInitials(displayName),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '@$username · ${isQuote ? "2s" : "5s"}',
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: badgeText,
                  ),
                ),
              ),
              if (isMyPost) ...[
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz_rounded, size: 20, color: mutedColor),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

          // 2. Replik Alıntı Metni (Sol kalın amber çizgi + İtalik kalın yazı)
          if (isQuote && _post['quote_text'] != null && _post['quote_text'].toString().isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 16, bottom: 14),
              padding: const EdgeInsets.only(left: 14, top: 2, bottom: 2),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppTheme.primaryColor, width: 4),
                ),
              ),
              child: Text(
                '“${_post['quote_text']}”',
                style: TextStyle(
                  fontSize: 17,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                  height: 1.35,
                ),
              ),
            ),

          // 3. Yorum Puan Yıldızları (★★★★★ 9.0/10)
          if (!isQuote && ratingVal != null)
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 8),
              child: Row(
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return const Padding(
                        padding: EdgeInsets.only(right: 2),
                        child: Icon(Icons.star_rounded, color: AppTheme.starColor, size: 18),
                      );
                    }),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${ratingVal.toStringAsFixed(1)}/10',
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

          // 4. Yorum / Açıklama Metni
          if (_post['content'] != null &&
              _post['content'].toString().isNotEmpty &&
              (!isQuote || _post['content'] != 'Bu repliği paylaştı.'))
            Padding(
              padding: EdgeInsets.only(top: isQuote ? 0 : 2, bottom: 12),
              child: Text(
                _post['content'].toString(),
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.5,
                  color: isDark ? Colors.white70 : const Color(0xFF27272A),
                ),
              ),
            ),

          // 5. İlişkili Film / Dizi Kutusu (Apollo 13 - Film · ★ 8.6 / 10 - PDF Page 3)
          if (_post['title'] != null && _post['title'].toString().isNotEmpty)
            InkWell(
              onTap: tmdbId != null ? () => context.push('/media/$mediaType/$tmdbId') : null,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF14171F) : AppTheme.mediaCardBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 76,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: hasPoster
                            ? Image.network(
                                AppConstants.getPosterUrl(_post['poster_path']),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const SizedBox.shrink(),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _post['title'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: titleColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${mediaType == "tv" ? "Dizi" : "Film"} · ',
                                style: TextStyle(fontSize: 13, color: mutedColor),
                              ),
                              const Icon(Icons.star_rounded, color: AppTheme.starColor, size: 15),
                              const SizedBox(width: 3),
                              Text(
                                '${_post["rating"] ?? "8.6"} / 10',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: mutedColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 6. Alt Etkileşim Çubuğu (❤️ 142   💬 18   ◁ Paylaş - PDF Page 3)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Beğeni
                InkWell(
                  onTap: widget.onLikeToggle,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          color: isLiked ? AppTheme.heartRed : AppTheme.heartRed.withValues(alpha: 0.85),
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          likesCount.toString(),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.heartRed,
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
                          final currentCount =
                              int.tryParse(_post['comments_count']?.toString() ?? '0') ?? 0;
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
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 18, color: mutedColor),
                        const SizedBox(width: 6),
                        Text(
                          commentsCount.toString(),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Paylaş
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Paylaşım bağlantısı kopyalandı! 🎬')),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.send_outlined, size: 18, color: mutedColor),
                        const SizedBox(width: 6),
                        Text(
                          'Paylaş',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: mutedColor,
                          ),
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
    );
  }
}
