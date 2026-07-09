import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const TerrariumApp());

// ─── Professional Design System ───
class AppColors {
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1E2022);
  static const Color textMuted = Color(0xFF8A9099);
  
  // Theme Color (Sunlytix nature-themed dark forest green/black accent)
  static const Color mainAccent = Color(0xFF1F2E22);
  static const Color primaryGreen = Color(0xFF388E3C);
  
  // Clean flat tones for sensor categories
  static const Color orangeBg = Color(0xFFFFF7F2);
  static const Color orangeText = Color(0xFFE65100);
  
  static const Color blueBg = Color(0xFFF0F5FA);
  static const Color blueText = Color(0xFF0288D1);
  
  static const Color yellowBg = Color(0xFFFFFBEA);
  static const Color yellowText = Color(0xFFF57F17);
  
  static const Color tealBg = Color(0xFFEAF8F6);
  static const Color tealText = Color(0xFF00796B);
}

// ─── Data Models ───
class SensorLog {
  final String timeLabel;
  final double value;
  final String status;

  SensorLog({
    required this.timeLabel,
    required this.value,
    required this.status,
  });
}

class TerrariumApp extends StatelessWidget {
  const TerrariumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp( 
      title: 'TerraLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Helvetica',
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.mainAccent,
          background: AppColors.background,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Navigation State
  int _activeNavIndex = 0; // 0 = Home, 1 = Analytics, 2 = Rules, 3 = Settings
  
  // Bluetooth State
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  List<BluetoothDevice> _devicesList = [];
  BluetoothConnection? _connection;
  bool isConnecting = false;
  bool isConnected = false;

  // Smart mode toggle
  bool _isSmartAutomationEnabled = true;

  // Rule specific states
  bool _isMistTriggerEnabled = true;
  bool _isOverheatingProtectionEnabled = true;
  bool _isNightOptimizationEnabled = false;

  // Sensor Alert System configurations (0=Temp, 1=Humid, 2=Light, 3=Water)
  final List<bool> _isAlertEnabled = [false, false, false, false];
  final List<bool> _alertOnGreater = [true, false, true, false]; // Default: Greater for Temp & Solar, Less for Humid & Water
  final List<double> _alertThreshold = [28.0, 45.0, 800.0, 150.0];
  final List<bool> _isAlertTriggered = [false, false, false, false];

  // Selected sensor for detailed chart display (0=Temp, 1=Humid, 2=Light, 3=Water)
  int _selectedSensorIndex = 0;

  // Demo mode values
  bool _isDemoMode = true; // Default to true so user can see UI right away
  Timer? _demoTimer;
  final Random _random = Random();

  // Current real-time sensor states
  double _currentTemp = 24.5;
  double _currentHumidity = 58.0;
  int _currentNPK = 420;
  int _currentSoilMoisture = 280;

  // Monitored history logs (5 hours duration, 1-hour interval for each sensor)
  Map<int, List<SensorLog>> _sensorHistory = {};

  @override
  void initState() {
    super.initState();
    _generateMockHistory();
    _startDemoSimulation();
    _requestBluetoothPermissions();
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    _connection?.dispose();
    super.dispose();
  }

  // ─── Generates Clean History Data ───
  void _generateMockHistory() {
    final now = DateTime.now();
    _sensorHistory = {
      0: List.generate(5, (index) {
        final hr = now.subtract(Duration(hours: 5 - index));
        final val = 22.0 + _random.nextDouble() * 5.0;
        return SensorLog(
          timeLabel: _formatHour(hr.hour),
          value: double.parse(val.toStringAsFixed(1)),
          status: val > 26 ? "Warm" : val < 23 ? "Cool" : "Optimal",
        );
      }),
      1: List.generate(5, (index) {
        final hr = now.subtract(Duration(hours: 5 - index));
        final val = 50.0 + _random.nextDouble() * 15.0;
        return SensorLog(
          timeLabel: _formatHour(hr.hour),
          value: double.parse(val.toStringAsFixed(1)),
          status: val > 62 ? "Humid" : val < 52 ? "Dry" : "Optimal",
        );
      }),
      2: List.generate(5, (index) {
        final hr = now.subtract(Duration(hours: 5 - index));
        final val = 30 + _random.nextInt(100);
        return SensorLog(
          timeLabel: _formatHour(hr.hour),
          value: val.toDouble(),
          status: val > 90 ? "High" : val < 40 ? "Low" : "Optimal",
        );
      }),
      3: List.generate(5, (index) {
        final hr = now.subtract(Duration(hours: 5 - index));
        final val = 150 + _random.nextInt(300);
        return SensorLog(
          timeLabel: _formatHour(hr.hour),
          value: val.toDouble(),
          status: val > 350 ? "Wet" : val < 200 ? "Dry" : "Optimal",
        );
      }),
    };
  }

  String _formatHour(int uHour) {
    if (uHour == 0) return '12:00 AM';
    if (uHour < 12) return '$uHour:00 AM';
    if (uHour == 12) return '12:00 PM';
    return '${uHour - 12}:00 PM';
  }

  // ─── Simulation of live data changes ───
  void _startDemoSimulation() {
    _demoTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_isDemoMode && !isConnected) {
        setState(() {
          _currentTemp += (_random.nextDouble() - 0.5) * 0.4;
          _currentTemp = double.parse(_currentTemp.clamp(18.0, 36.0).toStringAsFixed(1));

          _currentHumidity += (_random.nextDouble() - 0.5) * 2;
          _currentHumidity = double.parse(_currentHumidity.clamp(30.0, 95.0).toStringAsFixed(1));

          _currentNPK = (_currentNPK + _random.nextInt(11) - 5).clamp(0, 200);
          _currentSoilMoisture = (_currentSoilMoisture + _random.nextInt(11) - 5).clamp(50, 800);
          
          // Dynamically push to live log if needed, keeping 5 items
          _updateRealTimeHistoryItems();
          _checkSensorAlerts();
        });
      }
    });
  }

  void _updateRealTimeHistoryItems() {
    for (int i = 0; i < 4; i++) {
      if (!_sensorHistory.containsKey(i) || _sensorHistory[i]!.isEmpty) continue;
      final list = _sensorHistory[i]!;
      double currentVal = 0.0;
      String status = "Optimal";

      switch (i) {
        case 0:
          currentVal = _currentTemp;
          status = _currentTemp > 26 ? "Warm" : _currentTemp < 23 ? "Cool" : "Optimal";
          break;
        case 1:
          currentVal = _currentHumidity;
          status = _currentHumidity > 62 ? "Humid" : _currentHumidity < 52 ? "Dry" : "Optimal";
          break;
        case 2:
          currentVal = _currentNPK.toDouble();
          status = _currentNPK > 150 ? "High" : _currentNPK < 40 ? "Low" : "Optimal";
          break;
        case 3:
          currentVal = _currentSoilMoisture.toDouble();
          status = _currentSoilMoisture > 500 ? "Wet" : _currentSoilMoisture < 200 ? "Dry" : "Optimal";
          break;
      }

      list.last = SensorLog(
        timeLabel: "Now",
        value: currentVal,
        status: status,
      );
    }
  }

  void _checkSensorAlerts() {
    for (int i = 0; i < 4; i++) {
      if (!_isAlertEnabled[i]) {
        _isAlertTriggered[i] = false;
        continue;
      }

      double currentVal = 0.0;
      switch (i) {
        case 0: currentVal = _currentTemp; break;
        case 1: currentVal = _currentHumidity; break;
        case 2: currentVal = _currentNPK.toDouble(); break;
        case 3: currentVal = _currentSoilMoisture.toDouble(); break;
      }

      bool conditionMet = false;
      if (_alertOnGreater[i]) {
        conditionMet = currentVal >= _alertThreshold[i];
      } else {
        conditionMet = currentVal <= _alertThreshold[i];
      }

      if (conditionMet) {
        if (!_isAlertTriggered[i]) {
          _isAlertTriggered[i] = true;
          _showTriggeredAlertSnackbar(i, currentVal);
        }
      } else {
        _isAlertTriggered[i] = false;
      }
    }
  }

  void _showTriggeredAlertSnackbar(int index, double val) {
    final titles = ["Temperature", "Humidity", "Soil Nutrients (NPK)", "Soil Moisture"];
    final units = ["°C", "%", " mg/kg", " pts"];
    final direction = _alertOnGreater[index] ? "climbed above" : "dropped below";
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Alert! ${titles[index]} has $direction threshold ($val${units[index]} / limit: ${_alertThreshold[index]}${units[index]}).",
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    });
  }

  void _showAlertDialog(int index) {
    final titles = ["Temperature", "Humidity", "Soil Nutrients", "Soil Moisture"];
    final units = ["°C", "%", " mg/kg", " pts"];
    final minVals = [10.0, 10.0, 0.0, 10.0];
    final maxVals = [50.0, 100.0, 300.0, 1000.0];
    final divisions = [40, 90, 60, 99];

    // Local state for the dialog
    bool localEnabled = _isAlertEnabled[index];
    bool localOnGreater = _alertOnGreater[index];
    double localThreshold = _alertThreshold[index];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  const Icon(Icons.notifications_active, color: AppColors.mainAccent),
                  const SizedBox(width: 10),
                  Text(
                    "Set ${titles[index]} Alert",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Activate Warning Alert",
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Switch.adaptive(
                        value: localEnabled,
                        activeColor: AppColors.primaryGreen,
                        onChanged: (val) {
                          setDialogState(() {
                            localEnabled = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (localEnabled) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      "Condition Trigger Mode",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text("Above (>=)")),
                            selected: localOnGreater,
                            selectedColor: AppColors.mainAccent.withOpacity(0.12),
                            onSelected: (val) {
                              setDialogState(() {
                                localOnGreater = true;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text("Below (<=)")),
                            selected: !localOnGreater,
                            selectedColor: AppColors.mainAccent.withOpacity(0.12),
                            onSelected: (val) {
                              setDialogState(() {
                                localOnGreater = false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Alert Threshold Value",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Text(
                          "${localThreshold.toStringAsFixed(0)}${units[index]}",
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.mainAccent, fontSize: 14),
                        ),
                      ],
                    ),
                    Slider.adaptive(
                      value: localThreshold,
                      min: minVals[index],
                      max: maxVals[index],
                      divisions: divisions[index],
                      activeColor: AppColors.mainAccent,
                      inactiveColor: Colors.grey.shade200,
                      onChanged: (val) {
                        setDialogState(() {
                          localThreshold = val;
                        });
                      },
                    ),
                  ]
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel", style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    setState(() {
                      _isAlertEnabled[index] = localEnabled;
                      _alertOnGreater[index] = localOnGreater;
                      _alertThreshold[index] = localThreshold;
                      // reset trigger state
                      _isAlertTriggered[index] = false;
                    });
                    // Immediately evaluate after setting alert parameters
                    _checkSensorAlerts();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("${titles[index]} threshold saved successfully."),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text("Save Alert"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Bluetooth Logic ───
  Future<void> _requestBluetoothPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    FlutterBluetoothSerial.instance.state.then((state) {
      if (!mounted) return;
      setState(() {
        _bluetoothState = state;
      });
      if (state == BluetoothState.STATE_ON) {
        _getPairedDevices();
      }
    });

    FlutterBluetoothSerial.instance.onStateChanged().listen((BluetoothState state) {
      if (!mounted) return;
      setState(() {
        _bluetoothState = state;
        if (state == BluetoothState.STATE_ON) {
          _getPairedDevices();
        }
      });
    });
  }

  void _getPairedDevices() async {
    try {
      List<BluetoothDevice> devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() {
        _devicesList = devices;
      });
    } catch (e) {
      debugPrint("Error fetching devices: $e");
    }
  }

  void _connectToDevice(BluetoothDevice device) async {
    setState(() {
      isConnecting = true;
    });
    Navigator.of(context).pop();

    try {
      BluetoothConnection connection = await BluetoothConnection.toAddress(device.address);
      setState(() {
        _connection = connection;
        isConnected = true;
        isConnecting = false;
        _isDemoMode = false; // Disable demo mode once we connect successfully
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${device.name}'),
          backgroundColor: AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _connection!.input!.listen(_onDataReceived).onDone(() {
        if (mounted) {
          setState(() {
            isConnected = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Device disconnected.')),
          );
        }
      });
    } catch (e) {
      setState(() {
        isConnecting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $e')),
      );
    }
  }

  String _buffer = "";
  void _onDataReceived(Uint8List data) {
    String incomingData = ascii.decode(data);
    _buffer += incomingData;

    if (_buffer.contains('\n')) {
      List<String> lines = _buffer.split('\n');
      String completeLine = lines.first.trim();
      _buffer = lines.length > 1 ? lines.sublist(1).join('\n') : "";

      if (completeLine.isNotEmpty) {
        List<String> values = completeLine.split(',');
        if (values.length == 4) {
          setState(() {
            _currentTemp = double.tryParse(values[0]) ?? _currentTemp;
            _currentHumidity = double.tryParse(values[1]) ?? _currentHumidity;
            _currentNPK = int.tryParse(values[2]) ?? _currentNPK;
            _currentSoilMoisture = int.tryParse(values[3]) ?? _currentSoilMoisture;

            // Automatically update historical lists
            _updateRealTimeHistoryItems();
            _checkSensorAlerts();
          });
        }
      }
    }
  }

  void _showDevicesSheet() {
    _getPairedDevices();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Select TerraLink Module",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Scanning for paired HC-05 / HC-06 Bluetooth serial modules...",
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              if (_devicesList.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.bluetooth_disabled, color: AppColors.textMuted, size: 36),
                        const SizedBox(height: 10),
                        const Text(
                          "No paired devices found",
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Please pair HC-05 in your system settings first.",
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _devicesList.length,
                    itemBuilder: (context, index) {
                      final device = _devicesList[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.developer_board, color: AppColors.mainAccent),
                        title: Text(
                          device.name ?? "HC-05 module",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(device.address),
                        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                        onTap: () => _connectToDevice(device),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ─── UI Layout Helpers ───
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPageBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildPageBody() {
    switch (_activeNavIndex) {
      case 0:
        return _buildHomeDashboard();
      case 1:
        return _buildAnalyticsTab();
      case 2:
        return _buildAutomationRulesTab();
      case 3:
        return _buildSettingsTab();
      default:
        return _buildHomeDashboard();
    }
  }

  // ─── Page 1: Main Home Dashboard ───
  Widget _buildHomeDashboard() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          _generateMockHistory();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Luma Ecosystem",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text(
                            "TerraLink",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_isDemoMode && !isConnected)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "DEMO ACTIVE",
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            )
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.bluetooth_audio, size: 20, color: AppColors.textDark),
                      onPressed: () {
                        if (isConnected) {
                          _connection?.close();
                          setState(() {
                            isConnected = false;
                          });
                        } else {
                          _showDevicesSheet();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ─── Smart Rules / Mode Selector (Sunlytix inspired energy toggler card) ───
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.yellowBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, color: AppColors.yellowText, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Smart Biotop Control",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isSmartAutomationEnabled 
                                ? "Rule engine auto regulating light levels"
                                : "Manual override enabled (Eco Mode)",
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _isSmartAutomationEnabled,
                      activeColor: AppColors.primaryGreen,
                      onChanged: (val) {
                        setState(() {
                          _isSmartAutomationEnabled = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── Connection Banner ───
              _buildConnectionControllerCard(),

              const SizedBox(height: 24),

              // ─── Grid Title ───
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Realtime Readings",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    "Tap to view last 5 hrs",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ─── Clean Professional Sensor Grid ───
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.15,
                children: [
                  _buildMetricCard(
                    index: 0,
                    title: "Temperature",
                    value: "${_currentTemp.toStringAsFixed(1)}°C",
                    icon: Icons.thermostat,
                    colorBg: AppColors.orangeBg,
                    colorText: AppColors.orangeText,
                  ),
                  _buildMetricCard(
                    index: 1,
                    title: "Humidity",
                    value: "${_currentHumidity.toStringAsFixed(1)}%",
                    icon: Icons.water_drop_outlined,
                    colorBg: AppColors.blueBg,
                    colorText: AppColors.blueText,
                  ),
                  _buildMetricCard(
                    index: 2,
                    title: "Soil Nutrients (NPK)",
                    value: "$_currentNPK",
                    icon: Icons.science_outlined,
                    colorBg: AppColors.yellowBg,
                    colorText: AppColors.yellowText,
                  ),
                  _buildMetricCard(
                    index: 3,
                    title: "Soil Moisture",
                    value: "$_currentSoilMoisture",
                    icon: Icons.grass,
                    colorBg: AppColors.tealBg,
                    colorText: AppColors.tealText,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ─── Dynamic Graph / Last 5 Hours Analytics Block ───
              _buildHistoricalChartBlock(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Connection Controller Card (Premium UI Block) ───
  Widget _buildConnectionControllerCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.mainAccent,
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: NetworkImage("https://images.unsplash.com/photo-1518531933037-91b2f5f229cc?q=80&w=600&auto=format&fit=crop"),
          fit: BoxFit.cover,
          opacity: 0.15,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.mainAccent.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isConnected ? Colors.green.shade700 : AppColors.textMuted.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isConnected ? "LIVE FEED ACTIVE" : "OFFLINE / SIMULATION",
                  style: const TextStyle(fontSize: 10, letterSpacing: 0.4, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
              Text(
                isConnected ? "Connected" : "Not Linked",
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
              )
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Ecosystem Hardware Interface",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Secure connection protocol for microcontrollers via SPP Bluetooth.",
            style: TextStyle(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isConnected ? Colors.redAccent.withOpacity(0.8) : Colors.white,
                    foregroundColor: isConnected ? Colors.white : AppColors.mainAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    if (isConnected) {
                      _connection?.close();
                      setState(() {
                        isConnected = false;
                      });
                    } else {
                      _showDevicesSheet();
                    }
                  },
                  child: Text(
                    isConnected ? "Disconnect Bluetooth" : "Scan Bluetooth Hardware",
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Option to toggle demo mode / live simulator instantly
              IconButton(
                icon: Icon(
                  _isDemoMode ? Icons.pause_circle_filled : Icons.play_circle_filled_sharp,
                  color: Colors.white,
                  size: 34,
                ),
                tooltip: "Simulated Data Engine",
                onPressed: () {
                  setState(() {
                    _isDemoMode = !_isDemoMode;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isDemoMode ? "Live Demo Data Feed Resumed" : "Demo Data Feed Paused (Values static)"),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              )
            ],
          )
        ],
      ),
    );
  }

  // ─── Dynamic Metrics Card ───
  Widget _buildMetricCard({
    required int index,
    required String title,
    required String value,
    required IconData icon,
    required Color colorBg,
    required Color colorText,
  }) {
    final isSelected = _selectedSensorIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSensorIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.mainAccent.withOpacity(0.5) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? AppColors.mainAccent.withOpacity(0.04)
                  : Colors.black.withOpacity(0.015),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: colorText, size: 20),
                ),
                // Premium look alert configuration bell
                GestureDetector(
                  onTap: () {
                    _showAlertDialog(index);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _isAlertEnabled[index] ? colorText.withOpacity(0.1) : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isAlertEnabled[index] ? Icons.notifications_active : Icons.notifications_none_rounded,
                      size: 16,
                      color: _isAlertEnabled[index] ? colorText : AppColors.textMuted.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Page 2: Analytics Tab ───
  Widget _buildAnalyticsTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("System Health Analytics", style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: false,
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Full Diagnostic Overview",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Monitored hourly parameters representing physical biotop constraints over the last 5 operating hours.",
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _buildDetailedHistoryList(),
          ],
        ),
      ),
    );
  }

  String _getSensorAverage(List<SensorLog> logs) {
    if (logs.isEmpty) return '--';
    double sum = 0.0;
    for (var l in logs) {
      sum += l.value;
    }
    return (sum / logs.length).toStringAsFixed(1);
  }

  Widget _buildDetailedHistoryList() {
    final titles = ["Temperature", "Humidity", "Soil NPK", "Soil Moisture"];
    final units = ["°C", "%", " mg/kg", " pts"];
    
    return Column(
      children: List.generate(4, (sensorIdx) {
        final logs = _sensorHistory[sensorIdx] ?? [];
        return Card(
          color: AppColors.surface,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          child: ExpansionTile(
            title: Text(
              titles[sensorIdx],
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            subtitle: Text("Average: ${_getSensorAverage(logs)} ${units[sensorIdx]}"),
            children: logs.map((log) {
              return ListTile(
                title: Text(log.timeLabel),
                trailing: Text(
                  "${log.value}${units[sensorIdx]} (${log.status})",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
          ),
        );
      }),
    );
  }

  // ─── Page 3: Automation Rules Tab ───
  Widget _buildAutomationRulesTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Climate Automatons", style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Configure Smart Hardware Thresholds",
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          _buildRuleTile(
            title: "Automated Mist System Trigger",
            desc: "Activate humidity mist pump if humidity levels drop below 50%",
            icon: Icons.dew_point,
            isEnabled: _isMistTriggerEnabled,
            onChanged: (val) {
              setState(() {
                _isMistTriggerEnabled = val;
              });
            },
          ),
          _buildRuleTile(
            title: "Overheating Protection",
            desc: "Alert and trigger extraction fan if Temperature climbs past 32°C",
            icon: Icons.cyclone,
            isEnabled: _isOverheatingProtectionEnabled,
            onChanged: (val) {
              setState(() {
                _isOverheatingProtectionEnabled = val;
              });
            },
          ),
          _buildRuleTile(
            title: "Night Mode Optimization",
            desc: "Dim dashboard display values and notification sound alerts after 10 PM",
            icon: Icons.bedtime,
            isEnabled: _isNightOptimizationEnabled,
            onChanged: (val) {
              setState(() {
                _isNightOptimizationEnabled = val;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRuleTile({
    required String title,
    required String desc,
    required IconData icon,
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textDark),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Switch.adaptive(value: isEnabled, onChanged: onChanged),
        ],
      ),
    );
  }

  // ─── Page 4: Settings Tab ───
  Widget _buildSettingsTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Preferences", style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            title: const Text("Hardware Version"),
            trailing: const Text("Rev 1.4 BLE"),
          ),
          ListTile(
            title: const Text("Developer Mode"),
            trailing: Switch.adaptive(value: _isDemoMode, onChanged: (v){
              setState(() {
                _isDemoMode = v;
              });
            }),
          ),
        ],
      ),
    );
  }

  // ─── Dynamic Live Log Chart Block ───
  Widget _buildHistoricalChartBlock() {
    final titles = ["Temperature", "Humidity", "Soil Nutrients (NPK)", "Soil Moisture"];
    final units = ["°C", "%", " mg/kg", " pts"];
    final colors = [AppColors.orangeText, AppColors.blueText, AppColors.yellowText, AppColors.tealText];
    final bgs = [AppColors.orangeBg, AppColors.blueBg, AppColors.yellowBg, AppColors.tealBg];

    final currentTitle = titles[_selectedSensorIndex];
    final currentUnit = units[_selectedSensorIndex];
    final currentColor = colors[_selectedSensorIndex];
    final currentBg = bgs[_selectedSensorIndex];
    final currentLogs = _sensorHistory[_selectedSensorIndex] ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$currentTitle Trend",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Hourly average (Last 5 hours)",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: currentBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    currentTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: currentColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Custom visual representation resembling clean charts from the photo
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: currentLogs.map((log) {
                // Determine heights dynamically with safe loop
                double maxVal = 1.0;
                if (currentLogs.isNotEmpty) {
                  double maxTemp = currentLogs.first.value;
                  for (var item in currentLogs) {
                    if (item.value > maxTemp) maxTemp = item.value;
                  }
                  maxVal = maxTemp;
                }
                if (maxVal == 0) maxVal = 1;
                final fraction = log.value / maxVal;
                final barHeight = (fraction * 70).clamp(16.0, 80.0);

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "${log.value.toStringAsFixed(0)}$currentUnit",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark.withOpacity(0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 14,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: currentColor.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        log.timeLabel,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 8),
          
          // Latest status summary row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Health Assessment",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark.withOpacity(0.7)),
              ),
              Text(
                currentLogs.isNotEmpty ? currentLogs.last.status : "Waiting",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: currentColor,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // ─── Premium Custom Bottom Nav Bar ───
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: Colors.grey.shade100, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, "Status"),
            _buildNavItem(1, Icons.analytics_outlined, Icons.analytics, "Logs"),
            _buildNavItem(2, Icons.rule_sharp, Icons.rule_sharp, "Rules"),
            _buildNavItem(3, Icons.settings_outlined, Icons.settings, "Prefs"),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final isSelected = _activeNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeNavIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mainAccent.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? filledIcon : outlineIcon,
              color: isSelected ? AppColors.mainAccent : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? AppColors.mainAccent : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
