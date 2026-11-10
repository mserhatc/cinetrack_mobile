import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_client.dart';

abstract class ExploreState {}

class ExploreInitial extends ExploreState {}
class ExploreLoading extends ExploreState {}
class ExploreLoaded extends ExploreState {
  final List<Map<String, dynamic>> items;
  final String activeCategory; // 'trending', 'movies', 'tv'
  final String? searchQuery;

  ExploreLoaded({
    required this.items,
    this.activeCategory = 'trending',
    this.searchQuery,
  });
}
class ExploreError extends ExploreState {
  final String message;
  ExploreError(this.message);
}

class ExploreCubit extends Cubit<ExploreState> {
  final ApiClient _api = ApiClient();

  ExploreCubit() : super(ExploreInitial());

  Future<void> fetchItems({String category = 'trending'}) async {
    emit(ExploreLoading());
    try {
      String endpoint = '/tmdb/trending';
      if (category == 'movies') {
        endpoint = '/tmdb/popular/movies';
      } else if (category == 'tv') {
        endpoint = '/tmdb/popular/tv';
      }

      final response = await _api.get(endpoint);
      List<Map<String, dynamic>> results = [];
      if (response != null && response['results'] != null) {
        results = List<Map<String, dynamic>>.from(response['results']);
      }

      emit(ExploreLoaded(items: results, activeCategory: category));
    } catch (e) {
      emit(ExploreError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      fetchItems();
      return;
    }
    emit(ExploreLoading());
    try {
      final response = await _api.get('/tmdb/search', queryParams: {'query': query});
      List<Map<String, dynamic>> results = [];
      if (response != null && response['results'] != null) {
        results = List<Map<String, dynamic>>.from(response['results']);
      }
      emit(ExploreLoaded(items: results, searchQuery: query));
    } catch (e) {
      emit(ExploreError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}

