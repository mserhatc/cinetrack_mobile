import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_client.dart';

abstract class CreatePostState {}

class CreatePostInitial extends CreatePostState {}
class CreatePostSearching extends CreatePostState {}
class CreatePostSearchResults extends CreatePostState {
  final List<Map<String, dynamic>> results;
  CreatePostSearchResults(this.results);
}
class CreatePostSubmitting extends CreatePostState {}
class CreatePostSuccess extends CreatePostState {}
class CreatePostError extends CreatePostState {
  final String message;
  CreatePostError(this.message);
}

class CreatePostCubit extends Cubit<CreatePostState> {
  final ApiClient _api = ApiClient();

  CreatePostCubit() : super(CreatePostInitial());

  Future<void> searchMedia(String query) async {
    if (query.trim().isEmpty) {
      emit(CreatePostInitial());
      return;
    }

    emit(CreatePostSearching());
    try {
      final response = await _api.get('/tmdb/search', queryParams: {'query': query});
      List<dynamic>? results;
      if (response != null) {
        if (response['results'] != null && response['results'] is List) {
          results = response['results'];
        } else if (response['data'] != null) {
          if (response['data'] is Map && response['data']['results'] != null && response['data']['results'] is List) {
            results = response['data']['results'];
          } else if (response['data'] is List) {
            results = response['data'];
          }
        }
      }

      if (results != null) {
        final list = List<Map<String, dynamic>>.from(results);
        emit(CreatePostSearchResults(list));
      } else {
        emit(CreatePostSearchResults([]));
      }
    } catch (_) {
      emit(CreatePostSearchResults([]));
    }
  }

  Future<bool> createPost({
    required String postType, // 'quote', 'review', 'general'
    int? tmdbId,
    String? mediaType,
    String? title,
    String? posterPath,
    String? quoteText,
    required String content,
    double? rating,
  }) async {
    emit(CreatePostSubmitting());
    try {
      final response = await _api.post('/feed/create', body: {
        'post_type': postType,
        'tmdb_id': tmdbId,
        'media_type': mediaType ?? 'movie',
        'title': title ?? '',
        'poster_path': posterPath ?? '',
        'quote_text': quoteText,
        'content': content,
        'rating': rating,
      });

      if (response['status'] == true) {
        emit(CreatePostSuccess());
        return true;
      } else {
        emit(CreatePostError(response['message'] ?? 'Paylaşım yapılamadı.'));
        return false;
      }
    } catch (e) {
      emit(CreatePostError(e.toString().replaceAll('Exception: ', '')));
      return false;
    }
  }
}

