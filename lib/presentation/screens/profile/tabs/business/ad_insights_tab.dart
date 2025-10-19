import 'package:flutter/material.dart';

class BusinessAdInsightsTab extends StatefulWidget {
  final String userId;

  const BusinessAdInsightsTab({Key? key, required this.userId})
      : super(key: key);

  @override
  State<BusinessAdInsightsTab> createState() => _BusinessAdInsightsTabState();
}

class _BusinessAdInsightsTabState extends State<BusinessAdInsightsTab> {
  String _selectedRange = 'Last 30 days';

  final List<String> _ranges = [
    'Last 7 days',
    'Last 30 days',
    '3 months',
    '6 months',
    'Last year',
    'All time',
  ];

  // Dummy data for chart (values correspond to points across the selected range)
  List<double> _chartData = [10, 22, 18, 30, 25, 28, 35, 40, 38, 45];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'Ad Insights',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _selectedRange,
                  items: _ranges
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _selectedRange = v;
                      _chartData = List<double>.from(_chartData.reversed);
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: <Widget>[
                Expanded(child: _metricCard('Total Reach', '12.4K', Colors.purple)),
                const SizedBox(width: 8),
                Expanded(child: _metricCard('Total Likes', '3.2K', Colors.orange)),
              ],
            ),

            const SizedBox(height: 8),
            _metricCard('Total Engagement (30 days)', '5.6K', Colors.teal),

            const SizedBox(height: 16),

            const Text('Engagement over time', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            SizedBox(
              height: 180,
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _SimpleLineChart(data: _chartData),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const Icon(Icons.trending_up_outlined),
                title: const Text('Top performing ad'),
                subtitle: const Text('Ad: "Summer Promo" — 23% increase in reach'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String title, String value, Color color) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

class _SimpleLineChart extends StatelessWidget {
  final List<double> data;

  const _SimpleLineChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return CustomPaint(
        size: Size(constraints.maxWidth, constraints.maxHeight),
        painter: _LineChartPainter(data),
      );
    });
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;

  _LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final bg = Paint()..color = Colors.blue.withOpacity(0.08);

    if (data.isEmpty) return;

    final max = data.reduce((a, b) => a > b ? a : b);
    final min = data.reduce((a, b) => a < b ? a : b);
    final range = (max - min) == 0 ? 1 : (max - min);

    final path = Path();
    final area = Path();

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - min) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
        area.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        area.lineTo(x, y);
      }
    }

    // close area path
    area.lineTo(size.width, size.height);
    area.lineTo(0, size.height);
    area.close();

    // draw area and line
    canvas.drawPath(area, bg);
    canvas.drawPath(path, paint);

    // optional dots
    final dotPaint = Paint()..color = Colors.blue;
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - min) / range) * size.height;
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
