import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../cubit/profile_cubit.dart';

class UserListScreen extends StatefulWidget {
  final String type; // 'followers' or 'following'
  final int userId;

  const UserListScreen({super.key, required this.type, required this.userId});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final cubit = context.read<ProfileCubit>();
    List<Map<String, dynamic>> list;
    if (widget.type == 'followers') {
      list = await cubit.getFollowers(widget.userId);
    } else {
      list = await cubit.getFollowing(widget.userId);
    }
    if (mounted) {
      setState(() {
        _users = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final titleColor = isDark ? Colors.white : AppTheme.darkText;
    final mutedColor = isDark ? Colors.white60 : AppTheme.mutedText;

    final loc = AppLocalizations.of(context);
    final isFollowers = widget.type == 'followers';
    final title = isFollowers ? loc.translate('followers') : loc.translate('following');

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: titleColor),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: titleColor,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _users.isEmpty
              ? Center(
                  child: Text(
                    isFollowers ? 'Henüz takipçi yok.' : 'Henüz kimse takip edilmiyor.',
                    style: TextStyle(color: mutedColor, fontSize: 14),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final u = _users[index];
                    final username = u['username'] ?? '';
                    final fullName = u['full_name']?.isNotEmpty == true ? u['full_name'] : username;
                    final avatar = u['avatar'];

                    return GestureDetector(
                      onTap: () => context.push('/profile/${u['id']}'),
                      child: ShadCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            if (avatar != null && avatar.toString().isNotEmpty)
                              ShadAvatar(
                                avatar.toString(),
                                size: const Size.square(48),
                                placeholder: Text(
                                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                              )
                            else
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                                ),
                                child: Center(
                                  child: Text(
                                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: titleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '@$username',
                                    style: TextStyle(color: mutedColor, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: mutedColor),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
