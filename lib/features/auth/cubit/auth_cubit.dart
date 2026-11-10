import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class Authenticated extends AuthState {
  final Map<String, dynamic> user;
  final String token;
  Authenticated({required this.user, required this.token});
}
class Unauthenticated extends AuthState {
  final String? message;
  Unauthenticated({this.message});
}

class AuthCubit extends Cubit<AuthState> {
  final ApiClient _api = ApiClient();

  AuthCubit() : super(AuthInitial());

  Future<void> checkAuthStatus() async {
    emit(AuthLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        emit(Unauthenticated());
        return;
      }

      _api.setToken(token);
      final response = await _api.get('/auth/profile');
      if (response['status'] == true && response['data'] != null) {
        emit(Authenticated(user: response['data'], token: token));
      } else {
        await prefs.remove('auth_token');
        _api.setToken(null);
        emit(Unauthenticated());
      }
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  Future<bool> login(String login, String password) async {
    emit(AuthLoading());
    try {
      final response = await _api.post('/auth/login', body: {
        'login': login,
        'password': password,
      });

      if (response['status'] == true && response['data'] != null) {
        final token = response['data']['token'];
        final user = response['data']['user'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        _api.setToken(token);

        // Profil detaylarını ve istatistiklerini de çekelim
        final profileResp = await _api.get('/auth/profile/${user['id']}');
        final fullUser = profileResp['data'] ?? user;

        emit(Authenticated(user: fullUser, token: token));
        return true;
      } else {
        emit(Unauthenticated(message: response['message'] ?? 'Giriş başarısız'));
        return false;
      }
    } catch (e) {
      emit(Unauthenticated(message: e.toString().replaceAll('Exception: ', '')));
      return false;
    }
  }

  Future<bool> register(
    String username,
    String email,
    String password,
    String fullName, {
    String? avatar,
  }) async {
    emit(AuthLoading());
    try {
      final body = <String, dynamic>{
        'username': username,
        'email': email,
        'password': password,
        'full_name': fullName,
      };
      if (avatar != null && avatar.trim().isNotEmpty) {
        body['avatar'] = avatar.trim();
      }

      final response = await _api.post('/auth/register', body: body);

      if (response['status'] == true && response['data'] != null) {
        final token = response['data']['token'];
        final user = response['data']['user'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        _api.setToken(token);

        emit(Authenticated(user: user, token: token));
        return true;
      } else {
        emit(Unauthenticated(message: response['message'] ?? 'Kayıt başarısız'));
        return false;
      }
    } catch (e) {
      emit(Unauthenticated(message: e.toString().replaceAll('Exception: ', '')));
      return false;
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    String? bio,
    String? avatar,
  }) async {
    if (state is! Authenticated) return false;
    final currentToken = (state as Authenticated).token;
    try {
      final body = <String, dynamic>{};
      if (fullName != null) body['full_name'] = fullName.trim();
      if (bio != null) body['bio'] = bio.trim();
      if (avatar != null) body['avatar'] = avatar.trim();

      final res = await _api.post('/auth/update', body: body);
      if (res['status'] == true && res['data'] != null) {
        final updatedUser = Map<String, dynamic>.from(res['data']);
        emit(Authenticated(user: updatedUser, token: currentToken));
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> refreshProfile() async {
    if (state is Authenticated) {
      final currentToken = (state as Authenticated).token;
      try {
        final response = await _api.get('/auth/profile');
        if (response['status'] == true && response['data'] != null) {
          emit(Authenticated(user: response['data'], token: currentToken));
        }
      } catch (_) {}
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _api.setToken(null);
    emit(Unauthenticated());
  }

  bool get isAuthenticated => state is Authenticated;
  Map<String, dynamic>? get currentUser => state is Authenticated ? (state as Authenticated).user : null;
}

