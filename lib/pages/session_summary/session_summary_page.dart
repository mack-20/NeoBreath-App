import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/reading.dart';

class SessionSummaryPage extends StatefulWidget {
  final String babyName;
  final List<Reading> readings;
  final Map<String, double> statistics;

  const SessionSummaryPage({
    super.key,
    required this.babyName,
    required this.readings,
    required this.statistics,
  });

  @override
  State<SessionSummaryPage> createState() => _SessionSummaryPageState();
}

class _SessionSummaryPageState extends State<SessionSummaryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Monitoring Session Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baby name and session info
            _buildSessionHeader(),

            // Average readings cards
            _buildAverageReadingsSection(),

            // Min/Max values
            _buildMinMaxSection(),

            // Charts
            _buildChartsSection(),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionHeader() {
    final duration = widget.readings.isNotEmpty
        ? widget.readings.last.timestamp.difference(widget.readings.first.timestamp)
        : Duration.zero;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Baby ${widget.babyName}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoTile('Duration', _formatDuration(duration)),
              _buildInfoTile(
                'Readings',
                '${widget.statistics['readingCount']?.toInt() ?? 0}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF8A8A8A),
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildAverageReadingsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Average Readings',
            style: TextStyle(
              fontSize: 18,
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
                  value: '${(widget.statistics['avgHeartRate'] ?? 0).toStringAsFixed(1)}',
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
                  value: '${(widget.statistics['avgSpO2'] ?? 0).toStringAsFixed(1)}',
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
                  value: '${(widget.statistics['avgBreathingRate'] ?? 0).toStringAsFixed(1)}',
                  unit: 'br/m',
                  icon: Icons.air,
                  color: Color(0xFF4CAF50),
                  bgColor: Color(0xFFE8F5E9),
                ),
              ),
            ],
          ),
        ],
      ),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              unit,
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF8A8A8A),
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF48576B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinMaxSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Range (Min - Max)',
            style: TextStyle(
              fontSize: 18,
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
                    '${(widget.statistics['minHeartRate'] ?? 0).toStringAsFixed(0)} - ${(widget.statistics['maxHeartRate'] ?? 0).toStringAsFixed(0)}',
                    'BPM',
                  ),
                  Divider(height: 16),
                  _buildRangeRow(
                    'SpO2',
                    '${(widget.statistics['minSpO2'] ?? 0).toStringAsFixed(0)} - ${(widget.statistics['maxSpO2'] ?? 0).toStringAsFixed(0)}',
                    '%',
                  ),
                  Divider(height: 16),
                  _buildRangeRow(
                    'Breathing Rate',
                    '${(widget.statistics['minBreathingRate'] ?? 0).toStringAsFixed(0)} - ${(widget.statistics['maxBreathingRate'] ?? 0).toStringAsFixed(0)}',
                    'br/min',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeRow(String label, String range, String unit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF48576B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '$range $unit',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildChartsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Readings Over Time',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          _buildChart('Heart Rate (BPM)', widget.readings, (r) => r.heartRate.toDouble(), Color(0xFFFF6B6B)),
          SizedBox(height: 20),
          _buildChart('SpO2 (%)', widget.readings, (r) => r.spO2.toDouble(), Color(0xFF1B86ED)),
          SizedBox(height: 20),
          _buildChart('Breathing Rate (br/min)', widget.readings, (r) => r.breathingRate.toDouble(), Color(0xFF4CAF50)),
        ],
      ),
    );
  }

  Widget _buildChart(
    String title,
    List<Reading> readings,
    double Function(Reading) getValue,
    Color color,
  ) {
    if (readings.isEmpty) {
      return Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text('No data available for $title'),
          ),
        ),
      );
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
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              height: 150,
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

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes}m ${seconds}s';
  }
}
