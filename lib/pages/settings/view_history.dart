import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/baby_profile.dart';
import '../../models/reading.dart';
import '../../services/database_service.dart';

class ViewHistory extends StatefulWidget {
  final BabyProfile profile;

  const ViewHistory({
    super.key,
    required this.profile,
  });

  @override
  State<ViewHistory> createState() => _ViewHistoryState();
}

class _ViewHistoryState extends State<ViewHistory> {
  final DatabaseService _databaseService = DatabaseService.instance;
  int _selectedTabIndex = 0;

  late Future<Map<String, dynamic>> _historyData;

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  void _loadHistoryData() {
    _historyData = _fetchHistoryData();
  }

  Future<Map<String, dynamic>> _fetchHistoryData() async {
    final now = DateTime.now();
    final last7Days = now.subtract(Duration(days: 7));
    final lastMonth = now.subtract(Duration(days: 30));

    try {
      // Fetch readings for last 7 days
      final readings7Days = await _databaseService.getReadingsByDateRange(
        widget.profile.id!,
        last7Days,
        now,
      );

      final stats7Days = await _databaseService.getSessionStatistics(
        widget.profile.id!,
        last7Days,
        now,
      );

      // Fetch readings for last month
      final readingsMonth = await _databaseService.getReadingsByDateRange(
        widget.profile.id!,
        lastMonth,
        now,
      );

      final statsMonth = await _databaseService.getSessionStatistics(
        widget.profile.id!,
        lastMonth,
        now,
      );

      return {
        'readings7Days': readings7Days,
        'stats7Days': stats7Days,
        'readingsMonth': readingsMonth,
        'statsMonth': statsMonth,
      };
    } catch (e) {
      print('Error fetching history data: $e');
      return {
        'readings7Days': [],
        'stats7Days': {},
        'readingsMonth': [],
        'statsMonth': {},
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _historyData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: Color(0xFF1B86ED)),
          );
        }

        if (!snapshot.hasData) {
          return Center(
            child: Text('Error loading history'),
          );
        }

        final data = snapshot.data!;
        final isLast7Days = _selectedTabIndex == 0;
        final readings =
            isLast7Days ? data['readings7Days'] as List<Reading> : data['readingsMonth'] as List<Reading>;
        final stats = isLast7Days ? data['stats7Days'] as Map<String, double> : data['statsMonth'] as Map<String, double>;

        return Column(
          children: [
            // Tabs
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTab(
                      label: 'Last 7 Days',
                      isSelected: _selectedTabIndex == 0,
                      onTap: () {
                        setState(() => _selectedTabIndex = 0);
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildTab(
                      label: 'Last Month',
                      isSelected: _selectedTabIndex == 1,
                      onTap: () {
                        setState(() => _selectedTabIndex = 1);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: readings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 48, color: Color(0xFFC0C0C0)),
                          SizedBox(height: 12),
                          Text(
                            'No readings yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF8A8A8A),
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Average Readings
                            if (stats.isNotEmpty) ...[
                              _buildAverageSection(stats),
                              SizedBox(height: 20),
                            ],

                            // Range Section
                            if (stats.isNotEmpty) ...[
                              _buildRangeSection(stats),
                              SizedBox(height: 20),
                            ],

                            // Charts
                            _buildChart(
                              'Heart Rate (BPM)',
                              readings,
                              (r) => r.heartRate.toDouble(),
                              Color(0xFFFF6B6B),
                            ),
                            SizedBox(height: 16),
                            _buildChart(
                              'SpO2 (%)',
                              readings,
                              (r) => r.spO2.toDouble(),
                              Color(0xFF1B86ED),
                            ),
                            SizedBox(height: 16),
                            _buildChart(
                              'Breathing Rate (br/min)',
                              readings,
                              (r) => r.breathingRate.toDouble(),
                              Color(0xFF4CAF50),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Color(0xFF1B86ED) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Color(0xFF1B86ED) : Color(0xFF8A8A8A),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAverageSection(Map<String, double> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Average Readings',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Heart Rate',
                value: '${(stats['avgHeartRate'] ?? 0).toStringAsFixed(1)}',
                unit: 'BPM',
                icon: Icons.favorite_border,
                color: Color(0xFFFF6B6B),
                bgColor: Color(0xFFFFE5E5),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'SpO2',
                value: '${(stats['avgSpO2'] ?? 0).toStringAsFixed(1)}',
                unit: '%',
                icon: Icons.water_drop_outlined,
                color: Color(0xFF1B86ED),
                bgColor: Color(0xFFE2EDFF),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Breathing',
                value: '${(stats['avgBreathingRate'] ?? 0).toStringAsFixed(1)}',
                unit: 'br/m',
                icon: Icons.air,
                color: Color(0xFF4CAF50),
                bgColor: Color(0xFFE8F5E9),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 2),
            Text(
              unit,
              style: TextStyle(
                fontSize: 9,
                color: Color(0xFF8A8A8A),
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF48576B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeSection(Map<String, double> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Range (Min - Max)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildRangeRow(
                  'Heart Rate',
                  '${(stats['minHeartRate'] ?? 0).toStringAsFixed(0)} - ${(stats['maxHeartRate'] ?? 0).toStringAsFixed(0)}',
                  'BPM',
                ),
                Divider(height: 16),
                _buildRangeRow(
                  'SpO2',
                  '${(stats['minSpO2'] ?? 0).toStringAsFixed(0)} - ${(stats['maxSpO2'] ?? 0).toStringAsFixed(0)}',
                  '%',
                ),
                Divider(height: 16),
                _buildRangeRow(
                  'Breathing Rate',
                  '${(stats['minBreathingRate'] ?? 0).toStringAsFixed(0)} - ${(stats['maxBreathingRate'] ?? 0).toStringAsFixed(0)}',
                  'br/min',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRangeRow(String label, String range, String unit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF48576B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '$range $unit',
          style: TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildChart(
    String title,
    List<Reading> readings,
    double Function(Reading) getValue,
    Color color,
  ) {
    if (readings.isEmpty) {
      return SizedBox.shrink();
    }

    final values = readings.map((r) => getValue(r)).toList();
    final spots = values.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final padding = (maxVal - minVal) * 0.1;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (readings.length - 1).toDouble(),
                  minY: minVal - padding,
                  maxY: maxVal + padding,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
