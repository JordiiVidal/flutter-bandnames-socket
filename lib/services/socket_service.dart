import 'package:flutter/material.dart';

import 'package:socket_io_client/socket_io_client.dart' as IO;

enum ServerStatus {
  Online,
  Offline,
  Connecting,
}

class SocketService with ChangeNotifier {
  ServerStatus _serverStatus = ServerStatus.Connecting;
  IO.Socket _socket;

  ServerStatus get serverStatus => this._serverStatus;
  IO.Socket get socket => this._socket;

  SocketService() {
    initSocket();
  }

  void initSocket() {
    // Dart client
    this._socket = IO.io('https://flutter-socket-server-vidic.herokuapp.com/', {
      'transports': ['websocket'],
      'autoConnect': true,
    });

    this._socket.on('connect', (_) {
      this._serverStatus = ServerStatus.Online;
      notifyListeners();
    });

    this._socket.on('nuevo-mensaje', (data) => print(data));

    this._socket.on('disconnect', (_) {
      this._serverStatus = ServerStatus.Offline;
      notifyListeners();
    });

    this._socket.on('fromServer', (_) => print(_));
  }
}
