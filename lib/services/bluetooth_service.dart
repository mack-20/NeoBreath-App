import 'dart:async';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart';

class BluetoothService {
  final FlutterBluetoothClassic _bluetooth = FlutterBluetoothClassic();
  StreamSubscription<dynamic>? _connectionSubscription;
  StreamSubscription<dynamic>? _dataSubscription;
  StreamSubscription<dynamic>? _stateSubscription;

  // Check if Bluetooth is supported
  Future<bool> isBluetoothSupported() async {
    try {
      return await _bluetooth.isBluetoothSupported();
    } catch (e) {
      print('Error checking Bluetooth support: $e');
      return false;
    }
  }

  // Check if Bluetooth is enabled
  Future<bool> isBluetoothEnabled() async {
    try {
      return await _bluetooth.isBluetoothEnabled();
    } catch (e) {
      print('Error checking Bluetooth status: $e');
      return false;
    }
  }

  // Get paired devices
  Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      return await _bluetooth.getPairedDevices();
    } catch (e) {
      print('Error getting paired devices: $e');
      return [];
    }
  }

  // Setup event listeners
  void setupListeners() {
    // Cancel any existing subscriptions to avoid duplicate listeners
    _stateSubscription?.cancel();
    _connectionSubscription?.cancel();
    _dataSubscription?.cancel();

    // Listen for Bluetooth state changes
    try {
      _stateSubscription = _bluetooth.onStateChanged.listen((state) {
        // Print the raw state object to be defensive across plugin versions
        print('Bluetooth state changed: $state');
      });
    } catch (e) {
      print('Could not subscribe to state changes: $e');
    }

    // Listen for connection state changes
    try {
      _connectionSubscription = _bluetooth.onConnectionChanged.listen((connectionState) {
        // Print the raw connection state object; detail parsing can be added
        print('Connection state changed: $connectionState');
      });
    } catch (e) {
      print('Could not subscribe to connection changes: $e');
    }

    // Listen for incoming data
    try {
      _dataSubscription = _bluetooth.onDataReceived.listen((data) {
        // Print raw data; parsing depends on plugin event shape
        print('Received data event: $data');
      });
    } catch (e) {
      print('Could not subscribe to data events: $e');
    }
  }

  /// Ensure runtime permissions required for Bluetooth operations on Android.
  /// Returns true when required permissions are granted or not required on the platform.
  Future<bool> ensureBluetoothPermissions() async {
    if (!Platform.isAndroid) return true;

    // Request Android 12+ Bluetooth runtime permissions and location (older devices)
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.locationWhenInUse,
    ].request();

    final scanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? false;
    final connectGranted = statuses[Permission.bluetoothConnect]?.isGranted ?? false;
    final locationGranted = statuses[Permission.locationWhenInUse]?.isGranted ?? false;

    // Accept when both scan and connect are granted, or when location is granted (older devices)
    return (scanGranted && connectGranted) || locationGranted;
  }


  // Connect to a device
  Future<bool> connectToDevice(String deviceAddress) async {
    try {
      return await _bluetooth.connect(deviceAddress);
    } catch (e) {
      print('Connection failed: $e');
      return false;
    }
  }

  // Send string data
  Future<bool> sendMessage(String message) async {
    try {
      return await _bluetooth.sendString(message);
    } catch (e) {
      print('Send failed: $e');
      return false;
    }
  }

  // Send raw data
  Future<bool> sendData(List<int> data) async {
    try {
      return await _bluetooth.sendData(data);
    } catch (e) {
      print('Send failed: $e');
      return false;
    }
  }

  // Disconnect
  Future<bool> disconnect() async {
    try {
      return await _bluetooth.disconnect();
    } catch (e) {
      print('Disconnect failed: $e');
      return false;
    }
  }

  // Start device discovery
  Future<bool> startDiscovery() async {
    try {
      return await _bluetooth.startDiscovery();
    } catch (e) {
      print('Discovery failed: $e');
      return false;
    }
  }

  // Stop device discovery
  Future<bool> stopDiscovery() async {
    try {
      return await _bluetooth.stopDiscovery();
    } catch (e) {
      print('Stop discovery failed: $e');
      return false;
    }
  }

  // Clean up resources
  void dispose() {
    try {
      _connectionSubscription?.cancel();
    } catch (_) {}
    _connectionSubscription = null;

    try {
      _dataSubscription?.cancel();
    } catch (_) {}
    _dataSubscription = null;

    try {
      _stateSubscription?.cancel();
    } catch (_) {}
    _stateSubscription = null;
  }
}