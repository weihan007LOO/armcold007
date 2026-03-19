import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


// --- Data Models (Internal to this file for simplicity) ---
double latestTemperature = 0.0;
int latestHumidity = 0;
  Future<void> fetchLatestSensorData() async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('sensor_readings')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final data = querySnapshot.docs.first.data();
      latestTemperature = (data['temperature'] ?? 0).toDouble();
      latestHumidity = (data['humidity'] ?? 0).toInt();
      print('✅ Latest from Firebase: $latestTemperature°C, $latestHumidity%');
    }
  } catch (e) {
    print('❌ Error fetching Firebase data: $e');
  }
}


enum Status { safe, warning, critical }


class DetailData {
  final String shipmentId;
  final String currentTemp;
  final String humidity;
  final String powerStatus; // On Grid, On Battery, Offline
  final Status riskStatus;
  final String predictedExcursionTime;
  final String aiInsight;
  final String recommendation;
  final List<Event> recentEvents;


  const DetailData({
    required this.shipmentId,
    this.currentTemp = '5.2°C',
    this.humidity = '52%',
    this.powerStatus = 'On Grid',
    this.riskStatus = Status.safe,
    this.predictedExcursionTime = '~ 5 hours',
    this.aiInsight = 'Low (3%)',
    this.recommendation = 'Increase insulation or reduce door openings',
    required this.recentEvents,
  });
}


class Event {
  final String description;
  final String timestamp;
  final Status severity;


  const Event({
    required this.description,
    required this.timestamp,
    required this.severity,
  });
}


// --- Mock Data ---


final mockDetailData = DetailData(
  shipmentId: 'VAX-008', // Assuming VAX-008 was tapped
  recentEvents: const [
    Event(
        description: 'Door opened',
        timestamp: '10:22 AM',
        severity: Status.warning),
    Event(
        description: 'Power outage detected',
        timestamp: '10:05 AM',
        severity: Status.critical),
    Event(
        description: 'Temp exceeded threshold',
        timestamp: '9:55 AM',
        severity: Status.critical),
  ],
);


// --- Component Builders ---


// Helper function to get status color
Color _getStatusColor(Status status) {
  switch (status) {
    case Status.safe:
      return const Color(0xFF4CD964); // Green
    case Status.warning:
      return const Color(0xFFFF9500); // Orange
    case Status.critical:
      return const Color(0xFFCC0000); // Red
  }
}


// Custom Card for Reusability
class DetailCard extends StatelessWidget {
  final Widget child;
  const DetailCard({required this.child, super.key});


  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}


// --- Main Screen ---


class ShipmentDetailScreen extends StatelessWidget {
  static const routeName = '/shipment_detail';


  const ShipmentDetailScreen({super.key});


  @override
  Widget build(BuildContext context) {
    // 1. Get the shipment ID passed from the previous screen (ShipmentsFridgesScreen)
    final shipmentId = ModalRoute.of(context)?.settings.arguments as String? ?? 'N/A';
   
    // We will use the mock data for now, regardless of the passed ID
    final data = mockDetailData;


    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Shipment ID: $shipmentId'),
        backgroundColor: const Color(0xFF007AFF), // ARMCOLD Blue
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // --- 1. Header/Status Block ---
            _buildHeaderStatus(data),


            // --- 2. Temperature Chart Card ---
            _buildChartCard(context, data),


            // --- 3. AI Insights Card ---
            _buildAiInsightsCard(data),


            // --- 4. Recent Events Log Card ---
            _buildRecentEventsLog(data),
          ],
        ),
      ),
      // --- 5. Sticky Footer/Action Bar ---
      bottomNavigationBar: _buildBottomActionBar(context),
    );
  }


  Widget _buildHeaderStatus(DetailData data) {
    final statusColor = _getStatusColor(data.riskStatus);
    final statusText = data.riskStatus == Status.safe ? 'Stable' : 'Alert';


    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '${latestTemperature.toStringAsFixed(1)}°C',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFCC0000), // Red for temp
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Drop Icon (Humidity)
                  Column(
                    children: [
                      const Icon(Icons.opacity, size: 18, color: Color(0xFF007AFF)),
                      Text('${latestHumidity.toString()}%', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(width: 10),
                  // Status Text
                  Chip(
                    label: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: statusColor.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ],
              ),
              // Online Status
              Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 18, color: statusColor),
                  const SizedBox(width: 4),
                  Text(data.powerStatus, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Predicted time to excursion: ${data.predictedExcursionTime}',
            style: const TextStyle(fontSize: 14, color: Colors.red),
          ),
        ],
      ),
    );
  }


  Widget _buildChartCard(BuildContext context, DetailData data) {
    // --- Mock Chart Widget (Simplified Placeholder) ---
    // The complex chart from the design is simplified to a colored container.
    return DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Temperature (°C) Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            // Placeholder for the Line Chart with Critical Threshold Zone
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Mock Green/Red Area
                Row(
                  children: [
                    Expanded(
                      flex: 60,
                      child: Container(color: const Color(0xFFE6FFE6)), // Safe Zone (Light Green)
                    ),
                    Expanded(
                      flex: 40,
                      child: Container(color: const Color(0xFFFFE6E6)), // Critical Zone (Light Red)
                    ),
                  ],
                ),
                // Text Overlay
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Text(
                      'Critical Threshold Zone',
                      style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Center(
                  child: Text('LINE CHART PLACEHOLDER',
                      style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildAiInsightsCard(DetailData data) {
    final riskColor = data.riskStatus == Status.safe ? _getStatusColor(Status.safe) : _getStatusColor(Status.warning);


    return DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Spoilage Risk:', style: TextStyle(fontSize: 16)),
              Text(
                '${data.aiInsight}',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: riskColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Recommendation:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(
            data.recommendation,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }


  Widget _buildRecentEventsLog(DetailData data) {
    return DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Events Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          ...data.recentEvents.map((event) {
            final color = _getStatusColor(event.severity);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning, size: 20, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${event.description} - ${event.timestamp}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          event.severity == Status.critical ? 'Critical' : 'Warning',
                          style: TextStyle(fontSize: 12, color: color),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
          // Acknowledge Alert Button
          Center(
            child: ElevatedButton(
              onPressed: () {
                // Logic to acknowledge alert
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text('Acknowledge Alert', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBottomActionBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton('Details', Icons.info_outline, (){} ),
          _buildActionButton('Add Note / Observation', Icons.note_add_outlined, () {}),
          _buildActionButton('Share Report', Icons.share, () {}),
        ],
      ),
    );
  }


  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8), // optional: makes tap ripple rounder
    splashColor: Colors.blue.withOpacity(0.2), // optional: nice ripple effect
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF007AFF)),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF007AFF),
            ),
          ),
        ],
      ),
    ),
  );
}
}



