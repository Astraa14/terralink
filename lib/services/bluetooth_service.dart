import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothManagerService extends ChangeNotifier {
  BluetoothState bluetoothState = BluetoothState.UNKNOWN;
  List<BluetoothDevice> devicesList = [];
  BluetoothConnection? connection;
  bool isConnecting = false;
  bool isConnected = false;

  final List<String> sentCommandLogs = [];
  String _buffer = "";

  Function(double temp, double humidity, int npk, int moisture)? onDataReceivedCallback;

  BluetoothManagerService() {
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    try {
      await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
      ].request();

      final state = await FlutterBluetoothSerial.instance.state;
      bluetoothState = state;
      notifyListeners();
      if (state == BluetoothState.STATE_ON) {
        getPairedDevices();
      }

      FlutterBluetoothSerial.instance.onStateChanged().listen((BluetoothState state) {
        bluetoothState = state;
        if (state == BluetoothState.STATE_ON) {
          getPairedDevices();
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint("Bluetooth serial channel not supported on current platform: $e");
    }
  }

  Future<void> getPairedDevices() async {
    try {
      devicesList = await FlutterBluetoothSerial.instance.getBondedDevices();
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching devices: $e");
    }
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    isConnecting = true;
    notifyListeners();

    try {
      connection = await BluetoothConnection.toAddress(device.address);
      isConnected = true;
      isConnecting = false;
      notifyListeners();

      connection!.input!.listen(_onDataReceived).onDone(() {
        isConnected = false;
        notifyListeners();
      });
      return true;
    } catch (e) {
      isConnecting = false;
      notifyListeners();
      return false;
    }
  }

  void disconnect() {
    connection?.dispose();
    isConnected = false;
    notifyListeners();
  }

  void sendCommand(String command) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    sentCommandLogs.insert(0, "[$timestamp] Tx: $command");
    if (sentCommandLogs.length > 30) sentCommandLogs.removeLast();
    notifyListeners();

    if (isConnected && connection != null && connection!.isConnected) {
      try {
        connection!.output.add(ascii.encode("$command\n"));
        connection!.output.allSent;
      } catch (e) {
        debugPrint("Error transmitting BT packet: $e");
      }
    }
  }

  void _onDataReceived(Uint8List data) {
    String incoming = ascii.decode(data);
    _buffer += incoming;

    if (_buffer.contains('\n')) {
      List<String> lines = _buffer.split('\n');
      String completeLine = lines.first.trim();
      _buffer = lines.length > 1 ? lines.sublist(1).join('\n') : "";

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
