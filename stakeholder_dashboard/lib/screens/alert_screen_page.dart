import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Data Model for Alerts ---

enum AlertSeverity { critical, warning, resolved }

class Alert {
  final String documentId;
  final String title;
  final String details;
  final AlertSeverity severity;
  final String timeAgo;
  final IconData icon;
  final bool isAcknowledged;

  Alert({
    required this.documentId,
    required this.title,
    required this.details,
    required this.severity,
    required this.timeAgo,
    required this.icon,
    this.isAcknowledged = false,
  });
}

// --- Main Alert Screen Widget ---

class AlertScreenPage extends StatefulWidget {
  const AlertScreenPage({super.key});

  @override
  State<AlertScreenPage> createState() => _AlertScreenPageState();
}

class _AlertScreenPageState extends State<AlertScreenPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _activeCount = 0;
  int _resolvedCount = 0;
  
  List<Alert> _allAlerts = [];
  final CollectionReference _shipmentActions = FirebaseFirestore.instance.collection('shipment_actions');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _calculateCounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper to determine severity based on the reported issue type
  AlertSeverity _getSeverityFromIssue(String issueDescription) {
    if (issueDescription.contains('Violation') || issueDescription.contains('Damage') || issueDescription.contains('Power')) {
      return AlertSeverity.critical;
    }
    if (issueDescription.contains('Delay') || issueDescription.contains('Malfunction') || issueDescription.contains('Humidity')) {
      return AlertSeverity.warning;
    }
    return AlertSeverity.critical; 
  }

  void _calculateCounts() {
    _activeCount = _allAlerts.where((a) => a.severity != AlertSeverity.resolved).length;
    _resolvedCount = _allAlerts.where((a) => a.severity == AlertSeverity.resolved).length;
  }

  List<Alert> _getFilteredAlerts(int index) {
    if (index == 0) return _allAlerts; // All
    if (index == 1) {
      return _allAlerts.where((a) => a.severity != AlertSeverity.resolved).toList(); // Active
    }
    return _allAlerts.where((a) => a.severity == AlertSeverity.resolved).toList(); // Resolved
  }

  // 5. Factory method to create an Alert from a Firestore DocumentSnapshot
  Alert _alertFromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final issue = data['issueDescription'] as String? ?? 'N/A';
    final shipmentId = data['shipmentId'] as String? ?? 'N/A';
    final timestamp = data['timestamp'] as Timestamp?;

    final dbSeverityString = data['severity'] as String?;

    AlertSeverity severity;
    
    if (dbSeverityString == 'resolved') {
    // If the database says 'resolved', use AlertSeverity.resolved
    severity = AlertSeverity.resolved;
  } else {
    // Otherwise, derive the severity from the issueDescription (default/active logic)
    severity = _getSeverityFromIssue(issue);
  }

    IconData icon;
    if (issue.contains('Temperature')) {
      icon = Icons.thermostat_outlined;
    } else if (issue.contains('Damage')) {
      icon = Icons.broken_image_outlined;
    } else if (issue.contains('Delay')) {
      icon = Icons.schedule;}
      else if (issue.contains('Power')) {
      icon = Icons.flash_off_outlined;}
      else if (issue.contains('Humidity')) {
      icon = Icons.water_drop_outlined;}
      else if (issue.contains('GPS')) {
      icon = Icons.location_off_outlined;
    } else {
      icon = Icons.error_outline;
    }
    
    return Alert(
      documentId: doc.id,
      title: issue, // Use the issueDescription as the title
      details: 'Shipment: $shipmentId',
      severity: severity,
      // NOTE: Time formatting is simplified here.
      timeAgo: timestamp != null ? 'on ${DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch).toString().substring(0, 16)}' : 'Time N/A',
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Alerts & Notifications',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: <Widget> [IconButton(
          icon: const Icon(Icons.arrow_forward_ios, color: Colors.black87),
          onPressed: () => Navigator.pushNamed(context, '/checkin'),
        ),],
      ),
      // 6. Use StreamBuilder to listen for data changes
      body: StreamBuilder<QuerySnapshot>(
        stream: _shipmentActions.orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No issues have been reported yet.'));
          }

          // Map Firebase data to local Alert model
          _allAlerts = snapshot.data!.docs.map(_alertFromSnapshot).toList();
          _calculateCounts(); // Recalculate counts whenever data changes

          return Column(
            children: [
              // 1. Alert Summary Counts (Now using live data counts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCountChip(
                      count: _activeCount,
                      label: 'Active Alerts',
                      color: Colors.red.shade600,
                      icon: Icons.circle,
                    ),
                    _buildCountChip(
                      count: _resolvedCount,
                      label: 'Resolved',
                      color: Colors.green.shade600,
                      icon: Icons.circle_outlined,
                      labelColor: Colors.green.shade600,
                    ),
                  ],
                ),
              ),

              // 2. Tab Bar for Filtering
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.blue.shade600,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.black54,
                  splashBorderRadius: BorderRadius.circular(10),
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Active'),
                    Tab(text: 'Resolved'),
                  ],
                ),
              ),

              // 3. Alert List (TabBarView)
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _AlertListView(alerts: _getFilteredAlerts(0)),
                    _AlertListView(alerts: _getFilteredAlerts(1)),
                    _AlertListView(alerts: _getFilteredAlerts(2)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      // 4. Export Button (kept outside StreamBuilder as it's static UI)
      bottomNavigationBar: _buildExportButton(),
    );
  }

  Widget _buildCountChip({required int count, required String label, required Color color, required IconData icon, Color? labelColor,}) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 8),
        Text(
          '$count $label',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: labelColor ?? Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildExportButton() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SizedBox(
        height: 55,
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            // Action to Export Report
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 5,
          ),
          icon: const Icon(Icons.outbound_rounded, color: Colors.white),
          label: const Text(
            'Export Report (PDF/CSV)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// --- Alert List View ---

class _AlertListView extends StatelessWidget {
  final List<Alert> alerts;

  const _AlertListView({required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return Center(
        child: Text(
          'No alerts found in this category.',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16.0, bottom: 24.0, left: 16.0, right: 16.0),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        return _AlertCard(alert: alerts[index]);
      },
    );
  }
}

// --- Individual Alert Card ---

class _AlertCard extends StatelessWidget {
  final Alert alert;

  const _AlertCard({required this.alert});

  // New method to handle the acknowledgment logic
  Future<void> _acknowledgeAlert(BuildContext context) async {
    final CollectionReference shipmentActions = 
        FirebaseFirestore.instance.collection('shipment_actions');

    // Perform the Firestore update
    await shipmentActions.doc(alert.documentId).update({
      'severity': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
    }).then((_) {
      // Optional: Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert acknowledged/resolved successfully!')),
      );
    }).catchError((error) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to acknowledge alert: $error')),
      );
    });
    // The StreamBuilder will automatically rebuild the UI with the updated data.
  }

  Widget _buildStatusBadge(String text, Color color, AlertSeverity severity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    Color iconColor;
    String statusText = '';
    
    switch (alert.severity) {
      case AlertSeverity.critical:
        cardColor = Colors.red.shade50;
        iconColor = Colors.red.shade600;
        statusText = 'CRITICAL';
        break;
      case AlertSeverity.warning:
        cardColor = Colors.amber.shade50;
        iconColor = Colors.amber.shade600;
        statusText = 'WARNING';
        break;
      case AlertSeverity.resolved:
        cardColor = Colors.green.shade50;
        iconColor = Colors.green.shade600;
        statusText = 'RESOLVED';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: iconColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Icon (Critical/Warning/Resolved)
              Icon(
                alert.severity == AlertSeverity.resolved ? Icons.check_circle_outline : Icons.error_outline,
                color: iconColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              // Alert Title and Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.timeAgo,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Right Status Badge
              _buildStatusBadge(statusText, iconColor, alert.severity),
            ],
          ),
          const SizedBox(height: 12),
          // Alert Details
          Text(
            alert.details,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          if (alert.severity != AlertSeverity.resolved) const SizedBox(height: 12),
          // Acknowledge Button for active/critical alerts
          if (alert.severity != AlertSeverity.resolved && !alert.isAcknowledged)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () 
                  // Action to Acknowledge Alert
                  => _acknowledgeAlert(context)
                ,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: iconColor.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'Acknowledge',
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}