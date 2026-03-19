import 'package:flutter/material.dart';

// --- Main AI Insights Screen ---

class AiScreenPage extends StatelessWidget {
  const AiScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Logo and Title
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            floating: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
              onPressed: () => Navigator.of(context).pop(),
            ),
            centerTitle: true,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Snowflake/Circuit Icon (Placeholder for the AI/Cold Chain Logo)
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.blue.shade700, Colors.lightBlueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Icon(Icons.psychology_outlined, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI Insights / Analytics',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),

          SliverList(
            delegate: SliverChildListDelegate(
              [
                const SizedBox(height: 16),

                // 1. PREDICTED SPOILAGE RISK CARD
                _InsightCard(
                  title: 'Predicted Spoilage Risk (Next Week)',
                  alertValue: '15%',
                  status: 'Online',
                  isOnline: true,
                  chartType: _ChartType.riskPrediction,
                ),

                // 2. HISTORICAL TEMPERATURE ANOMALIES CARD
                _InsightCard(
                  title: 'Historical Temperature Anomalies (Past Month)',
                  alertValue: '9.8°C',
                  status: 'Online',
                  isOnline: true,
                  chartType: _ChartType.historicalAnomaly,
                ),

                // 3. AI RECOMMENDATIONS SECTION
                const Padding(
                  padding: EdgeInsets.only(top: 16.0, left: 24.0, bottom: 8.0),
                  child: Text(
                    'AI Recommendations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const _RecommendationList(),

                const SizedBox(height: 32),

                // 4. DOWNLOAD REPORT BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Action for downloading the report
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
                      icon: const Icon(Icons.download, color: Colors.white),
                      label: const Text(
                        'Download Report (PDF Summary)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Sub-Widgets for AI Insights ---

enum _ChartType { riskPrediction, historicalAnomaly }

class _InsightCard extends StatelessWidget {
  final String title;
  final String alertValue;
  final String status;
  final bool isOnline;
  final _ChartType chartType;

  const _InsightCard({
    required this.title,
    required this.alertValue,
    required this.status,
    required this.isOnline,
    required this.chartType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              // Alert Value and Status
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    alertValue,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.offline_bolt_outlined,
                    size: 18,
                    color: isOnline ? Colors.green.shade500 : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    status,
                    style: TextStyle(
                      color: isOnline ? Colors.green.shade500 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Chart Placeholder
          _ChartPlaceholder(chartType: chartType),
        ],
      ),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  final _ChartType chartType;

  const _ChartPlaceholder({required this.chartType});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.only(top: 8.0, right: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Y-Axis Labels
          _buildYAxisLabels(),
          const SizedBox(width: 8),
          // Chart Area (Custom Painter)
          Expanded(
            child: CustomPaint(
              painter: _LineChartPainter(chartType: chartType),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYAxisLabels() {
    // Labels based on the image (Y-axis numbers are 100, 80, 60... for Risk, and 90, 50, 10 for Anomalies)
    List<String> labels;
    if (chartType == _ChartType.riskPrediction) {
      labels = const ['100', '80', '60', '40', '20', '0'];
    } else {
      labels = const ['90', '70', '50', '30', '10'];
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: labels
          .map((label) => Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ))
          .toList(),
    );
  }
}

// Custom Painter to draw the lines and dots mimicking the graph
class _LineChartPainter extends CustomPainter {
  final _ChartType chartType;

  _LineChartPainter({required this.chartType});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.red.shade400
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()..color = Colors.red.shade600;

    // Mock data points (normalized to 0.0 to 1.0 for the chart height)
    final List<double> yData;
    if (chartType == _ChartType.riskPrediction) {
      // Data mimicking the 'Predicted Spoilage Risk' chart (rising then stable/falling)
      yData = const [0.6, 0.45, 0.55, 0.7, 0.65, 0.58, 0.4];
    } else {
      // Data mimicking the 'Historical Anomaly' chart (more volatile)
      yData = const [0.4, 0.5, 0.35, 0.6, 0.45, 0.75, 0.2, 0.8, 0.65];
    }

    final path = Path();
    for (int i = 0; i < yData.length; i++) {
      final x = i / (yData.length - 1) * size.width;
      final y = size.height * (1.0 - yData[i]); // Invert Y for drawing

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      // Draw dots
      canvas.drawCircle(Offset(x, y), 3.0, dotPaint);
    }

    canvas.drawPath(path, linePaint);

    // Draw X-Axis labels
    final List<String> xLabels = chartType == _ChartType.riskPrediction
        ? const ['11', '23', '03', '15', '48', '13', '15'] // Mocked Week/Day labels
        : const ['10', '12', '20', '28', '30', '13', '15', '12', '10']; // Mocked Day/Hour labels

    final textStyle = TextStyle(fontSize: 10, color: Colors.grey.shade500);

    for (int i = 0; i < xLabels.length; i++) {
      final textPainter = TextPainter(
        text: TextSpan(text: xLabels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final x = i / (xLabels.length - 1) * size.width - textPainter.width / 2;
      textPainter.paint(canvas, Offset(x.clamp(0.0, size.width - textPainter.width), size.height + 4));
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) => false;
}

class _RecommendationList extends StatelessWidget {
  const _RecommendationList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildRecommendationItem(
              context,
              number: 1,
              text: 'Suggested Routes: Optimize for cooler transit (2PM - 4PM )',
              isUrgent: true,
              icon: Icons.route,
            ),
            _buildRecommendationItem(
              context,
              number: 2,
              text: 'Maintenance: Check Fridge Alpha 123 due Nov 15',
              isUrgent: false,
              icon: Icons.build,
            ),
            _buildRecommendationItem(
              context,
              number: 3,
              text: 'Shipment Timing: Depart after 8PM (Avoid hottest hours)',
              isUrgent: false,
              icon: Icons.schedule,
            ),
            _buildRecommendationItem(
              context,
              number: 4,
              text: 'Upload New Datasets (AI Retraining)',
              isUrgent: false,
              icon: Icons.upload_file,
              isSpecial: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(
    BuildContext context, {
    required int number,
    required String text,
    required bool isUrgent,
    required IconData icon,
    bool isSpecial = false,
  }) {
    final numberColor = isUrgent ? Colors.red.shade600 : Colors.blue.shade600;
    final iconColor = isSpecial ? Colors.blue.shade600 : Colors.grey.shade600;
    
    // FIX: Define mainText as a Widget explicitly.
    // If isSpecial is true, the layout uses a Row below, so we don't need mainText here.
    // If isSpecial is false, mainText is the simple Text widget that goes into the Column.
    final Widget mainTextWidget = Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: isSpecial ? iconColor : Colors.black87,
      )
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: isSpecial ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          // Number Circle (1, 2, 3...)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: numberColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Text Content
          Expanded(
            child: isSpecial
                ? Row(
                    children: [
                      Icon(Icons.upload_file, color: iconColor, size: 20),
                      const SizedBox(width: 8),
                      // Use the defined widget for the special case text
                      mainTextWidget,
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Use the defined widget for the normal case text
                      mainTextWidget,
                      // The magnifying glass icon is placed next to the first recommendation in the image
                      if (isUrgent)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Icon(Icons.search, color: Colors.blue.shade400, size: 18),
                        ),
                    ],
                  ),
          ),
          // Clock/Calendar Icon for item 3
          if (number == 3) Icon(Icons.wb_sunny_outlined, color: Colors.orange.shade700, size: 20),
        ],
      ),
    );
  }
}
