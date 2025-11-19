import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import '../../models/baby_profile.dart';
import '../../models/reading.dart';
import '../../services/hub_service.dart';
import '../../services/database_service.dart';
import '../bluetooth/bluetooth_page.dart';
import '../session_summary/session_summary_page.dart';
import '../settings/settings_drawer.dart';

class Home extends StatefulWidget {
  final BabyProfile profile;

  const Home({super.key, required this.profile});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Services
  final HubService _hubService = HubService();
  final DatabaseService _databaseService = DatabaseService.instance;

  // Bluetooth connection state
  bool _isConnected = false;

  // Vitals data state
  bool _hasData = false;

  // Real vitals data from ESP32
  double? _heartRate;
  double? _oxygenSaturation;
  double? _breathingRate;

  // History data for charts (last 20 readings)
  final List<double> _heartRateHistory = [];
  final List<double> _oxygenHistory = [];
  final List<double> _breathingHistory = [];

  // Session tracking
  DateTime? _sessionStartTime;
  List<Reading> _sessionReadings = [];


  @override
  void initState() {
    super.initState();

    // Load previous readings from database when page is created
    _loadPreviousReadings();

    // Listen to vital signs data from ESP32
    _hubService.vitalSignsStream.listen((vitalSigns) {
      if (mounted) {
        setState(() {
          _hasData = true;
          _heartRate = vitalSigns.heartRate.toDouble();
          _oxygenSaturation = vitalSigns.spO2.toDouble();
          _breathingRate = vitalSigns.breathingRate.toDouble();

          // Add to history (keep last 20 readings)
          _addToHistory(_heartRateHistory, _heartRate!);
          _addToHistory(_oxygenHistory, _oxygenSaturation!);
          _addToHistory(_breathingHistory, _breathingRate!);
        });
      }
    });

    // For testing UI with mock data, uncomment:
    // _loadMockData();
  }

  @override
  void dispose() {
    _hubService.dispose();
    super.dispose();
  }

  void _addToHistory(List<double> history, double value) {
    history.add(value);
    if (history.length > 20) {
      history.removeAt(0);
    }
  }

  Future<void> _loadPreviousReadings() async {
    try {
      print('🔍 Attempting to load previous readings...');
      print('📌 Profile ID: ${widget.profile.id}');
      
      if (widget.profile.id == null) {
        print('⚠️ Profile ID is null, cannot load readings');
        return;
      }

      // Fetch the latest 20 readings from database
      final readings = await _databaseService.getLatestReadings(
        widget.profile.id!,
        20,
      );

      print('✅ Loaded ${readings.length} previous readings from database');

      if (readings.isNotEmpty && mounted) {
        setState(() {
          // Clear current history
          _heartRateHistory.clear();
          _oxygenHistory.clear();
          _breathingHistory.clear();

          // Load previous readings into history
          for (final reading in readings) {
            _heartRateHistory.add(reading.heartRate.toDouble());
            _oxygenHistory.add(reading.spO2.toDouble());
            _breathingHistory.add(reading.breathingRate.toDouble());
          }

          // Set hasData to true and set current values to the latest readings
          _hasData = true;
          _heartRate = readings.last.heartRate.toDouble();
          _oxygenSaturation = readings.last.spO2.toDouble();
          _breathingRate = readings.last.breathingRate.toDouble();

          print('📊 History loaded - HR: $_heartRate, SpO2: $_oxygenSaturation, BR: $_breathingRate');
        });
      } else {
        print('⚠️ No previous readings found for this profile');
      }
    } catch (e) {
      print('❌ Error loading previous readings: $e');
    }
  }

  Future<void> _disconnectDevice() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stop Monitoring'),
        content: Text(
          'Are you sure you want to stop monitoring ${widget.profile.firstName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFF6B6B)),
            child: Text('Stop'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Stop listening for new data from ESP32
    _hubService.disconnect();

    // Capture session data before clearing
    DateTime? sessionEndTime = DateTime.now();
    
    // Fetch all readings from this session from database
    List<Reading> sessionReadings = [];
    Map<String, double> statistics = {};
    
    if (_sessionStartTime != null && widget.profile.id != null) {
      try {
        sessionReadings = await _databaseService.getReadingsByDateRange(
          widget.profile.id!,
          _sessionStartTime!,
          sessionEndTime,
        );
        
        statistics = await _databaseService.getSessionStatistics(
          widget.profile.id!,
          _sessionStartTime!,
          sessionEndTime,
        );
      } catch (e) {
        print('Error fetching session data: $e');
      }
    }

    // Disconnect from device
    setState(() {
      _isConnected = false;

      // Clear current vitals data but keep history for display
      _heartRate = null;
      _oxygenSaturation = null;
      _breathingRate = null;
      // Note: Do NOT clear history - it should remain visible on the page
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Disconnected from NeoBreath Hub'),
          backgroundColor: Color(0xFF8A8A8A),
          duration: Duration(seconds: 1),
        ),
      );

      // Navigate to session summary if we have data
      if (sessionReadings.isNotEmpty && mounted) {
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SessionSummaryPage(
                  babyName: widget.profile.firstName,
                  readings: sessionReadings,
                  statistics: statistics,
                ),
              ),
            ).then((_) {
              // After summary page is closed, reload the latest readings
              _loadPreviousReadings();
            });
          }
        });
      }
    }
  }

  // Navigate to Bluetooth page
  Future<void> _openBluetoothPage() async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(builder: (context) => BluetoothPage()),
    );

    // Update connection state based on result
    if (result is BluetoothConnection && mounted) {
      _hubService.setConnection(result, babyProfileId: widget.profile.id);
      await _loadPreviousReadings();
      setState(() {
        _isConnected = true;
        _sessionStartTime = DateTime.now();
        _sessionReadings = [];
      });
    } else if (result == true && mounted) {
      await _loadPreviousReadings();
      setState(() {
        _isConnected = true;
        _sessionStartTime = DateTime.now();
        _sessionReadings = [];
      });
    }
  }

  String _getStatusText() {
    if (!_hasData) {
      return 'No Data Available';
    }

    // Check if all vitals are in normal range
    final heartRateNormal =
        _heartRate != null && _heartRate! >= 100 && _heartRate! <= 160;
    final oxygenNormal = _oxygenSaturation != null && _oxygenSaturation! >= 95;
    final breathingNormal =
        _breathingRate != null &&
        _breathingRate! >= 30 &&
        _breathingRate! <= 60;

    if (heartRateNormal && oxygenNormal && breathingNormal) {
      return 'All Vitals Stable';
    } else {
      return 'Check Vitals';
    }
  }

  Color _getStatusColor() {
    if (!_hasData) {
      return Color(0xFF8A8A8A); // Grey
    }

    final heartRateNormal =
        _heartRate != null && _heartRate! >= 100 && _heartRate! <= 160;
    final oxygenNormal = _oxygenSaturation != null && _oxygenSaturation! >= 95;
    final breathingNormal =
        _breathingRate != null &&
        _breathingRate! >= 30 &&
        _breathingRate! <= 60;

    if (heartRateNormal && oxygenNormal && breathingNormal) {
      return Color(0xFF4CAF50); // Green
    } else {
      return Color(0xFFFF6B6B); // Red
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Color(0xFFF6F7F8),
        appBar: _buildAppBar(),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status banner
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(20),
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isConnected ? Icons.sensors : Icons.sensors_off,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      _isConnected
                          ? 'Monitoring: ${_getStatusText()}'
                          : 'Not Connected',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Section title
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 20.0,
                ),
                child: Text(
                  "Real-Time Vitals",
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),

              // Heart Rate Card
              _buildVitalCard(
                title: "Heart Rate",
                value: _heartRate?.toStringAsFixed(0),
                unit: "BPM",
                icon: Icons.favorite_border,
                iconColor: Color(0xFFFF6B6B),
                iconBgColor: Color(0xFFFFE5E5),
                historyData: _heartRateHistory,
              ),

              // Oxygen Saturation Card
              _buildVitalCard(
                title: "Oxygen Saturation",
                value: _oxygenSaturation?.toStringAsFixed(0),
                unit: "% SpO₂",
                icon: Icons.water_drop_outlined,
                iconColor: Color(0xFF1B86ED),
                iconBgColor: Color(0xFFE2EDFF),
                historyData: _oxygenHistory,
              ),

              // Breathing Rate Card
              _buildVitalCard(
                title: "Breathing Rate",
                value: _breathingRate?.toStringAsFixed(0),
                unit: "Breaths/min",
                icon: Icons.air,
                iconColor: Color(0xFF4CAF50),
                iconBgColor: Color(0xFFE8F5E9),
                historyData: _breathingHistory,
              ),

              if (_isConnected) ...[
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _disconnectDevice,
                      icon: Icon(Icons.stop_circle_outlined, size: 24),
                      label: Text(
                        'Stop Monitoring',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF6B6B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVitalCard({
    required String title,
    required String? value,
    required String unit,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required List<double> historyData,
  }) {
    final hasData = value != null;
    final displayValue = hasData ? value : '--';

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF48576B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Value row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                    color: hasData ? Colors.black87 : Color(0xFFB0B0B0),
                  ),
                ),
                SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    unit,
                    style: TextStyle(
                      color: Color(0xFF48576B),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Chart
            SizedBox(
              height: 80,
              child: hasData && historyData.isNotEmpty
                  ? _buildChart(historyData, iconColor)
                  : _buildEmptyChart(),
            ),

            // No data message
            if (!hasData) ...[
              SizedBox(height: 8),
              Center(
                child: Text(
                  'No recordings yet',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A8A8A),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<double> data, Color color) {
    final spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    final values = data;
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final yRange = maxY - minY;
    final yPadding = yRange > 0 ? yRange * 0.2 : 10.0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: minY - yPadding,
        maxY: maxY + yPadding,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: [FlSpot(0, 50), FlSpot(10, 50)],
            isCurved: false,
            color: Color(0xFFE0E0E0),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        // Disable button when already connected
        onPressed: _isConnected ? null : _openBluetoothPage,
        icon: Icon(
          _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
          color: _isConnected ? Color(0xFF1B86ED) : Color(0xFF8A8A8A),
        ),
        tooltip: _isConnected ? 'Connected' : 'Connect Device',
      ),
      title: Text(
        'Baby ${widget.profile.firstName}',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () {
            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: 'Close settings',
              barrierColor: Colors.black.withOpacity(0.3),
              transitionDuration: Duration(milliseconds: 300),
              pageBuilder: (context, animation, secondaryAnimation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: SettingsDrawer(profile: widget.profile),
                );
              },
            );
          },
          icon: Icon(Icons.settings, color: Colors.black87),
        ),
      ],
    );
  }
}
