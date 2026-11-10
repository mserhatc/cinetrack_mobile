import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_client.dart';

abstract class FeedState {}

class FeedInitial extends FeedState {}
class FeedLoading extends FeedState {}
class FeedLoaded extends FeedState {
  final List<Map<String, dynamic>> posts;
  FeedLoaded(this.posts);
}
class FeedError extends FeedState {
  final String message;
  FeedError(this.message);
}

class FeedCubit extends Cubit<FeedState> {
  final ApiClient _api = ApiClient();

  FeedCubit() : super(FeedInitial());

  Future<void> fetchFeed() async {
    emit(FeedLoading());
    try {
      final response = await _api.get('/feed');
      if (response['status'] == true && response['data'] != null) {
        final list = List<Map<String, dynamic>>.from(response['data']);
        emit(FeedLoaded(list));
      } else {
        emit(FeedError('Akış yüklenemedi.'));
      }
    } catch (e) {
      emit(FeedError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> toggleLike(int postId) async {
    if (state is! FeedLoaded) return;
    final currentPosts = List<Map<String, dynamic>>.from((state as FeedLoaded).posts);

    try {
      final response = await _api.post('/feed/like/$postId');
      if (response['status'] == true && response['data'] != null) {
        final isLiked = response['data']['is_liked'] as bool;
        final likesCount = response['data']['likes_count'] as int;

        final index = currentPosts.indexWhere((p) => p['id'].toString() == postId.toString());
        if (index != -1) {
          final updatedPost = Map<String, dynamic>.from(currentPosts[index]);
          updatedPost['is_liked'] = isLiked;
          updatedPost['likes_count'] = likesCount.toString();
          currentPosts[index] = updatedPost;
          emit(FeedLoaded(currentPosts));
        }
      }
    } catch (_) {}
  }

  void incrementCommentCount(int postId) {
    if (state is! FeedLoaded) return;
    final currentPosts = List<Map<String, dynamic>>.from((state as FeedLoaded).posts);
    final index = currentPosts.indexWhere((p) => p['id'].toString() == postId.toString());
    if (index != -1) {
      final updatedPost = Map<String, dynamic>.from(currentPosts[index]);
      final currentCount = int.tryParse(updatedPost['comments_count'].toString()) ?? 0;
      updatedPost['comments_count'] = (currentCount + 1).toString();
      currentPosts[index] = updatedPost;
      emit(FeedLoaded(currentPosts));
    }
  }

  void decrementCommentCount(int postId) {
    if (state is! FeedLoaded) return;
    final currentPosts = List<Map<String, dynamic>>.from((state as FeedLoaded).posts);
    final index = currentPosts.indexWhere((p) => p['id'].toString() == postId.toString());
    if (index != -1) {
      final updatedPost = Map<String, dynamic>.from(currentPosts[index]);
      final currentCount = int.tryParse(updatedPost['comments_count'].toString()) ?? 1;
      updatedPost['comments_count'] = (currentCount > 0 ? currentCount - 1 : 0).toString();
      currentPosts[index] = updatedPost;
      emit(FeedLoaded(currentPosts));
    }
  }

  void updateCommentCount(int postId, int count) {
    if (state is! FeedLoaded) return;
    final currentPosts = List<Map<String, dynamic>>.from((state as FeedLoaded).posts);
    final index = currentPosts.indexWhere((p) => p['id'].toString() == postId.toString());
    if (index != -1) {
      final updatedPost = Map<String, dynamic>.from(currentPosts[index]);
      updatedPost['comments_count'] = count.toString();
      currentPosts[index] = updatedPost;
      emit(FeedLoaded(currentPosts));
    }
  }

  void updatePostLocally(Map<String, dynamic> updatedPost) {
    if (state is! FeedLoaded) return;
    final currentPosts = List<Map<String, dynamic>>.from((state as FeedLoaded).posts);
    final index = currentPosts.indexWhere((p) => p['id'].toString() == updatedPost['id'].toString());
    if (index != -1) {
      currentPosts[index] = updatedPost;
      emit(FeedLoaded(currentPosts));
    }
  }

  void removePostLocally(int postId) {
    if (state is! FeedLoaded) return;
    final currentPosts = List<Map<String, dynamic>>.from((state as FeedLoaded).posts);
    currentPosts.removeWhere((p) => p['id'].toString() == postId.toString());
    emit(FeedLoaded(currentPosts));
  }

  Future<bool> addComment(int postId, String comment) async {
    try {
      final response = await _api.post('/feed/comment/$postId', body: {'comment': comment});
      if (response['status'] == true) {
        if (state is FeedLoaded) {
          final currentPosts = List<Map<String, dynamic>>.from((state as FeedLoaded).posts);
          final index = currentPosts.indexWhere((p) => p['id'].toString() == postId.toString());
          if (index != -1) {
            final updatedPost = Map<String, dynamic>.from(currentPosts[index]);
            final currentCount = int.tryParse(updatedPost['comments_count'].toString()) ?? 0;
            updatedPost['comments_count'] = (currentCount + 1).toString();
            currentPosts[index] = updatedPost;
            emit(FeedLoaded(currentPosts));
          }
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

