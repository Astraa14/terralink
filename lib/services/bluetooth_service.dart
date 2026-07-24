import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

enum BluetoothConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

class BluetoothService extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------
  BluetoothConnectionState _state = BluetoothConnectionState.disconnected;
  BluetoothConnectionState get state => _state;

  BluetoothConnection? _connection;
  BluetoothConnection? get connection => _connection;

  List<BluetoothDevice> _devices = [];
  List<BluetoothDevice> get devices => List.unmodifiable(_devices);

  BluetoothDevice? _connectedDevice;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  bool _isBluetoothAvailable = false;
  bool get isBluetoothAvailable => _isBluetoothAvailable;

  bool _isBluetoothEnabled = false;
  bool get isBluetoothEnabled => _isBluetoothEnabled;

  String _dataBuffer = '';

  // ---------------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------------
  final StreamController<String> _rawDataController =
      StreamController<String>.broadcast();
  Stream<String> get rawDataStream => _rawDataController.stream;

  final StreamController<Map<String, double>> _parsedDataController =
      StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get parsedDataStream =>
      _parsedDataController.stream;

  final StreamController<BluetoothConnectionState> _stateController =
      StreamController<BluetoothConnectionState>.broadcast();
  Stream<BluetoothConnectionState> get stateStream => _stateController.stream;

  // Auto-reconnect
  Timer? _reconnectTimer;
  bool _autoReconnect = true;
  bool get autoReconnect => _autoReconnect;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectInterval = Duration(seconds: 10);

  StreamSubscription<Uint8List>? _dataSubscription;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  BluetoothService() {
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    try {
      _isBluetoothAvailable =
          await FlutterBluetoothSerial.instance.isAvailable ?? false;
      _isBluetoothEnabled =
          await FlutterBluetoothSerial.instance.isEnabled ?? false;
      notifyListeners();
    } catch (e) {
      _isBluetoothAvailable = false;
      _isBluetoothEnabled = false;
      debugPrint('Bluetooth init error: $e');
    }
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _dataSubscription?.cancel();
    _connection?.dispose();
    _rawDataController.close();
    _parsedDataController.close();
    _stateController.close();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // State helpers
  // ---------------------------------------------------------------------------
  void _setState(BluetoothConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
    notifyListeners();
  }

  bool get isConnected => _state == BluetoothConnectionState.connected;

  String get statusLabel {
    switch (_state) {
      case BluetoothConnectionState.disconnected:
        return 'Disconnected';
      case BluetoothConnectionState.scanning:
        return 'Scanning…';
      case BluetoothConnectionState.connecting:
        return 'Connecting…';
      case BluetoothConnectionState.connected:
        return 'Connected';
      case BluetoothConnectionState.error:
        return 'Error';
    }
  }

  // ---------------------------------------------------------------------------
  // Scanning
  // ---------------------------------------------------------------------------
  Future<void> startScan() async {
    if (_state == BluetoothConnectionState.scanning) return;
    _setState(BluetoothConnectionState.scanning);
    _devices = [];
    notifyListeners();

    try {
      _isBluetoothEnabled =
          await FlutterBluetoothSerial.instance.isEnabled ?? false;
      if (!_isBluetoothEnabled) {
        await FlutterBluetoothSerial.instance.requestEnable();
        _isBluetoothEnabled =
            await FlutterBluetoothSerial.instance.isEnabled ?? false;
        if (!_isBluetoothEnabled) {
          _errorMessage = 'Bluetooth is disabled';
          _setState(BluetoothConnectionState.error);
          return;
        }
      }

      final bonded =
          await FlutterBluetoothSerial.instance.getBondedDevices();
      _devices = bonded;

      // Also run discovery for unbonded devices
      final discovered = <BluetoothDevice>[];
      final completer = Completer<void>();

      FlutterBluetoothSerial.instance.startDiscovery().listen(
        (result) {
          final exists = _devices.any(
              (d) => d.address == result.device.address);
          if (!exists) {
            discovered.add(result.device);
          }
        },
        onDone: () {
          _devices = [..._devices, ...discovered];
          if (!completer.isCompleted) completer.complete();
        },
        onError: (e) {
          if (!completer.isCompleted) completer.complete();
        },
      );

      // Wait up to 12 seconds for discovery
      await completer.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          try {
            FlutterBluetoothSerial.instance.cancelDiscovery();
          } catch (_) {}
        },
      );

      _setState(BluetoothConnectionState.disconnected);
    } catch (e) {
      _errorMessage = 'Scan failed: $e';
      _setState(BluetoothConnectionState.error);
    }
  }

  void stopScan() {
    try {
      FlutterBluetoothSerial.instance.cancelDiscovery();
    } catch (_) {}
    if (_state == BluetoothConnectionState.scanning) {
      _setState(BluetoothConnectionState.disconnected);
    }
  }

  // ---------------------------------------------------------------------------
  // Connection
  // ---------------------------------------------------------------------------
  Future<bool> connectToDevice(BluetoothDevice device) async {
    if (_state == BluetoothConnectionState.connecting ||
        _state == BluetoothConnectionState.connected) {
      return false;
    }

    _setState(BluetoothConnectionState.connecting);
    _errorMessage = '';
    _reconnectAttempts = 0;

    try {
      _connection = await BluetoothConnection.toAddress(device.address)
          .timeout(const Duration(seconds: 15));
      _connectedDevice = device;
      _setState(BluetoothConnectionState.connected);
      _listenForData();
      return true;
    } catch (e) {
      _errorMessage = 'Connection failed: ${e.toString().split(':').last.trim()}';
      _setState(BluetoothConnectionState.error);
      _scheduleReconnect(device);
      return false;
    }
  }

  Future<void> disconnect() async {
    _autoReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    _dataSubscription?.cancel();
    _dataSubscription = null;

    try {
      await _connection?.close();
    } catch (_) {}

    _connection = null;
    _connectedDevice = null;
    _dataBuffer = '';
    _setState(BluetoothConnectionState.disconnected);
    _autoReconnect = true;
  }

  // ---------------------------------------------------------------------------
  // Auto-reconnect
  // ---------------------------------------------------------------------------
  void setAutoReconnect(bool value) {
    _autoReconnect = value;
    if (!value) {
      _reconnectTimer?.cancel();
    }
    notifyListeners();
  }

  void _scheduleReconnect(BluetoothDevice device) {
    if (!_autoReconnect || _reconnectAttempts >= _maxReconnectAttempts) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectInterval, () {
      _reconnectAttempts++;
      debugPrint(
          'Auto-reconnect attempt $_reconnectAttempts / $_maxReconnectAttempts');
      connectToDevice(device);
    });
  }

  // ---------------------------------------------------------------------------
  // Data handling
  // ---------------------------------------------------------------------------
  void _listenForData() {
    _dataSubscription?.cancel();
    if (_connection == null || _connection!.input == null) return;

    _dataSubscription = _connection!.input!.listen(
      (Uint8List data) {
        final incoming = utf8.decode(data, allowMalformed: true);
        _dataBuffer += incoming;

        while (_dataBuffer.contains('\n')) {
          final newlineIndex = _dataBuffer.indexOf('\n');
          final line = _dataBuffer.substring(0, newlineIndex).trim();
          _dataBuffer = _dataBuffer.substring(newlineIndex + 1);

          if (line.isNotEmpty) {
            _rawDataController.add(line);
            _parseAndEmit(line);
          }
        }
      },
      onDone: () {
        debugPrint('Bluetooth stream closed');
        final device = _connectedDevice;
        _connection = null;
        _connectedDevice = null;
        _setState(BluetoothConnectionState.disconnected);
        if (device != null) _scheduleReconnect(device);
      },
      onError: (error) {
        debugPrint('Bluetooth data error: $error');
        _errorMessage = 'Data error: $error';
        final device = _connectedDevice;
        _connection = null;
        _connectedDevice = null;
        _setState(BluetoothConnectionState.error);
        if (device != null) _scheduleReconnect(device);
      },
    );
  }

  /// Expected CSV format: temperature,humidity,npk,soil_moisture
  void _parseAndEmit(String line) {
    try {
      final parts = line.split(',');
      if (parts.length >= 4) {
        final parsed = <String, double>{
          'temperature': double.tryParse(parts[0].trim()) ?? 0,
          'humidity': double.tryParse(parts[1].trim()) ?? 0,
          'npk': double.tryParse(parts[2].trim()) ?? 0,
          'soil_moisture': double.tryParse(parts[3].trim()) ?? 0,
        };
        _parsedDataController.add(parsed);
      }
    } catch (e) {
      debugPrint('Parse error for "$line": $e');
    }
  }

  /// Send a command string to the connected device.
  Future<void> sendCommand(String command) async {
    if (_connection == null || !isConnected) return;
    try {
      _connection!.output.add(Uint8List.fromList(utf8.encode('$command\n')));
      await _connection!.output.allSent;
    } catch (e) {
      debugPrint('Send command error: $e');
    }
  }
}
