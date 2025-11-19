import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';
import '../models/reading.dart';

class VitalSignsData {
  final int heartRate;
  final int spO2;
  final int breathingRate;
  final DateTime timestamp;

  VitalSignsData({
    required this.heartRate,
    required this.spO2,
    required this.breathingRate,
    required this.timestamp,
  });

  @override
  String toString() {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
    return '''
═══════════════════════════════════════════════════
  VITAL SIGNS DATA
═══════════════════════════════════════════════════
  ❤️  Heart Rate:       $heartRate BPM
  🫁 SpO2:             $spO2 %
  💨 Breathing Rate:   $breathingRate breaths/min
  🕐 Timestamp:        ${formatter.format(timestamp)}
═══════════════════════════════════════════════════
    ''';
  }

  Map<String, dynamic> toJson() {
    return {
      'heartRate': heartRate,
      'spO2': spO2,
      'breathingRate': breathingRate,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class HubService {
  BluetoothConnection? _connection;
  StreamSubscription? _dataSubscription;
  final _vitalSignsController = StreamController<VitalSignsData>.broadcast();
  
  int? _babyProfileId;
  final DatabaseService _databaseService = DatabaseService.instance;

  /// Stream of vital signs data
  Stream<VitalSignsData> get vitalSignsStream => _vitalSignsController.stream;

  /// Initialize connection with Bluetooth device and baby profile ID
  void setConnection(BluetoothConnection connection, {int? babyProfileId}) {
    _connection = connection;
    _babyProfileId = babyProfileId;
    _startListening();
  }

  /// Start listening for data from ESP32
  void _startListening() {
    if (_connection == null) {
      print('❌ Error: No Bluetooth connection available');
      return;
    }

    _dataSubscription = _connection!.input?.listen(
      (data) {
        _processData(data);
      },
      onError: (error) {
        print('❌ Error reading data: $error');
      },
      onDone: () {
        print('⚠️  Connection closed by device');
        disconnect();
      },
    );

    print('✅ Started listening for ESP32 data');
  }

  /// Process incoming data from ESP32
  void _processData(Uint8List data) {
    try {
      // Convert bytes to string
      String rawString = String.fromCharCodes(data).trim();

      if (rawString.isEmpty) {
        return;
      }

      print('📥 Raw data received: $rawString');

      // Parse the data
      final vitalSigns = _parseVitalSigns(rawString);

      if (vitalSigns != null) {
        print(vitalSigns.toString());
        _vitalSignsController.add(vitalSigns);
        
        // Save reading to database if baby profile is set
        if (_babyProfileId != null) {
          _saveReadingToDatabase(vitalSigns);
        }
      }
    } catch (e) {
      print('❌ Error processing data: $e');
    }
  }

  /// Save reading to database
  Future<void> _saveReadingToDatabase(VitalSignsData vitalSigns) async {
    try {
      final reading = Reading(
        babyProfileId: _babyProfileId!,
        heartRate: vitalSigns.heartRate,
        spO2: vitalSigns.spO2,
        breathingRate: vitalSigns.breathingRate,
        timestamp: vitalSigns.timestamp,
      );
      
      await _databaseService.addReading(reading);
      print('💾 Reading saved to database for baby profile $_babyProfileId');
    } catch (e) {
      print('❌ Error saving reading to database: $e');
    }
  }

  /// Parse vital signs from string format: HR120SPO296BR120
  VitalSignsData? _parseVitalSigns(String data) {
    try {
      // Regular expression to match HR, SPO2, BR values
      final pattern = RegExp(r'HR(\d+)SPO2(\d+)BR(\d+)');
      final match = pattern.firstMatch(data);

      if (match == null) {
        print('⚠️  Data format not recognized: $data');
        return null;
      }

      final heartRate = int.parse(match.group(1) ?? '0');
      final spO2 = int.parse(match.group(2) ?? '0');
      final breathingRate = int.parse(match.group(3) ?? '0');

      // Validate ranges
      if (!_isValidHeartRate(heartRate)) {
        print('⚠️  Invalid heart rate: $heartRate BPM (expected 40-200)');
      }

      if (!_isValidSpO2(spO2)) {
        print('⚠️  Invalid SpO2: $spO2% (expected 70-100)');
      }

      if (!_isValidBreathingRate(breathingRate)) {
        print('⚠️  Invalid breathing rate: $breathingRate breaths/min (expected 10-100)');
      }

      return VitalSignsData(
        heartRate: heartRate,
        spO2: spO2,
        breathingRate: breathingRate,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('❌ Error parsing vital signs: $e');
      return null;
    }
  }

  /// Validate heart rate range
  bool _isValidHeartRate(int hr) {
    return hr >= 40 && hr <= 200;
  }

  /// Validate SpO2 range
  bool _isValidSpO2(int spo2) {
    return spo2 >= 70 && spo2 <= 100;
  }

  /// Validate breathing rate range
  bool _isValidBreathingRate(int br) {
    return br >= 10 && br <= 100;
  }

  /// Send command to ESP32 (optional)
  Future<void> sendCommand(String command) async {
    if (_connection == null || !_connection!.isConnected) {
      print('❌ Error: Bluetooth connection not available');
      return;
    }

    try {
      _connection!.output.add(Uint8List.fromList(command.codeUnits));
      await _connection!.output.allSent;
      print('✅ Command sent: $command');
    } catch (e) {
      print('❌ Error sending command: $e');
    }
  }

  /// Disconnect from device
  void disconnect() {
    _dataSubscription?.cancel();
    _connection?.dispose();
    _connection = null;
    print('🔌 Disconnected from device');
  }

  /// Check if connected
  bool get isConnected => _connection != null && _connection!.isConnected;

  /// Dispose the service
  void dispose() {
    _dataSubscription?.cancel();
    _connection?.dispose();
    _vitalSignsController.close();
  }
}
