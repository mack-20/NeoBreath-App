import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/baby_profile.dart';
import '../bluetooth/bluetooth_page.dart';

class Home extends StatefulWidget {
  final BabyProfile profile;

  const Home({super.key, required this.profile});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Bluetooth connection state
  bool _isConnected = false;

  // Vitals data state
  bool _hasData = false;

  // Mock vitals data (will be replaced with real data from ESP32)
  double? _heartRate;
  double? _oxygenSaturation;
  double? _breathingRate;

  // History data for charts (last 20 readings)
  final List<double> _heartRateHistory = [];
  final List<double> _oxygenHistory = [];
  final List<double> _breathingHistory = [];

  @override
  void initState() {
    super.initState();

    // For testing UI with mock data, uncomment:
    // _loadMockData();
  }

  @override
  void dispose() {
    super.dispose();
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

    // Disconnect from device
    setState(() {
      _isConnected = false;
      _hasData = false;

      // Clear all vitals data
      _heartRate = null;
      _oxygenSaturation = null;
      _breathingRate = null;

      // Clear history
      _heartRateHistory.clear();
      _oxygenHistory.clear();
      _breathingHistory.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Disconnected from NeoBreath Hub'),
          backgroundColor: Color(0xFF8A8A8A),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Navigate to Bluetooth page
  Future<void> _openBluetoothPage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => BluetoothPage()),
    );

    // Update connection state based on result
    if (result == true && mounted) {
      setState(() {
        _isConnected = true;
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
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Settings'),
                content: Text('Settings screen coming soon!'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK'),
                  ),
                ],
              ),
            );
          },
          icon: Icon(Icons.settings, color: Colors.black87),
        ),
      ],
    );
  }
}
