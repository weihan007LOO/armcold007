import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Data Model for Shipments/Fridges ---
double latestTemperature = 0.0;
int latestHumidity = 0;
String latestAddress = '--';
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
      latestAddress = (data['location'] ?? '--').toString();
      print('✅ Latest from Firebase: $latestTemperature°C, $latestHumidity%, $latestAddress');
    }
  } catch (e) {
    print('❌ Error fetching Firebase data: $e');
  }
}
enum ShipmentStatus { safe, alert, critical }

class ShipmentItem {
  final String id;
  final ShipmentStatus status;
  final String deviceType;
  final double temp;
  final int humidity;
  final String location;
  final String syncStatus;
  final bool isOnBattery;

  const ShipmentItem({
    required this.id,
    required this.status,
    required this.deviceType,
    required this.temp,
    required this.humidity,
    required this.location,
    required this.syncStatus,
    this.isOnBattery = false,
  });
}

// --- ShipmentsFridgesScreen Widget ---

class ShipmentsFridgesScreen extends StatefulWidget {
  const ShipmentsFridgesScreen({super.key});

  @override
  State<ShipmentsFridgesScreen> createState() => _ShipmentsFridgesScreenState();
}

class _ShipmentsFridgesScreenState extends State<ShipmentsFridgesScreen> {
  String _selectedTab = 'Active';
  bool _isMapView = false;  

  List<ShipmentItem> activeShipments = [
    ShipmentItem(
      id: 'VAX-008',
      status: ShipmentStatus.safe,
      deviceType: 'Safe',
      temp: latestTemperature,
      humidity: latestHumidity,
      location: latestAddress,
      syncStatus: 'Online',
    ),
    ShipmentItem(
      id: 'FRDGE-ALPHA',
      status: ShipmentStatus.alert,
      deviceType: 'Warning',
      temp: 9.1,
      humidity: 75,
      location: 'Rural Clinic A',
      syncStatus: 'On Battery',
      isOnBattery: true,
    ),
    ShipmentItem(
      id: 'VAX-007',
      status: ShipmentStatus.critical,
      deviceType: 'Humidity Alert',
      temp: 15.0,
      humidity: 90,
      location: 'Unknown / Last Sync: 2h ago',
      syncStatus: 'Offline',
    ),
  ];
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Shipments / Fridges',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.more_vert, color: Colors.black87),
          )
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTabBar(),
          Expanded(
            child: _isMapView ? _buildMapView() : _buildShipmentList(),
          ),
          _buildMapToggle(),
        ],
      ),
    );
  }

  // --- UI Components ---

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search shipment ID or location',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['Active', 'Completed', 'In Storage'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: tabs.map((tab) {
            final isSelected = _selectedTab == tab;
            return GestureDetector(
              onTap: () => setState(() => _selectedTab = tab),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? Colors.indigo.shade700 : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.indigo.shade700 : Colors.grey.shade600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildShipmentList() {
    if (_selectedTab != 'Active') {
      return Center(
        child: Text('No $_selectedTab Shipments.', style: TextStyle(color: Colors.grey.shade500)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: activeShipments.length,
      itemBuilder: (context, index) {
        return _ShipmentCard(item: activeShipments[index]);
      },
    );
  }

  Widget _buildMapView() {
    // Placeholder for a Map View, as mapping is outside the scope of simple Flutter UI
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.map_outlined,
            size: 80,
            color: Colors.indigo,
          ),
          const SizedBox(height: 10),
          Text(
            'Map View Toggled',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'The map would be displayed here, showing locations.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMapToggle() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Toggle Map View',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
          ),
          Switch(
            value: _isMapView,
            onChanged: (value) {
              setState(() {
                _isMapView = value;
              });
            },
            activeColor: Colors.indigo.shade700,
          ),
        ],
      ),
    );
  }
}

// --- Custom Shipment Card Widget ---

class _ShipmentCard extends StatelessWidget {
  final ShipmentItem item;

  const _ShipmentCard({required this.item});

  // Navigation Function to the Detail Screen
  void _navigateToDetail(BuildContext context) {
    // We use the named route we registered in main.dart: '/shipment_detail'
    // The second argument is the data we pass to the next screen (the shipment ID).
    Navigator.pushNamed(
      context,
      '/shipment_detail1',
      arguments: item.id,
    );
  }

  Color _getCardColor(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.safe:
        return Colors.green.shade50; // Light green background
      case ShipmentStatus.alert:
        return Colors.amber.shade50; // Light amber background
      case ShipmentStatus.critical:
        return Colors.red.shade50; // Light red background
    }
  }

  Color _getPrimaryColor(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.safe:
        return Colors.green.shade600;
      case ShipmentStatus.alert:
        return Colors.amber.shade700;
      case ShipmentStatus.critical:
        return Colors.red.shade700;
    }
  }

  IconData _getStatusIcon(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.safe:
        return Icons.check_circle;
      case ShipmentStatus.alert:
        return Icons.warning_rounded;
      case ShipmentStatus.critical:
        return Icons.flash_on; // Represents critical alert/power issue
    }
  }

  Widget _buildSyncStatus() {
    IconData icon;
    Color color;

    if (item.isOnBattery) {
      icon = Icons.battery_charging_full;
      color = Colors.amber.shade700;
    } else if (item.syncStatus == 'Online') {
      icon = Icons.online_prediction;
      color = Colors.green.shade600;
    } else {
      icon = Icons.flash_off;
      color = Colors.red.shade700;
    }

    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          item.syncStatus,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getPrimaryColor(item.status);
    final cardColor = _getCardColor(item.status);

    return InkWell( // 1. Make the whole card tappable
      onTap: () => _navigateToDetail(context), // 1. Primary navigation logic here
      child: Card(
        color: cardColor,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: primaryColor.withOpacity(0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Shipment ID, Status Icon, and Connection Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(_getStatusIcon(item.status), size: 18, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Shipment ID: ${item.id}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  _buildSyncStatus(),
                ],
              ),
              const Divider(height: 20, thickness: 1, color: Colors.white),

              // Row 2: Status Text and View Details Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.deviceType,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Temp: ${item.temp}°C, Humidity ${item.humidity}%',
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Location: ${item.location}',
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _navigateToDetail(context), // 2. Also navigate when the button is pressed
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      backgroundColor: Colors.indigo.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'View Details',
                      style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}