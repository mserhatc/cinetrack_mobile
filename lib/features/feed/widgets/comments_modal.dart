import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../cubit/feed_cubit.dart';

class CommentsModal extends StatefulWidget {
  final int postId;
  final int? postUserId;
  final VoidCallback? onCommentAdded;
  final Function(int count)? onCommentCountChanged;

  const CommentsModal({
    super.key,
    required this.postId,
    this.postUserId,
    this.onCommentAdded,
    this.onCommentCountChanged,
  });

  @override
  State<CommentsModal> createState() => _CommentsModalState();
}

class _CommentsModalState extends State<CommentsModal> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiClient _api = ApiClient();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final res = await _api.get('/feed/comments/${widget.postId}');
      if (res['status'] == true && res['data'] != null && mounted) {
        setState(() {
          _comments = List<Map<String, dynamic>>.from(res['data']);
          _isLoading = false;
        });
        _scrollToBottom(animate: false);
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final target = _scrollController.position.maxScrollExtent;
        if (animate) {
          _scrollController.animateTo(
            target,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(target);
        }
      }
    });
  }

  Future<void> _submitComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    final authCubit = context.read<AuthCubit>();
    final authState = authCubit.state;
    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yorum yapmak için lütfen önce giriş yapın.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final currentUser = authCubit.currentUser ?? {};
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    // 1. ANLIK GÖRÜNTÜLEME (Optimistic Update)
    final tempComment = <String, dynamic>{
      'id': tempId,
      'post_id': widget.postId,
      'user_id': currentUser['id'],
      'username': currentUser['username'] ?? 'Ben',
      'full_name': currentUser['full_name'],
      'avatar': currentUser['avatar'],
      'comment': text,
      'likes_count': 0,
      'is_liked': false,
      'created_at': DateTime.now().toIso8601String(),
      'is_pending': true,
    };

    setState(() {
      _comments = List<Map<String, dynamic>>.from(_comments)..add(tempComment);
      _controller.clear();
      _isSending = true;
    });

    _scrollToBottom(animate: true);

    // Ana ekrandaki kartın yorum sayısını anında artır
    if (mounted) {
      context.read<FeedCubit>().incrementCommentCount(widget.postId);
    }
    widget.onCommentAdded?.call();
    widget.onCommentCountChanged?.call(_comments.length);

    // 2. Sunucuya Gönderim
    try {
      final response = await _api.post('/feed/comment/${widget.postId}', body: {'comment': text});
      if (response['status'] == true && mounted) {
        final serverData = response['data'];
        setState(() {
          final idx = _comments.indexWhere((c) => c['id'].toString() == tempId);
          if (idx != -1) {
            if (serverData != null && serverData is Map) {
              _comments[idx] = Map<String, dynamic>.from(serverData);
            } else {
              _comments[idx]['is_pending'] = false;
            }
          }
          _isSending = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Yorum gönderilemedi.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _comments.removeWhere((c) => c['id'].toString() == tempId);
          _isSending = false;
        });
        widget.onCommentCountChanged?.call(_comments.length);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _toggleCommentLike(Map<String, dynamic> comment) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorum beğenmek için lütfen giriş yapın.')),
      );
      return;
    }

    final commentId = comment['id'];
    if (commentId == null || comment['is_pending'] == true) return;

    final wasLiked = comment['is_liked'] == true;
    final currentLikes = int.tryParse(comment['likes_count']?.toString() ?? '0') ?? 0;

    // Optimistik güncelle
    setState(() {
      comment['is_liked'] = !wasLiked;
      comment['likes_count'] = wasLiked ? (currentLikes - 1) : (currentLikes + 1);
    });

    try {
      final res = await _api.post('/feed/comment/like/$commentId');
      if (res['status'] == true && res['data'] != null && mounted) {
        setState(() {
          comment['is_liked'] = res['data']['is_liked'];
          comment['likes_count'] = res['data']['likes_count'];
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          comment['is_liked'] = wasLiked;
          comment['likes_count'] = currentLikes;
        });
      }
    }
  }

  Future<void> _editComment(Map<String, dynamic> comment) async {
    final editController = TextEditingController(text: comment['comment'] ?? '');
    final updated = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yorumu Düzenle', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: editController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Yorumunuzu güncelleyin...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              final text = editController.text.trim();
              if (text.isNotEmpty) Navigator.pop(ctx, text);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (updated != null && updated != comment['comment'] && mounted) {
      final commentId = comment['id'];
      try {
        final res = await _api.put('/feed/comment/$commentId', body: {'comment': updated});
        if (res['status'] == true && mounted) {
          setState(() {
            comment['comment'] = updated;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yorum güncellendi.')),
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

  Future<void> _deleteComment(Map<String, dynamic> comment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yorumu Sil'),
        content: const Text('Bu yorumu silmek istediğinize emin misiniz?'),
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
      final commentId = comment['id'];
      try {
        final res = await _api.delete('/feed/comment/$commentId');
        if (res['status'] == true && mounted) {
          setState(() {
            _comments.removeWhere((c) => c['id'].toString() == commentId.toString());
          });
          context.read<FeedCubit>().decrementCommentCount(widget.postId);
          widget.onCommentCountChanged?.call(_comments.length);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yorum silindi.')),
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
    final viewInsets = MediaQuery.of(context).viewInsets;
    final authState = context.watch<AuthCubit>().state;
    final isLoggedIn = authState is Authenticated;
    final currentUserId = isLoggedIn ? (int.tryParse(authState.user['id']?.toString() ?? '') ?? 0) : 0;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Container(
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark ? const Color(0xFF171922) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Çekme çubuğu ve Başlık
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${loc.translate('comments')} (${_comments.length})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEEEEF2)),

              // Yorum Listesi
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _comments.isEmpty
                        ? Center(
                            child: Text(
                              'Henüz yorum yapılmamış. İlk yorumu sen yap!',
                              style: TextStyle(color: theme.textTheme.bodySmall?.color),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              final c = _comments[index];
                              final avatar = c['avatar'];
                              final username = c['username'] ?? '?';
                              final fullName = c['full_name'];
                              final isPending = c['is_pending'] == true;
                              final commentUserId = int.tryParse(c['user_id']?.toString() ?? '') ?? 0;
                              final isMyComment = isLoggedIn && (commentUserId == currentUserId);
                              final canDelete = isMyComment || (widget.postUserId != null && widget.postUserId == currentUserId);
                              final isLiked = c['is_liked'] == true;
                              final likesCount = int.tryParse(c['likes_count']?.toString() ?? '0') ?? 0;

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Profil Resmi
                                    GestureDetector(
                                      onTap: () {
                                        final uid = c['user_id'];
                                        if (uid != null) {
                                          Navigator.of(context, rootNavigator: true).pop();
                                          context.push('/profile/$uid');
                                        }
                                      },
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.primaryColor,
                                        ),
                                        child: ClipOval(
                                          child: (avatar != null && avatar.toString().isNotEmpty)
                                              ? Image.network(
                                                  avatar.toString(),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) => Center(
                                                    child: Text(
                                                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                                    ),
                                                  ),
                                                )
                                              : Center(
                                                  child: Text(
                                                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    // Yorum İçeriği
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  final uid = c['user_id'];
                                                  if (uid != null) {
                                                    Navigator.of(context, rootNavigator: true).pop();
                                                    context.push('/profile/$uid');
                                                  }
                                                },
                                                child: Text(
                                                  fullName != null && fullName.toString().isNotEmpty ? fullName : username,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                                ),
                                              ),
                                              if (isPending) ...[
                                                const SizedBox(width: 6),
                                                const SizedBox(
                                                  width: 10,
                                                  height: 10,
                                                  child: CircularProgressIndicator(strokeWidth: 1.5),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            c['comment'] ?? '',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isPending ? theme.textTheme.bodySmall?.color : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Sağ Alan: Beğeni Butonu + İşlemler Menüsü
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Beğeni Butonu
                                        InkWell(
                                          onTap: () => _toggleCommentLike(c),
                                          borderRadius: BorderRadius.circular(16),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                                  size: 16,
                                                  color: isLiked ? Colors.redAccent : Colors.grey,
                                                ),
                                                if (likesCount > 0) ...[
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    '$likesCount',
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight: isLiked ? FontWeight.bold : FontWeight.normal,
                                                      color: isLiked ? Colors.redAccent : Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),

                                        // Düzenle / Sil Menüsü
                                        if (isMyComment || canDelete)
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            onSelected: (val) {
                                              if (val == 'edit') _editComment(c);
                                              if (val == 'delete') _deleteComment(c);
                                            },
                                            itemBuilder: (ctx) => [
                                              if (isMyComment)
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
                                              if (canDelete)
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
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),

              // Alt Alan: Yorum Yazma veya Giriş Yap Butonu
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color ?? theme.cardColor,
                    border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
                  ),
                  child: isLoggedIn
                      ? Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                decoration: const InputDecoration(
                                  hintText: 'Bir yorum yaz...',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                onSubmitted: (_) => _submitComment(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.send_rounded, color: AppTheme.primaryColor),
                              onPressed: _submitComment,
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Yorum yapabilmek için lütfen giriş yapın.',
                                style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context, rootNavigator: true).pop();
                                context.push('/login');
                              },
                              child: const Text('Giriş Yap'),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
