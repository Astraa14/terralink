import 'package:flutter/foundation.dart';
import 'bluetooth_service.dart';

class AutomationEngineService extends ChangeNotifier {
  final BluetoothManagerService bluetoothService;

  bool isSmartAutomationEnabled = true;

  // Rule 1: Mist Pump
  bool isMistTriggerEnabled = true;
  double mistHumidityThreshold = 50.0;
  bool isMistPumpActive = false;

  // Rule 2: Cooling Fan
  bool isOverheatingProtectionEnabled = true;
  double overheatTempThreshold = 32.0;
  bool isCoolingFanActive = false;

  // Rule 3: Night Optimization Light
  bool isNightOptimizationEnabled = false;
  bool isNightModeActive = false;

  // Rule 4: Soil Irrigation Pump
  bool isIrrigationTriggerEnabled = true;
  double soilMoistureMinThreshold = 200.0;
  bool isIrrigationActive = false;

  AutomationEngineService({required this.bluetoothService});

  void toggleSmartAutomation(bool val) {
    isSmartAutomationEnabled = val;
    notifyListeners();
  }

  void updateMistRule({bool? enabled, double? threshold}) {
    if (enabled != null) isMistTriggerEnabled = enabled;
    if (threshold != null) mistHumidityThreshold = threshold;
    notifyListeners();
  }

  void updateOverheatRule({bool? enabled, double? threshold}) {
    if (enabled != null) isOverheatingProtectionEnabled = enabled;
    if (threshold != null) overheatTempThreshold = threshold;
    notifyListeners();
  }

  void updateIrrigationRule({bool? enabled, double? threshold}) {
    if (enabled != null) isIrrigationTriggerEnabled = enabled;
    if (threshold != null) soilMoistureMinThreshold = threshold;
    notifyListeners();
  }

  void updateNightRule({bool? enabled}) {
    if (enabled != null) isNightOptimizationEnabled = enabled;
    notifyListeners();
  }

  void evaluateRules({
    required double currentTemp,
    required double currentHumidity,
    required double currentSoilMoisture,
  }) {
    if (!isSmartAutomationEnabled) return;

    // 1. Mist Pump evaluation
    if (isMistTriggerEnabled) {
      if (currentHumidity < mistHumidityThreshold && !isMistPumpActive) {
        isMistPumpActive = true;
        bluetoothService.sendCommand("MIST:ON");
        notifyListeners();
      } else if (currentHumidity >= (mistHumidityThreshold + 5.0) && isMistPumpActive) {
        isMistPumpActive = false;
        bluetoothService.sendCommand("MIST:OFF");
        notifyListeners();
      }
    } else if (isMistPumpActive) {
      isMistPumpActive = false;
      bluetoothService.sendCommand("MIST:OFF");
      notifyListeners();
    }

    // 2. Overheating Protection evaluation
    if (isOverheatingProtectionEnabled) {
      if (currentTemp > overheatTempThreshold && !isCoolingFanActive) {
        isCoolingFanActive = true;
        bluetoothService.sendCommand("FAN:ON");
        notifyListeners();
      } else if (currentTemp <= (overheatTempThreshold - 2.0) && isCoolingFanActive) {
        isCoolingFanActive = false;
        bluetoothService.sendCommand("FAN:OFF");
        notifyListeners();
      }
    } else if (isCoolingFanActive) {
      isCoolingFanActive = false;
      bluetoothService.sendCommand("FAN:OFF");
      notifyListeners();
    }

    // 3. Soil Irrigation evaluation
    if (isIrrigationTriggerEnabled) {
      if (currentSoilMoisture < soilMoistureMinThreshold && !isIrrigationActive) {
        isIrrigationActive = true;
        bluetoothService.sendCommand("PUMP:ON");
        notifyListeners();
      } else if (currentSoilMoisture >= (soilMoistureMinThreshold + 100.0) && isIrrigationActive) {
        isIrrigationActive = false;
        bluetoothService.sendCommand("PUMP:OFF");
        notifyListeners();
      }
    } else if (isIrrigationActive) {
      isIrrigationActive = false;
      bluetoothService.sendCommand("PUMP:OFF");
      notifyListeners();
    }

    // 4. Night Mode Optimization evaluation
    final currentHour = DateTime.now().hour;
    final isNightHour = currentHour >= 22 || currentHour < 6;
    if (isNightOptimizationEnabled && isNightHour) {
      if (!isNightModeActive) {
        isNightModeActive = true;
        bluetoothService.sendCommand("NIGHT:ON");
        notifyListeners();
      }
    } else {
      if (isNightModeActive) {
        isNightModeActive = false;
        bluetoothService.sendCommand("NIGHT:OFF");
        notifyListeners();
      }
    }
  }
}
