import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/constants.dart';
import 'package:flutter/foundation.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  IO.Socket? socket;
  
  SocketService._internal();

  void connect(String token, String userId) {
    if (socket?.connected == true) return;

    socket = IO.io(ApiConstants.socketUrl, 
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .disableAutoConnect()
        .build()
    );

    socket?.connect();

    socket?.onConnect((_) {
      debugPrint('Connected to Socket.io');
      // Join user room
      socket?.emit('join', userId);
    });

    socket?.onDisconnect((_) {
      debugPrint('Disconnected from Socket.io');
    });

    socket?.onError((data) {
      debugPrint('Socket Error: $data');
    });
  }

  void disconnect() {
    socket?.disconnect();
    socket = null;
  }

  void on(String event, Function(dynamic) handler) {
    socket?.on(event, handler);
  }

  void off(String event) {
    socket?.off(event);
  }

  void emit(String event, dynamic data) {
    socket?.emit(event, data);
  }
}
