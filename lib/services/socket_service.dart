import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../utils/constants.dart';

class SocketService {
  SocketService._internal();

  static final SocketService instance = SocketService._internal();

  ServerSocket? _serverSocket;
  Socket? _socket;
  StreamSubscription<String>? _messageSubscription;

  final StreamController<void> _connectedController =
      StreamController<void>.broadcast();
  final StreamController<String> _messageController =
      StreamController<String>.broadcast();
  final StreamController<void> _disconnectedController =
      StreamController<void>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  Stream<void> get onConnected => _connectedController.stream;
  Stream<String> get onMessage => _messageController.stream;
  Stream<void> get onDisconnected => _disconnectedController.stream;
  Stream<String> get onError => _errorController.stream;

  String? get remoteIpAddress => _socket?.remoteAddress.address;
  bool get isConnected => _socket != null;

  Future<String?> getLocalIpAddress() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
      includeLinkLocal: false,
    );

    for (final interface in interfaces) {
      for (final addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && addr.isLoopback == false) {
          return addr.address;
        }
      }
    }
    return null;
  }

  Future<void> startServer({int port = AppConstants.serverPort}) async {
    await _serverSocket?.close();
    _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);

    _serverSocket!.listen(
      (client) {
        if (_socket != null) {
          client.destroy();
          return;
        }

        _socket = client;
        _connectedController.add(null);
        listenToMessages();
      },
      onError: (Object error) {
        _errorController.add('Server error: $error');
      },
    );
  }

  Future<void> connectToServer(
    String ip, {
    int port = AppConstants.serverPort,
  }) async {
    final parsed = InternetAddress.tryParse(ip.trim());
    if (parsed == null || parsed.type != InternetAddressType.IPv4) {
      throw const FormatException('Invalid IPv4 address');
    }

    await _closeSocketOnly();

    _socket = await Socket.connect(
      ip.trim(),
      port,
      timeout: const Duration(seconds: 8),
    );

    _connectedController.add(null);
    listenToMessages();
  }

  void listenToMessages() {
    final socket = _socket;
    if (socket == null) {
      return;
    }

    _messageSubscription?.cancel();

    // Every protocol message is newline-separated UTF-8 text.
    _messageSubscription = socket
      .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      (message) {
        final trimmed = message.trim();
        if (trimmed.isNotEmpty) {
          _messageController.add(trimmed);
        }
      },
      onError: (Object error) {
        _errorController.add('Connection error: $error');
      },
      onDone: () {
        _socket = null;
        _disconnectedController.add(null);
      },
      cancelOnError: true,
    );
  }

  void sendMessage(String message) {
    final socket = _socket;
    if (socket == null) {
      return;
    }

    socket.write('$message\n');
  }

  Future<void> shutdown({bool notifyPeer = false}) async {
    if (notifyPeer && _socket != null) {
      sendMessage(AppConstants.disconnect);
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    await _closeSocketOnly();
    await _serverSocket?.close();
    _serverSocket = null;
  }

  Future<void> _closeSocketOnly() async {
    await _messageSubscription?.cancel();
    _messageSubscription = null;

    try {
      await _socket?.flush();
    } catch (_) {
      // Ignore flush failures while tearing down connection.
    }

    await _socket?.close();
    _socket?.destroy();
    _socket = null;
  }
}
