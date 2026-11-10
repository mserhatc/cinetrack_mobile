import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
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
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isFollowers = widget.type == 'followers';
    final title = isFollowers ? loc.translate('followers') : loc.translate('following');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Text(
                    isFollowers ? 'Henüz takipçi yok.' : 'Henüz kimse takip edilmiyor.',
                    style: TextStyle(color: theme.textTheme.bodySmall?.color),
                  ),
                )
              : ListView.separated(
                  itemCount: _users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final u = _users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundImage: (u['avatar'] != null && u['avatar'].toString().isNotEmpty)
                            ? NetworkImage(u['avatar'])
                            : null,
                        child: (u['avatar'] == null || u['avatar'].toString().isEmpty)
                            ? Text((u['username'] ?? '?')[0].toUpperCase())
                            : null,
                      ),
                      title: Text(
                        u['full_name']?.isNotEmpty == true ? u['full_name'] : u['username'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('@${u['username']}'),
                      onTap: () {
                        context.push('/profile/${u['id']}');
                      },
                    );
                  },
                ),
    );
  }
}

