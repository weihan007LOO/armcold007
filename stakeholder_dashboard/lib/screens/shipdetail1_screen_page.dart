import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Reusing Data Models (Consistency is Key!) ---
double latestTemperature = 0.0;
int latestHumidity = 0;
String latestAddress = '--';
String latestLat = '--';
String latestLong = '--';

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
      latestAddress = (data['location' ?? '--']).toString();
      latestLat = (data['latitude' ?? '--']).toString();
      latestLong = (data['longitude' ?? '--']).toString();
      print('✅ Latest from Firebase: $latestTemperature°C, $latestHumidity%');
    }
  } catch (e) {
    print('❌ Error fetching Firebase data: $e');
  }
}
enum ShipmentStatus { safe, alert, critical }

// Data structure to hold all necessary mock data for the hybrid detail screen
class ShipmentDetailData {
  final String shipmentId;
  final String topAlertMessage;
  final ShipmentStatus shipmentOverallStatus;
  final double shipmentCurrentTemp;
  final int shipmentHumidity;
  final int shipmentBattery;
  final String shipmentLocation;
  final String shipmentSyncStatus;
  final double shipmentMaxTempAlert;

  final ShipmentStatus realTimeOverallStatus;
  final double realTimeCurrentTemp;
  final int realTimeHumidity;
  final int realTimeBattery;
  final String realTimeLocation;
  final String realTimeSyncStatus;
  final double realTimeMaxTempAlert;

  const ShipmentDetailData({
    required this.shipmentId,
    this.topAlertMessage = 'Critical temperature excursion detected in Shipment ID: VAX-008',
    this.shipmentOverallStatus = ShipmentStatus.safe,
    this.shipmentCurrentTemp = 3.5,
    this.shipmentHumidity = 45,
    this.shipmentBattery = 45,
    this.shipmentLocation = 'New Delhi, India',
    this.shipmentSyncStatus = 'Online',
    this.shipmentMaxTempAlert = 70.0, // Used for the secondary metric in the card

    this.realTimeOverallStatus = ShipmentStatus.critical,
    this.realTimeCurrentTemp = 9.2, // Value from the image
    this.realTimeHumidity = 80, // Value from the image
    this.realTimeBattery = 70, // Value from the image
    this.realTimeLocation = 'Petaling Jaya, Malaysia',
    this.realTimeSyncStatus = 'Online',
    this.realTimeMaxTempAlert = 7.9, // Used for the secondary metric in the card
  });
}

// --- Mock Data Service ---

ShipmentDetailData getMockShipmentDetail(String id) {
  // Always return the data matching the new image for VAX-007
  return const ShipmentDetailData(shipmentId: 'VAX-007');
}


class ShipmentDetailScreen1 extends StatelessWidget {
  const ShipmentDetailScreen1({super.key});

  // Helper function to get status colors
  Color _getMetricColor(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.safe:
        return Colors.green.shade600;
      case ShipmentStatus.alert:
        return Colors.amber.shade700;
      case ShipmentStatus.critical:
        return Colors.red.shade700;
    }
  }

  // Helper function to get status icons
  IconData _getMetricIcon(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.safe:
        return Icons.check_circle_outline;
      case ShipmentStatus.alert:
        return Icons.warning_amber_rounded;
      case ShipmentStatus.critical:
        return Icons.bolt;
    }
  }

  @override
  Widget build(BuildContext context) {
    //final String? shipmentId = ModalRoute.of(context)?.settings.arguments as String?;

    

    final shipmentData = getMockShipmentDetail('VAX-008');

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // 1. TOP CRITICAL ALERT BAR
          _buildCriticalAlertBanner(context, shipmentData.topAlertMessage),
          Expanded(
            child: CustomScrollView(
              slivers: [
                // 2. APP BAR (only back button, no title in the visible area)
                _buildAppBar(context),
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      // 3. DASHBOARD TITLE
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0, left: 24.0, bottom: 8.0),
                        child: Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      // 4. SHIPMENT CARD
                      _MetricCard(
                        title: 'Shipment',
                        currentTemp: latestTemperature,
                        humidity: latestHumidity,
                        battery: shipmentData.shipmentBattery,
                        secondaryTemp: shipmentData.shipmentMaxTempAlert,
                        location: '$latestAddress (Lat:$latestLat, Long: $latestLong)',
                        isOnline: shipmentData.shipmentSyncStatus == 'Online',
                        status: shipmentData.shipmentOverallStatus,
                        getMetricColor: _getMetricColor,
                        getMetricIcon: _getMetricIcon,
                      ),
                      // 5. REAL-TIME STATUS CARD
                      _MetricCard(
                        title: 'Real-time status',
                        currentTemp: shipmentData.realTimeCurrentTemp,
                        humidity: shipmentData.realTimeHumidity,
                        battery: shipmentData.realTimeBattery,
                        secondaryTemp: shipmentData.realTimeMaxTempAlert,
                        location: shipmentData.realTimeLocation,
                        isOnline: shipmentData.realTimeSyncStatus == 'Online',
                        status: shipmentData.realTimeOverallStatus,
                        getMetricColor: _getMetricColor,
                        getMetricIcon: _getMetricIcon,
                      ),
                      // 6. LIVE MAP VIEW
                      _buildLiveMapView(context),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 7. BOTTOM ACTION BAR
          _buildBottomActions(context),
        ],
      ),
    );
  }

  // --- Widget Builders ---

  SliverAppBar _buildAppBar(BuildContext context) {
  return SliverAppBar(
    backgroundColor: const Color(0xFF007AFF),
    elevation: 0,
    floating: true,
    snap: true,
    centerTitle: true, // 👈 this ensures the title is centered
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
      onPressed: () => Navigator.of(context).pop(),
    ),
    title: const Text(
      'Shipment ID: VAX-008', // 👈 your title text here
      style: TextStyle(
        color: Colors.white, // make it visible against the blue background
        fontSize: 20,
        //fontWeight: FontWeight.bold,
      ),
    ),
  );
}

  Widget _buildCriticalAlertBanner(BuildContext context, String message) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 8, left: 16, right: 16),
      color: Colors.red.shade700,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMapView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live Map View',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
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
                // Map Placeholder (Image.asset as requested)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey.shade200, // Background color for map area
                    child: InkWell
                    (
                      onTap:()
                      {Navigator.pushNamed(context, '/map_tracking');},
                      child: Image.asset(
                      'assets/images/MAP.PNG', // Placeholder file path
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          // Fallback when asset is not found (common in dev environment)
                          Container(
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Text(
                            'Map Placeholder\n(assets/map_placeholder.png)',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ),
                    ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Map Toggle and AI Prediction Label
                Row(
                  children: [
                    const Text(
                      'Shipments in Transit',
                      style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: true,
                      onChanged: (bool value) {},
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ActionButton(
            label: 'Details',
            icon: Icons.info_outline,
            onTap: () {Navigator.pushNamed(context, '/shipment_detail',arguments: 'VAX-008',);},
            isActive: true,
          ),
          _ActionButton(
            label: 'Add Note / Observation',
            icon: Icons.note_add_outlined,
            onTap: () {},
            isActive: false,
          ),
          _ActionButton(
            label: 'Share Report',
            icon: Icons.share_outlined,
            onTap: () {},
            isActive: false,
          ),
        ],
      ),
    );
  }
}

// --- Sub-Widgets ---

class _MetricCard extends StatelessWidget {
  final String title;
  final double currentTemp;
  final int humidity;
  final int battery;
  final double secondaryTemp;
  final String location;
  final bool isOnline;
  final ShipmentStatus status;
  final Color Function(ShipmentStatus) getMetricColor;
  final IconData Function(ShipmentStatus) getMetricIcon;

  const _MetricCard({
    required this.title,
    required this.currentTemp,
    required this.humidity,
    required this.battery,
    required this.secondaryTemp,
    required this.location,
    required this.isOnline,
    required this.status,
    required this.getMetricColor,
    required this.getMetricIcon,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = getMetricColor(status);
    final statusIcon = getMetricIcon(status);

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
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT: Main Metric (Temperature)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${currentTemp.toStringAsFixed(1)}°C',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(statusIcon, color: statusColor, size: 28),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Sub Metrics (Humidity/Battery/Check)
                  Row(
                    children: [
                      Icon(Icons.opacity, size: 18, color: Colors.blue.shade400),
                      const SizedBox(width: 4),
                      Text('$humidity%', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(width: 16),
                      Icon(Icons.battery_std, size: 18, color: Colors.green.shade400),
                      const SizedBox(width: 4),
                      Text('$battery%', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(width: 16),
                      const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              // RIGHT: Secondary Metric (e.g., Max Temp Alert)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 20, color: Colors.amber.shade700),
                      const SizedBox(width: 4),
                      Text(
                        '${secondaryTemp.toStringAsFixed(1)}°C',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.bolt, size: 18, color: Colors.green.shade500),
                      const SizedBox(width: 4),
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 30, color: Color(0xFFEEEEEE)),
          // Bottom Info Row
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                'GPS: $location',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.blue.shade700 : Colors.grey.shade700;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
