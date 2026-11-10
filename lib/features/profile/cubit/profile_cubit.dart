import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_client.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}
class ProfileLoading extends ProfileState {}
class ProfileLoaded extends ProfileState {
  final Map<String, dynamic> user;
  final List<Map<String, dynamic>> userPosts;
  ProfileLoaded({required this.user, required this.userPosts});
}
class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}

class ProfileCubit extends Cubit<ProfileState> {
  final ApiClient _api = ApiClient();

  ProfileCubit() : super(ProfileInitial());

  Future<void> loadProfile({int? userId}) async {
    emit(ProfileLoading());
    try {
      final profileUrl = userId != null ? '/auth/profile/$userId' : '/auth/profile';
      final postsUrl = userId != null ? '/feed/user/$userId' : '/feed/user';

      final results = await Future.wait([
        _api.get(profileUrl),
        _api.get(postsUrl),
      ]);

      final profileResp = results[0];
      final postsResp = results[1];

      if (profileResp['status'] == true && profileResp['data'] != null) {
        final userData = Map<String, dynamic>.from(profileResp['data']);
        final posts = postsResp['data'] != null
            ? List<Map<String, dynamic>>.from(postsResp['data'])
            : <Map<String, dynamic>>[];

        emit(ProfileLoaded(user: userData, userPosts: posts));
      } else {
        emit(ProfileError('Profil yüklenemedi.'));
      }
    } catch (e) {
      emit(ProfileError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<bool> toggleFollow(int userId) async {
    try {
      final res = await _api.post('/user/follow/$userId');
      if (res['status'] == true && res['data'] != null) {
        if (state is ProfileLoaded) {
          final cur = state as ProfileLoaded;
          final updatedUser = Map<String, dynamic>.from(cur.user);
          final stats = Map<String, dynamic>.from(updatedUser['stats'] ?? {});
          stats['is_following'] = res['data']['is_following'];
          stats['followers'] = res['data']['followers_count'];
          updatedUser['stats'] = stats;
          emit(ProfileLoaded(user: updatedUser, userPosts: cur.userPosts));
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  void removePostLocally(int postId) {
    if (state is! ProfileLoaded) return;
    final cur = state as ProfileLoaded;
    final posts = List<Map<String, dynamic>>.from(cur.userPosts);
    posts.removeWhere((p) => p['id'].toString() == postId.toString());
    final user = Map<String, dynamic>.from(cur.user);
    final stats = Map<String, dynamic>.from(user['stats'] ?? {});
    final currentCount = int.tryParse(stats['posts_count']?.toString() ?? '1') ?? 1;
    stats['posts_count'] = currentCount > 0 ? currentCount - 1 : 0;
    user['stats'] = stats;
    emit(ProfileLoaded(user: user, userPosts: posts));
  }

  void updatePostLocally(Map<String, dynamic> updatedPost) {
    if (state is! ProfileLoaded) return;
    final cur = state as ProfileLoaded;
    final posts = List<Map<String, dynamic>>.from(cur.userPosts);
    final idx = posts.indexWhere((p) => p['id'].toString() == updatedPost['id'].toString());
    if (idx != -1) {
      posts[idx] = updatedPost;
      emit(ProfileLoaded(user: cur.user, userPosts: posts));
    }
  }

  void updatePostCommentCount(int postId, int count) {
    if (state is! ProfileLoaded) return;
    final cur = state as ProfileLoaded;
    final posts = List<Map<String, dynamic>>.from(cur.userPosts);
    final idx = posts.indexWhere((p) => p['id'].toString() == postId.toString());
    if (idx != -1) {
      final post = Map<String, dynamic>.from(posts[idx]);
      post['comments_count'] = count.toString();
      posts[idx] = post;
      emit(ProfileLoaded(user: cur.user, userPosts: posts));
    }
  }

  void updateProfileLocally(Map<String, dynamic> updatedUserData) {
    if (state is! ProfileLoaded) return;
    final cur = state as ProfileLoaded;
    final user = Map<String, dynamic>.from(cur.user);
    user.addAll(updatedUserData);
    emit(ProfileLoaded(user: user, userPosts: cur.userPosts));
  }

  Future<List<Map<String, dynamic>>> getWatchedMovies(int userId) async {
    try {
      final res = await _api.get('/user/watched/movies/$userId');
      if (res['status'] == true && res['data'] != null) {
        return List<Map<String, dynamic>>.from(res['data']);
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> getWatchedShows(int userId) async {
    try {
      final res = await _api.get('/user/watched/shows/$userId');
      if (res['status'] == true && res['data'] != null) {
        return List<Map<String, dynamic>>.from(res['data']);
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> getFollowers(int userId) async {
    try {
      final res = await _api.get('/user/followers/$userId');
      if (res['status'] == true && res['data'] != null) {
        return List<Map<String, dynamic>>.from(res['data']);
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> getFollowing(int userId) async {
    try {
      final res = await _api.get('/user/following/$userId');
      if (res['status'] == true && res['data'] != null) {
        return List<Map<String, dynamic>>.from(res['data']);
      }
    } catch (_) {}
    return [];
  }
}

