import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';
import '../storage/auth_storage.dart';

enum WsConnectionStatus {
  disconnected,
  connecting,
  connected,
}

class WebSocketService {
  final AuthStorage authStorage;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  bool _isDisposed = false;
  int _reconnectAttempts = 0;
  WsConnectionStatus _status = WsConnectionStatus.disconnected;

  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  final _statusController = StreamController<WsConnectionStatus>.broadcast();

  VoidCallback? onResyncNeeded;

  WebSocketService({required this.authStorage});

  Stream<Map<String, dynamic>> get events => _eventController.stream;
  Stream<WsConnectionStatus> get statusStream => _statusController.stream;
  WsConnectionStatus get status => _status;
  bool get isConnected => _status == WsConnectionStatus.connected;

  void _setStatus(WsConnectionStatus status) {
    if (_status != status) {
      _status = status;
      _statusController.add(status);
    }
  }

  Future<void> connect() async {
    if (_isDisposed) return;
    if (_status == WsConnectionStatus.connected ||
        _status == WsConnectionStatus.connecting) {
      return;
    }

    final token = await authStorage.getToken();
    if (token == null || token.isEmpty) {
      _setStatus(WsConnectionStatus.disconnected);
      return;
    }

    _setStatus(WsConnectionStatus.connecting);

    try {
      final wsUri = Uri.parse('${AppConfig.wsUrl}?token=${Uri.encodeComponent(token)}');
      _channel = WebSocketChannel.connect(wsUri);

      // Wait for stream ready
      _subscription = _channel!.stream.listen(
        (data) {
          _handleIncoming(data);
        },
        onDone: () {
          _handleDisconnect();
        },
        onError: (err) {
          debugPrint('WebSocket error: $err');
          _handleDisconnect();
        },
        cancelOnError: true,
      );

      _setStatus(WsConnectionStatus.connected);
      final hadPreviousAttempts = _reconnectAttempts > 0;
      _reconnectAttempts = 0;
      _startPingTimer();

      // If reconnecting after a drop, notify resync
      if (hadPreviousAttempts) {
        onResyncNeeded?.call();
      }
    } catch (e) {
      debugPrint('Failed to connect to WebSocket: $e');
      _handleDisconnect();
    }
  }

  void _handleIncoming(dynamic data) {
    try {
      if (data is String) {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          final eventName = decoded['event'] ?? decoded['type'];
          final eventData = decoded['data'] ?? decoded;

          if (kDebugMode) {
            debugPrint('[WebSocket] INCOMING EVENT: $eventName | DATA: $eventData');
          }

          // Normalize so all listeners can consume either contract style or legacy
          final Map<String, dynamic> normalized = Map<String, dynamic>.from(decoded);
          normalized['event'] = eventName;
          normalized['type'] = eventName;

          if (eventData is Map<String, dynamic>) {
            normalized.addAll(eventData);
            normalized['data'] = eventData;
          }

          _eventController.add(normalized);
        }
      }
    } catch (e) {
      debugPrint('Error decoding WS message: $e');
    }
  }

  void _handleDisconnect() {
    _cleanupChannel();
    _setStatus(WsConnectionStatus.disconnected);
    _scheduleReconnect();
  }

  void _cleanupChannel() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (isConnected) {
        send({'event': 'ping'});
      }
    });
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    _reconnectTimer?.cancel();

    // Exponential backoff: 1s, 2s, 4s, 8s, up to 30s
    final delaySeconds = min(30, pow(2, _reconnectAttempts).toInt());
    _reconnectAttempts++;

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      connect();
    });
  }

  void send(Map<String, dynamic> data) {
    if (!isConnected || _channel == null) return;
    try {
      _channel!.sink.add(jsonEncode(data));
    } catch (e) {
      debugPrint('Failed to send WS message: $e');
    }
  }

  void sendTyping({required int conversationId, required bool isTyping}) {
    send({
      'event': 'typing',
      'data': {
        'conversation_id': conversationId,
        'is_typing': isTyping,
      },
    });
  }

  void onAppForeground() {
    if (!isConnected) {
      _reconnectAttempts = 0;
      connect();
    }
  }

  void disconnect() {
    _cleanupChannel();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _setStatus(WsConnectionStatus.disconnected);
  }

  void dispose() {
    _isDisposed = true;
    disconnect();
    _eventController.close();
    _statusController.close();
  }
}
