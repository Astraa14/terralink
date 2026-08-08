import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

enum BluetoothConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

class BluetoothManagerService extends ChangeNotifier {
  // ─── State ───────────────────────────────────────
  BluetoothState bluetoothState = BluetoothState.UNKNOWN;
  BluetoothDevice? connectedDevice;
  List<BluetoothDevice> devicesList = [];
  BluetoothConnection? connection;

  bool isConnecting = false;
  bool isConnected = false;
  bool isScanning = false;
  bool autoReconnect = false;

  String errorMessage = '';
  BluetoothConnectionState state = BluetoothConnectionState.disconnected;

  final List<String> sentCommandLogs = [];
  String _buffer = '';

  Function(double temp, double humidity, int npk, int moisture)?
      onDataReceivedCallback;

  // ─── Constructor ─────────────────────────────────
  BluetoothManagerService() {
    requestPermissions();
  }

  // ─── Derived getters ─────────────────────────────
  List<BluetoothDevice> get devices => devicesList;

  String get statusLabel {
    switch (state) {
      case BluetoothConnectionState.connected:
        return connectedDevice?.name ?? 'Connected';
      case BluetoothConnectionState.connecting:
        return 'Connecting…';
      case BluetoothConnectionState.scanning:
        return 'Scanning for devices…';
      case BluetoothConnectionState.error:
        return errorMessage.isNotEmpty ? errorMessage : 'Connection error';
      case BluetoothConnectionState.disconnected:
        return 'Not connected';
    }
  }

  // ─── Permissions & Setup ─────────────────────────
  Future<void> requestPermissions() async {
    try {
      await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
      ].request();

      final btState = await FlutterBluetoothSerial.instance.state;
      bluetoothState = btState;
      notifyListeners();

      if (btState == BluetoothState.STATE_ON) {
        getPairedDevices();
      }

      FlutterBluetoothSerial.instance
          .onStateChanged()
          .listen((BluetoothState s) {
        bluetoothState = s;
        if (s == BluetoothState.STATE_ON) {
          getPairedDevices();
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Bluetooth serial channel not supported on this platform: $e');
    }
  }

  // ─── Scan / Refresh paired devices ───────────────
  Future<void> startScan() async {
    isScanning = true;
    state = BluetoothConnectionState.scanning;
    errorMessage = '';
    notifyListeners();
    await getPairedDevices();
    isScanning = false;
    if (state == BluetoothConnectionState.scanning) {
      state = BluetoothConnectionState.disconnected;
    }
    notifyListeners();
  }

  Future<void> getPairedDevices() async {
    try {
      devicesList = await FlutterBluetoothSerial.instance.getBondedDevices();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching paired devices: $e');
    }
  }

  // ─── Connect ─────────────────────────────────────
  Future<bool> connectToDevice(BluetoothDevice device) async {
    isConnecting = true;
    state = BluetoothConnectionState.connecting;
    errorMessage = '';
    notifyListeners();

    try {
      connection = await BluetoothConnection.toAddress(device.address);
      isConnected = true;
      isConnecting = false;
      connectedDevice = device;
      state = BluetoothConnectionState.connected;
      notifyListeners();

      connection!.input!.listen(_onDataReceived).onDone(() {
        isConnected = false;
        connectedDevice = null;
        state = BluetoothConnectionState.disconnected;
        notifyListeners();
        if (autoReconnect) {
          Future.delayed(const Duration(seconds: 3), () => connectToDevice(device));
        }
      });
      return true;
    } catch (e) {
      isConnecting = false;
      isConnected = false;
      errorMessage = 'Failed to connect to ${device.name ?? device.address}';
      state = BluetoothConnectionState.error;
      notifyListeners();
      return false;
    }
  }

  // ─── Disconnect ──────────────────────────────────
  void disconnect() {
    connection?.dispose();
    isConnected = false;
    connectedDevice = null;
    state = BluetoothConnectionState.disconnected;
    notifyListeners();
  }

  // ─── Auto-reconnect toggle ───────────────────────
  void setAutoReconnect(bool value) {
    autoReconnect = value;
    notifyListeners();
  }

  // ─── Send command ────────────────────────────────
  void sendCommand(String command) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    sentCommandLogs.insert(0, '[$timestamp] Tx: $command');
    if (sentCommandLogs.length > 30) sentCommandLogs.removeLast();
    notifyListeners();

    if (isConnected && connection != null && connection!.isConnected) {
      try {
        connection!.output.add(ascii.encode('$command\n'));
        connection!.output.allSent;
      } catch (e) {
        debugPrint('Error transmitting BT packet: $e');
      }
    }
  }

  // ─── Data receive ────────────────────────────────
  void _onDataReceived(Uint8List data) {
    String incoming = ascii.decode(data);
    _buffer += incoming;

    if (_buffer.contains('\n')) {
      List<String> lines = _buffer.split('\n');
      String completeLine = lines.first.trim();
      _buffer = lines.length > 1 ? lines.sublist(1).join('\n') : '';

      if (completeLine.isNotEmpty) {
        List<String> values = completeLine.split(',');
        if (values.length == 4) {
          double? temp = double.tryParse(values[0]);
          double? hum = double.tryParse(values[1]);
          int? npk = int.tryParse(values[2]);
          int? moist = int.tryParse(values[3]);

          if (temp != null && hum != null && npk != null && moist != null) {
            onDataReceivedCallback?.call(temp, hum, npk, moist);
          }
        }
      }
    }
  }
}
