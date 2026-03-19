import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// --- Data Model for Combined Check-in Record ---
class CheckinRecord {
  final String documentId;
  final String shipmentId;
  final String actionType;
  final String issueDescription;
  final DateTime timestamp;
  
  // Dynamic Sensor and Location data (from sensor_readings closest to check-in time)
  final double latitude;
  final double longitude;
  final String address;
  final double temperature;
  final double humidity;

  CheckinRecord({
    required this.documentId,
    required this.shipmentId,
    required this.actionType,
    required this.issueDescription,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.temperature,
    required this.humidity,
  });
}

class CheckinScreenPage extends StatelessWidget {
  const CheckinScreenPage({super.key});

  double _getSafeDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      // Use tryParse to safely convert string data to double
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
  // Function to find the single latest sensor reading recorded BEFORE the check-in time.
  Future<Map<String, dynamic>> _getSensorDataForTime(DateTime checkinTime) async {
    final CollectionReference sensorReadings = 
        FirebaseFirestore.instance.collection('sensor_readings');
    
    // Query: Find the latest reading (descending) where the sensor's timestamp 
    // is BEFORE (or equal to) the driver's check-in timestamp.
    final QuerySnapshot snapshot = await sensorReadings
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(checkinTime))
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      
      return {
        'latitude': _getSafeDouble(data['latitude']),
      'longitude': _getSafeDouble(data['longitude']),
      'temperature': _getSafeDouble(data['temperature']),
      'humidity': _getSafeDouble(data['humidity']),
      'address': data['location'] as String? ?? 'N/A Location',
      };
    } else {
      // Return default values if no sensor data was found BEFORE this check-in
      return {
        'latitude': 0.0,
        'longitude': 0.0,
        'temperature': 0.0,
        'humidity': 0.0,
        'address': 'N/A (Historical Sensor data missing)',
      };
    }
  }

  // Maps Firestore DocumentSnapshot to the combined CheckinRecord model (now asynchronous)
  Future<CheckinRecord> _mapSnapshotToRecord(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final Timestamp timestamp = data['timestamp'] as Timestamp;
    final DateTime checkinTime = timestamp.toDate();

    // Fetch the corresponding, historically accurate sensor data asynchronously
    final sensorData = await _getSensorDataForTime(checkinTime);

    return CheckinRecord(
      documentId: doc.id,
      shipmentId: data['shipmentId'] as String? ?? 'N/A',
      actionType: data['actionType'] as String? ?? 'N/A',
      issueDescription: data['issueDescription'] as String? ?? '',
      timestamp: checkinTime,
      
      // Map dynamic sensor data from the lookup
      latitude: sensorData['latitude'] as double,
      longitude: sensorData['longitude'] as double,
      temperature: sensorData['temperature'] as double,
      humidity: sensorData['humidity'] as double,
      address: sensorData['address'] as String,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Check-in History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      // StreamBuilder listens to the driver's check-in actions
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('shipment_checkin')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Error/No Data checks remain...
          if (snapshot.hasError) {
            return Center(child: Text('Error loading check-ins: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No check-in records found.'));
          }

          final checkinDocs = snapshot.data!.docs;
          
          // Use FutureBuilder.builder to process each check-in asynchronously
          // Future.wait ensures all necessary sensor lookups are done before rendering the list.
          return FutureBuilder<List<CheckinRecord>>(
            future: Future.wait(checkinDocs.map(_mapSnapshotToRecord)),
            builder: (context, futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (futureSnapshot.hasError) {
                // Handle the case where a sensor lookup failed
                return Center(child: Text('Error processing check-in details: ${futureSnapshot.error}'));
              }
              
              final records = futureSnapshot.data ?? [];

              return ListView.builder(
                padding: const EdgeInsets.all(12.0),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  return _CheckinCard(record: records[index]);
                },
              );
            },
          );
        },
      ),
    );
  }
}

// --- Individual Check-in Card Widget (Remains the same for display) ---
class _CheckinCard extends StatelessWidget {
  final CheckinRecord record;

  const _CheckinCard({required this.record});

  Widget _buildDetailRow({
    required IconData icon, 
    required String label, 
    required String value, 
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine card color based on action type
    final Color cardColor = record.actionType == 'issue' ? Colors.red.shade50 : Colors.blue.shade50;
    final Color textColor = record.actionType == 'issue' ? Colors.red.shade800 : Colors.blue.shade800;

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: textColor.withOpacity(0.3), width: 1.5)
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (Shipment ID and Type)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Shipment ID: ${record.shipmentId}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    record.actionType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 15, thickness: 1),
            
            // Time and Date
            _buildDetailRow(
              icon: Icons.access_time, 
              label: 'Time:', 
              value: DateFormat.yMMMd().add_jm().format(record.timestamp)
            ),
            
            // Temperature and Humidity 
            _buildDetailRow(
              icon: Icons.thermostat_outlined, 
              label: 'Temp/Hum:', 
              value: '${record.temperature.toStringAsFixed(1)}°C / ${record.humidity.toStringAsFixed(1)}%'
            ),

            // Location Coordinates
            _buildDetailRow(
              icon: Icons.location_on_outlined, 
              label: 'Coord:', 
              value: '${record.latitude.toStringAsFixed(4)}, ${record.longitude.toStringAsFixed(4)}'
            ),
            
            // Address 
             _buildDetailRow(
              icon: Icons.map, 
              label: 'Address:', 
              value: record.address,
              maxLines: 2,
            ),

            // Issue Description (if applicable)
            if (record.actionType == 'issue' && record.issueDescription.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Issue Details: ${record.issueDescription}',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}