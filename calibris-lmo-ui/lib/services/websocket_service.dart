import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../core/config/api_config.dart';
import '../data/models/tamper_event_model.dart';

class BatchTamperAlert {
  final String deviceId;
  final int count;
  final Map<String, int> typeCounts;
  final List<TamperEventModel> logs;

  BatchTamperAlert({
    required this.deviceId,
    required this.count,
    required this.typeCounts,
    required this.logs,
  });
}

class WebSocketService {
  socket_io.Socket? _socket;
  bool _isConnected = false;

  final StreamController<bool> _connectionStateController = StreamController<bool>.broadcast();
  final StreamController<TamperEventModel> _tamperAlertController = StreamController<TamperEventModel>.broadcast();
  final StreamController<BatchTamperAlert> _batchTamperAlertController = StreamController<BatchTamperAlert>.broadcast();

  Stream<bool> get onConnectionStateChanged => _connectionStateController.stream;
  Stream<TamperEventModel> get onTamperAlert => _tamperAlertController.stream;
  Stream<BatchTamperAlert> get onBatchTamperAlert => _batchTamperAlertController.stream;

  bool get isConnected => _isConnected;

  void connect({String? customUrl}) {
    final url = customUrl ?? ApiConfig.wsUrl;
    if (_socket != null && _socket!.connected) return;

    try {
      _socket = socket_io.io(
        url,
        socket_io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(2000)
            .setReconnectionAttempts(100)
            .build(),
      );

      _socket!.onConnect((_) {
        _isConnected = true;
        _connectionStateController.add(true);
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        _connectionStateController.add(false);
      });

      _socket!.onConnectError((err) {
        _isConnected = false;
        _connectionStateController.add(false);
      });

      // Listen for single tamper alert: tamper:alert
      _socket!.on('tamper:alert', (data) {
        if (data is Map) {
          try {
            final log = TamperEventModel.fromBackendJson(Map<String, dynamic>.from(data));
            _tamperAlertController.add(log);
          } catch (_) {}
        }
      });

      // Listen for batch tamper alert: tamper:batch
      _socket!.on('tamper:batch', (data) {
        if (data is Map) {
          try {
            final devId = data['device_id']?.toString() ?? '1';
            final count = data['count'] is int ? data['count'] : (int.tryParse(data['count'].toString()) ?? 0);
            
            final Map<String, int> typeCounts = {};
            if (data['type_counts'] is Map) {
              data['type_counts'].forEach((k, v) {
                typeCounts[k.toString()] = v is int ? v : (int.tryParse(v.toString()) ?? 0);
              });
            }

            final List<TamperEventModel> logs = [];
            if (data['logs'] is List) {
              for (final item in data['logs']) {
                if (item is Map) {
                  logs.add(TamperEventModel.fromBackendJson(Map<String, dynamic>.from(item)));
                }
              }
            }

            _batchTamperAlertController.add(BatchTamperAlert(
              deviceId: devId,
              count: count,
              typeCounts: typeCounts,
              logs: logs,
            ));
          } catch (_) {}
        }
      });

      _socket!.connect();
    } catch (_) {
      _isConnected = false;
      _connectionStateController.add(false);
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _connectionStateController.add(false);
  }

  void dispose() {
    disconnect();
    _connectionStateController.close();
    _tamperAlertController.close();
    _batchTamperAlertController.close();
  }
}
