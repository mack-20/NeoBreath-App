import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  final _flutterBlueClassicPlugin = FlutterBlueClassic();

  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  StreamSubscription? _adapterStateSubscription;

  final Set<BluetoothDevice> _scanResults = {};
  StreamSubscription? _scanSubscription;

  bool _isScanning = false;
  int? _connectingToIndex;
  StreamSubscription? _scanningStateSubscription;
  
  BluetoothConnection? _currentConnection;
  Timer? _refreshTimer;

  static const String TARGET_DEVICE_NAME = "NeoBreath Hub";

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    BluetoothAdapterState adapterState = _adapterState;

    try {
      // Request Bluetooth permissions first
      await _requestBluetoothPermissions();

      adapterState = await _flutterBlueClassicPlugin.adapterStateNow;
      if (kDebugMode) print('Bluetooth adapter state: $adapterState');
      
      _adapterStateSubscription =
          _flutterBlueClassicPlugin.adapterState.listen((current) {
        if (kDebugMode) print('Adapter state changed to: $current');
        if (mounted) {
          setState(() => _adapterState = current);
          // Check if Bluetooth is turned off
          if (current != BluetoothAdapterState.on) {
            _showBluetoothOffDialog();
          }
        }
      });
      _scanSubscription =
          _flutterBlueClassicPlugin.scanResults.listen((device) {
        if (kDebugMode) print('Device found: ${device.name} (${device.address})');
        if (mounted) setState(() => _scanResults.add(device));
      });
      _scanningStateSubscription =
          _flutterBlueClassicPlugin.isScanning.listen((isScanning) {
        if (kDebugMode) print('Scanning state: $isScanning');
        if (mounted) setState(() => _isScanning = isScanning);
      });
    } catch (e) {
      if (kDebugMode) print('Error in initPlatformState: $e');
    }

    if (!mounted) return;

    setState(() {
      _adapterState = adapterState;
    });

    // Check if Bluetooth is off on init
    if (adapterState != BluetoothAdapterState.on) {
      _showBluetoothOffDialog();
      return;
    }

    // Auto-start scan on init if Bluetooth is on
    _startScan();

    // Start auto-refresh timer - refresh UI every 10 seconds
    _refreshTimer = Timer.periodic(Duration(seconds: 10), (_) {
      if (mounted) {
        setState(() {
          if (kDebugMode) print('Auto-refresh: ${_scanResults.length} devices found');
        });
      }
    });
  }

  Future<void> _requestBluetoothPermissions() async {
    try {
      // Request Bluetooth permissions based on platform
      final status = await Permission.bluetooth.request();
      if (kDebugMode) print('Bluetooth permission status: $status');

      // Also request location permission for Android (required for BLE scanning)
      final locationStatus = await Permission.location.request();
      if (kDebugMode) print('Location permission status: $locationStatus');
    } catch (e) {
      if (kDebugMode) print('Error requesting permissions: $e');
    }
  }

  Future<void> _startScan() async {
    if (_isScanning) {
      if (kDebugMode) print('Scan already in progress');
      return;
    }

    if (kDebugMode) print('Starting Bluetooth scan...');

    setState(() {
      _scanResults.clear();
      _isScanning = true;
    });

    try {
      // Start discovery scan
      _flutterBlueClassicPlugin.startScan();
      if (kDebugMode) print('Scan initiated');
      
      // Set a timeout for scanning - scan for 10 seconds
      await Future.delayed(Duration(seconds: 10));
      
      if (kDebugMode) print('Scan timeout reached. Found ${_scanResults.length} device(s)');

      // Stop the scan after the timeout
      if (mounted) {
        _stopScan();
      }
    } catch (e) {
      if (kDebugMode) print('Error starting scan: $e');
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  void _showBluetoothOffDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Bluetooth Off'),
        content: Text(
          'Please enable Bluetooth to connect to NeoBreath Hub and monitor your baby.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, false); // Close Bluetooth page
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              // Turn on Bluetooth
              _flutterBlueClassicPlugin.turnOn();
              // Retry after a short delay
              await Future.delayed(Duration(seconds: 1));
              if (mounted) {
                await initPlatformState();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
            ),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _stopScan() {
    try {
      _flutterBlueClassicPlugin.stopScan();
      if (mounted) {
        setState(() => _isScanning = false);
      }
    } catch (e) {
      if (kDebugMode) print('Error stopping scan: $e');
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device, int index) async {
    setState(() => _connectingToIndex = index);

    try {
      final connection =
          await _flutterBlueClassicPlugin.connect(device.address);

      if (!mounted) return;

      if (connection != null && connection.isConnected) {
        _currentConnection = connection;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connected to ${device.name}'),
              backgroundColor: Color(0xFF4CAF50),
              duration: Duration(seconds: 2),
            ),
          );

          // Wait a moment to show the success message
          await Future.delayed(Duration(milliseconds: 500));

          // Return the connection object to home page
          if (mounted) Navigator.pop(context, connection);
        }
      }
    } catch (e) {
      if (kDebugMode) print('Connection error: $e');

      if (mounted) {
        setState(() => _connectingToIndex = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to ${device.name}'),
            backgroundColor: Color(0xFFFF6B6B),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _adapterStateSubscription?.cancel();
    _scanSubscription?.cancel();
    _scanningStateSubscription?.cancel();
    _refreshTimer?.cancel();
    _stopScan();
    _currentConnection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<BluetoothDevice> scanResults = _scanResults.toList();

    return Scaffold(
      backgroundColor: Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _connectingToIndex == null
              ? () => Navigator.pop(context, false)
              : null,
        ),
        title: Text(
          'Connect to Device',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildHeader(scanResults),
          Expanded(
            child: scanResults.isEmpty
                ? _buildEmptyState()
                : _buildDeviceList(scanResults),
          ),
        ],
      ),
      floatingActionButton: _isScanning
          ? null
          : FloatingActionButton.extended(
              onPressed: _startScan,
              backgroundColor: Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              icon: Icon(Icons.bluetooth_searching),
              label: Text('Scan Devices'),
            ),
    );
  }

  Widget _buildHeader(List<BluetoothDevice> devices) {
    String statusMessage = _getStatusMessage(devices);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Devices',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              if (_isScanning) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF6B6B),
                    ),
                  ),
                ),
                SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  statusMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isScanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            _isScanning
                ? 'Searching for devices...'
                : 'No devices found',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF8A8A8A),
            ),
          ),
          if (!_isScanning) ...[
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _startScan,
              icon: Icon(Icons.refresh),
              label: Text('Scan Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF6B6B),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceList(List<BluetoothDevice> devices) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        final deviceName = device.name ?? 'Unknown Device';
        final isTargetDevice = deviceName == TARGET_DEVICE_NAME;
        final isConnecting = _connectingToIndex == index;

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isTargetDevice
                ? BorderSide(color: Color(0xFFFF6B6B), width: 2)
                : BorderSide.none,
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isTargetDevice
                    ? Color(0xFFFFE5E5)
                    : Color(0xFFE2EDFF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bluetooth,
                color: isTargetDevice
                    ? Color(0xFFFF6B6B)
                    : Color(0xFF1B86ED),
              ),
            ),
            title: Text(
              deviceName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  device.address,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
                if (isTargetDevice) ...[
                  SizedBox(height: 4),
                  Text(
                    'Recommended',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF6B6B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            trailing: isConnecting
                ? SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF6B6B),
                        ),
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () => _connectToDevice(device, index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isTargetDevice
                          ? Color(0xFFFF6B6B)
                          : Color(0xFF1B86ED),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Connect'),
                  ),
          ),
        );
      },
    );
  }

  String _getStatusMessage(List<BluetoothDevice> devices) {
    if (_isScanning) {
      return 'Scanning for devices...';
    }

    if (devices.isEmpty) {
      return 'No devices found. Tap scan to search.';
    }

    final hasTarget =
        devices.any((d) => d.name == TARGET_DEVICE_NAME);
    if (hasTarget) {
      return 'Tap on "$TARGET_DEVICE_NAME" to connect';
    }

    return 'Found ${devices.length} device(s)';
  }
}