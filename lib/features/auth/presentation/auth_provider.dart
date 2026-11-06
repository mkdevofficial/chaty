import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    checkAuth();
  }

  Future<void> checkAuth() async {
    final token = await _ref.read(authStorageProvider).getToken();
    if (token == null || token.isEmpty) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repository.getMe();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      _ref.read(webSocketServiceProvider).connect();
    } catch (e) {
      // Token might be expired or invalid
      await _ref.read(authStorageProvider).clear();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> login({required String phone, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.login(phone: phone, password: password);
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
