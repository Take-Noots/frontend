import 'package:flutter/material.dart';
import '../../../../../data/services/analytics_service.dart';

class BusinessAdInsightsTab extends StatefulWidget {
  final String userId;

  const BusinessAdInsightsTab({Key? key, required this.userId})
      : super(key: key);

  @override
  State<BusinessAdInsightsTab> createState() => _BusinessAdInsightsTabState();
}

class _BusinessAdInsightsTabState extends State<BusinessAdInsightsTab> {
  final AnalyticsService _analyticsService = AnalyticsService();
  String _selectedRange = 'Last 30 days';
  bool _isLoading = true;
  String? _error;

  final List<String> _ranges = [
    'Last 7 days',
    'Last 30 days',
    '3 months',
    '6 months',
    'Last year',
    'All time',
  ];

  // Real data from backend
  List<double> _chartData = [10, 22, 18, 30, 25, 28, 35, 40, 38, 45];
  Map<String, dynamic> _userMetrics = {};
  Map<String, dynamic> _contentMetrics = {};
  Map<String, dynamic> _growthMetrics = {};

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all analytics data in parallel
      final results = await Future.wait([
        _analyticsService.getUserMetrics(),
        _analyticsService.getContentMetrics(),
        _analyticsService.getGrowthMetrics(_getPeriodKey()),
      ]);

      final userResult = results[0];
      final contentResult = results[1];
      final growthResult = results[2];

      if (userResult['success'] && contentResult['success'] && growthResult['success']) {
        setState(() {
          _userMetrics = userResult['data'];
          _contentMetrics = contentResult['data'];
          _growthMetrics = growthResult['data'];
          _chartData = _analyticsService.parseGrowthDataForChart(_growthMetrics, 'posts');
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load analytics data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading analytics: $e';
        _isLoading = false;
      });
    }
  }

  String _getPeriodKey() {
    switch (_selectedRange) {
      case 'Last 7 days': return '7d';
      case 'Last 30 days': return '30d';
      case '3 months': return '90d';
      case '6 months': return '180d';
      case 'Last year': return '365d';
      case 'All time': return 'all';
      default: return '30d';
    }
  }

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
                  'Analytics Dashboard',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: _isLoading ? Colors.grey : Colors.blue,
                      ),
                      onPressed: _isLoading ? null : _loadAnalyticsData,
                      tooltip: 'Refresh Data',
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
                        });
                        _loadAnalyticsData(); // Reload data when range changes
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 32),
                      SizedBox(height: 8),
                      Text(_error!, style: TextStyle(color: Colors.red)),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadAnalyticsData,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Row(
                children: <Widget>[
                  Expanded(child: _metricCard(
                    'Total Users',
                    _formatNumber(_userMetrics['total'] ?? 0),
                    Colors.purple
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _metricCard(
                    'Total Posts',
                    _formatNumber(_contentMetrics['total'] ?? 0),
                    Colors.orange
                  )),
                ],
              ),

              const SizedBox(height: 8),
              _metricCard(
                'Active Users',
                _formatNumber(_userMetrics['active'] ?? 0),
                Colors.teal
              ),
            ],

            const SizedBox(height: 16),

            if (!_isLoading && _error == null) ...[
              const Text('Platform Growth over time', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  leading: const Icon(Icons.analytics_outlined),
                  title: const Text('Platform Insights'),
                  subtitle: Text(
                    'Total Content: ${_formatNumber(_contentMetrics['total'] ?? 0)} posts • '
                    'Moderators: ${_userMetrics['moderators'] ?? 0}'
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.trending_up_outlined),
                  title: const Text('Growth Summary'),
                  subtitle: Text(
                    'Period: $_selectedRange • '
                    'Popular Posts: ${_contentMetrics['popular'] ?? 0}'
                  ),
                ),
              ),
            ],
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

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
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

    if (data.isEmpty || size.width <= 0 || size.height <= 0) {
      // Draw "No data" text
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'No data available',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2,
        ),
      );
      return;
    }

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
