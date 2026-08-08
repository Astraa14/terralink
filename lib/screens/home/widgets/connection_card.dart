import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/bluetooth_service.dart';
import '../../../services/sensor_service.dart';

class ConnectionCard extends StatelessWidget {
  const ConnectionCard({super.key});

  static const Color _mainAccent = Color(0xFF1F2E22);

  @override
  Widget build(BuildContext context) {
    final bt = context.watch<BluetoothManagerService>();
    final sensor = context.watch<SensorService>();
    final isConnected = bt.isConnected;
    final isDemoMode = sensor.demoMode;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _mainAccent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _mainAccent.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isDemoMode
                        ? Icons.science_outlined
                        : Icons.bluetooth_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDemoMode ? 'Demo Mode' : 'Bluetooth Controller',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _buildStatusDot(isConnected, isDemoMode),
                          const SizedBox(width: 6),
                          Text(
                            _statusText(bt, isDemoMode),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _indicatorColor(bt, isDemoMode).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _indicatorLabel(bt, isDemoMode),
                    style: TextStyle(
                      color: _indicatorColor(bt, isDemoMode),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Device name if connected
            if (isConnected && bt.connectedDevice != null) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.devices_rounded,
                        size: 16, color: Colors.white.withOpacity(0.6)),
                    const SizedBox(width: 8),
                    Text(
                      bt.connectedDevice!.name ?? bt.connectedDevice!.address,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            // Action buttons row
            Row(
              children: [
                // Connect / Disconnect button
                Expanded(
                  child: _ActionButton(
                    label: isConnected ? 'Disconnect' : 'Connect',
                    icon: isConnected
                        ? Icons.bluetooth_disabled_rounded
                        : Icons.bluetooth_searching_rounded,
                    filled: !isConnected,
                    loading: bt.state == BluetoothConnectionState.scanning ||
                        bt.state == BluetoothConnectionState.connecting,
                    onTap: () {
                      if (isConnected) {
                        bt.disconnect();
                      } else {
                        _showDeviceSheet(context, bt);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Demo toggle
                Expanded(
                  child: _ActionButton(
                    label: isDemoMode ? 'Stop Demo' : 'Demo Mode',
                    icon: isDemoMode
                        ? Icons.stop_circle_outlined
                        : Icons.play_circle_outline_rounded,
                    filled: isDemoMode,
                    filledColor: const Color(0xFF388E3C),
                    onTap: () => sensor.toggleDemoMode(),
                  ),
                ),
              ],
            ),
            // Error message
            if (bt.errorMessage.isNotEmpty &&
                bt.state == BluetoothConnectionState.error) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 16, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bt.errorMessage,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDot(bool connected, bool demo) {
    final color = demo
        ? const Color(0xFF388E3C)
        : connected
            ? const Color(0xFF4CAF50)
            : const Color(0xFFBDBDBD);
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          if (connected || demo)
            BoxShadow(color: color.withOpacity(0.5), blurRadius: 6),
        ],
      ),
    );
  }

  String _statusText(BluetoothManagerService bt, bool demo) {
    if (demo) return 'Simulating sensor data';
    return bt.statusLabel;
  }

  Color _indicatorColor(BluetoothManagerService bt, bool demo) {
    if (demo) return const Color(0xFF4CAF50);
    switch (bt.state) {
      case BluetoothConnectionState.connected:
        return const Color(0xFF4CAF50);
      case BluetoothConnectionState.connecting:
      case BluetoothConnectionState.scanning:
        return const Color(0xFFFFA726);
      case BluetoothConnectionState.error:
        return Colors.redAccent;
      case BluetoothConnectionState.disconnected:
        return const Color(0xFFBDBDBD);
    }
  }

  String _indicatorLabel(BluetoothManagerService bt, bool demo) {
    if (demo) return 'LIVE';
    switch (bt.state) {
      case BluetoothConnectionState.connected:
        return 'LIVE';
      case BluetoothConnectionState.connecting:
        return 'PAIRING';
      case BluetoothConnectionState.scanning:
        return 'SCANNING';
      case BluetoothConnectionState.error:
        return 'ERROR';
      case BluetoothConnectionState.disconnected:
        return 'OFFLINE';
    }
  }

  void _showDeviceSheet(BuildContext context, BluetoothManagerService bt) {
    bt.startScan();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _DeviceSelectionSheet(bt: bt),
    );
  }
}

// ---------------------------------------------------------------------------
// Action button
// ---------------------------------------------------------------------------
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final bool loading;
  final Color? filledColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.loading = false,
    this.filledColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled
        ? (filledColor ?? Colors.white)
        : Colors.white.withOpacity(0.1);
    final fg = filled ? const Color(0xFF1F2E22) : Colors.white;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: loading ? null : onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fg,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: fg,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Device selection bottom sheet
// ---------------------------------------------------------------------------
class _DeviceSelectionSheet extends StatefulWidget {
  final BluetoothManagerService bt;
  const _DeviceSelectionSheet({required this.bt});

  @override
  State<_DeviceSelectionSheet> createState() => _DeviceSelectionSheetState();
}

class _DeviceSelectionSheetState extends State<_DeviceSelectionSheet> {
  @override
  void initState() {
    super.initState();
    widget.bt.addListener(_onBtChange);
  }

  @override
  void dispose() {
    widget.bt.removeListener(_onBtChange);
    super.dispose();
  }

  void _onBtChange() {
    if (mounted) setState(() {});
    if (widget.bt.isConnected && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = widget.bt.devices;
    final isScanning =
        widget.bt.state == BluetoothConnectionState.scanning;
    final isConnecting =
        widget.bt.state == BluetoothConnectionState.connecting;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.bluetooth_searching_rounded,
                    color: Color(0xFF1F2E22), size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Available Devices',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E2022),
                    ),
                  ),
                ),
                if (isScanning)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF388E3C)),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 22),
                    color: const Color(0xFF388E3C),
                    onPressed: () => widget.bt.startScan(),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Device list
          Flexible(
            child: devices.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isScanning
                              ? Icons.bluetooth_searching_rounded
                              : Icons.bluetooth_disabled_rounded,
                          size: 44,
                          color: const Color(0xFFBDBDBD),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isScanning
                              ? 'Scanning for devices…'
                              : 'No devices found',
                          style: const TextStyle(
                            color: Color(0xFF8A9099),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: devices.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final d = devices[i];
                      final name = d.name ?? 'Unknown Device';
                      final isHC = name.toUpperCase().contains('HC-05') ||
                          name.toUpperCase().contains('HC-06');
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isHC
                                ? const Color(0xFF388E3C).withOpacity(0.1)
                                : const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isHC
                                ? Icons.memory_rounded
                                : Icons.bluetooth_rounded,
                            color: isHC
                                ? const Color(0xFF388E3C)
                                : const Color(0xFF8A9099),
                            size: 22,
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E2022),
                          ),
                        ),
                        subtitle: Text(
                          d.address,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A9099),
                          ),
                        ),
                        trailing: isConnecting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF388E3C)),
                              )
                            : Icon(
                                Icons.chevron_right_rounded,
                                color: isHC
                                    ? const Color(0xFF388E3C)
                                    : const Color(0xFFBDBDBD),
                              ),
                        onTap: isConnecting
                            ? null
                            : () => widget.bt.connectToDevice(d),
                      );
                    },
                  ),
          ),
          // Safety bottom padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}
