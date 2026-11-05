import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../network/api_client.dart';
import '../network/websocket_service.dart';
import '../storage/auth_storage.dart';

final authStorageProvider = Provider<AuthStorage>((ref) {
  return AuthStorage();
});

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final authStorage = ref.watch(authStorageProvider);
  return ApiClient(
    authStorage: authStorage,
    onUnauthorized: () {
      // Auto logout trigger
      ref.read(webSocketServiceProvider).disconnect();
    },
  );
});

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final authStorage = ref.watch(authStorageProvider);
  final service = WebSocketService(authStorage: authStorage);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Globally tracks the conversation ID currently open and visible to the user.
final activeConversationIdProvider = StateProvider<int?>((ref) => null);
