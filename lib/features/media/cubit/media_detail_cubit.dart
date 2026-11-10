import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_client.dart';

abstract class MediaDetailState {}

class MediaDetailInitial extends MediaDetailState {}
class MediaDetailLoading extends MediaDetailState {}
class MediaDetailLoaded extends MediaDetailState {
  final Map<String, dynamic> media;
  final List<Map<String, dynamic>> communityReviews;
  final String? watchStatus; // 'watched', 'plan_to_watch', null
  final double? userRating;

  MediaDetailLoaded({
    required this.media,
    required this.communityReviews,
    this.watchStatus,
    this.userRating,
  });
}
class MediaDetailError extends MediaDetailState {
  final String message;
  MediaDetailError(this.message);
}

class MediaDetailCubit extends Cubit<MediaDetailState> {
  final ApiClient _api = ApiClient();

  MediaDetailCubit() : super(MediaDetailInitial());

  Future<void> loadDetails(int id, String mediaType) async {
    emit(MediaDetailLoading());
    try {
      final endpoint = mediaType == 'tv' ? '/tmdb/tv/$id' : '/tmdb/movie/$id';
      final rawData = await _api.get(endpoint);
      Map<String, dynamic> mediaData = {};
      if (rawData is Map<String, dynamic>) {
        if (rawData.containsKey('data') && rawData['data'] is Map<String, dynamic>) {
          mediaData = Map<String, dynamic>.from(rawData['data']);
        } else {
          mediaData = Map<String, dynamic>.from(rawData);
        }
      }

      final reviewsResp = await _api.get('/watchlist/reviews/$id/$mediaType');
      final reviews = reviewsResp['status'] == true && reviewsResp['data'] != null
          ? List<Map<String, dynamic>>.from(reviewsResp['data'])
          : <Map<String, dynamic>>[];

      final userStatus = mediaData['user_status'];
      String? watchStatus;
      double? userRating;

      if (userStatus != null) {
        watchStatus = userStatus['status'];
        if (userStatus['rating'] != null) {
          userRating = double.tryParse(userStatus['rating'].toString());
        }
      }

      emit(MediaDetailLoaded(
        media: mediaData,
        communityReviews: reviews,
        watchStatus: watchStatus,
        userRating: userRating,
      ));
    } catch (e) {
      emit(MediaDetailError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<bool> setWatchStatus({
    required int tmdbId,
    required String mediaType,
    required String title,
    required String posterPath,
    required String status,
  }) async {
    try {
      final response = await _api.post('/watchlist/status', body: {
        'tmdb_id': tmdbId,
        'media_type': mediaType,
        'title': title,
        'poster_path': posterPath,
        'status': status,
      });

      if (response['status'] == true && state is MediaDetailLoaded) {
        final current = state as MediaDetailLoaded;
        emit(MediaDetailLoaded(
          media: current.media,
          communityReviews: current.communityReviews,
          watchStatus: status == 'remove' ? null : status,
          userRating: current.userRating,
        ));
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rateAndReview({
    required int tmdbId,
    required String mediaType,
    required String title,
    required String posterPath,
    required double rating,
    required String reviewText,
  }) async {
    try {
      final response = await _api.post('/watchlist/rate', body: {
        'tmdb_id': tmdbId,
        'media_type': mediaType,
        'title': title,
        'poster_path': posterPath,
        'rating': rating,
        'review_text': reviewText,
      });

      if (response['status'] == true) {
        // Yeniden yükle
        await loadDetails(tmdbId, mediaType);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

