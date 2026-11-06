import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/providers/core_providers.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final authStorage = ref.watch(authStorageProvider);
  return AuthRepository(apiClient: apiClient, authStorage: authStorage);
});

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthNotifier(this._repository, this._ref) : super(const AuthState()) {
    _ref.read(apiClientProvider).onUnauthorized = () {
      logout();
    };
    checkAuth();
  }

  Future<void> checkAuth() async {
    final storage = _ref.read(authStorageProvider);
    final token = await storage.getToken();
    if (token == null || token.isEmpty) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    // Attempt to load cached profile for instant startup
    final cachedProfileStr = await storage.getUserProfile();
    UserModel? cachedUser;
    if (cachedProfileStr != null && cachedProfileStr.isNotEmpty) {
      try {
        final Map<String, dynamic> data = jsonDecode(cachedProfileStr);
        cachedUser = UserModel.fromJson(data);
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: cachedUser,
        );
        _ref.read(webSocketServiceProvider).connect();
      } catch (_) {}
    }

    if (cachedUser == null) {
      state = state.copyWith(status: AuthStatus.loading);
    }

    try {
      final user = await _repository.getMe();
      await storage.saveUserProfile(jsonEncode(user.toJson()));
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      _ref.read(webSocketServiceProvider).connect();
    } catch (e) {
      if (e is ApiException && e.statusCode == 401) {
        // Token is genuinely invalid or expired on server
        await storage.clear();
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: e.toString(),
        );
      } else {
        // Network timeout, server restarting, or connection dropped:
        // Do NOT log out! Keep existing user session active.
        if (state.user == null) {
          final cachedId = await storage.getUserId() ?? 0;
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: UserModel(
              id: cachedId,
              username: 'me',
              displayName: 'Me',
            ),
          );
          _ref.read(webSocketServiceProvider).connect();
        }
      }
    }
  }

  Future<bool> login({required String phone, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.login(phone: phone, password: password);
      await _ref.read(authStorageProvider).saveUserProfile(jsonEncode(user.toJson()));
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      _ref.read(webSocketServiceProvider).connect();
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> loginWithGoogle({
    String? idToken,
    String? accessToken,
    String? email,
    String? displayName,
    String? photoUrl,
    String? googleId,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.loginWithGoogle(
        idToken: idToken,
        accessToken: accessToken,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        googleId: googleId,
      );
      await _ref.read(authStorageProvider).saveUserProfile(jsonEncode(user.toJson()));
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      _ref.read(webSocketServiceProvider).connect();
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> register({
    required String phone,
    required String username,
    required String displayName,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.register(
        phone: phone,
        username: username,
        displayName: displayName,
        password: password,
      );
      await _ref.read(authStorageProvider).saveUserProfile(jsonEncode(user.toJson()));
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      _ref.read(webSocketServiceProvider).connect();
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    _ref.read(webSocketServiceProvider).disconnect();
    await _repository.logout();
    await _ref.read(databaseProvider).clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> updateProfile({
    String? displayName,
    String? bio,
    String? username,
  }) async {
    try {
      final user = await _repository.updateProfile(
        displayName: displayName,
        bio: bio,
        username: username,
      );
      await _ref.read(authStorageProvider).saveUserProfile(jsonEncode(user.toJson()));
      state = state.copyWith(user: user);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateAvatar(File imageFile) async {
    try {
      final user = await _repository.uploadAvatar(imageFile);
      await _ref.read(authStorageProvider).saveUserProfile(jsonEncode(user.toJson()));
      state = state.copyWith(user: user);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository, ref);
});
