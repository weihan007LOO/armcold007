import 'package:flutter/material.dart';

class BluetoothScreenPage extends StatefulWidget {
  final String shipmentId;

  // Assuming this screen is opened with a specific shipment ID
  const BluetoothScreenPage({super.key, this.shipmentId = 'VAX-008'});

  @override
  State<BluetoothScreenPage> createState() => _BluetoothScreenPageState();
}

class _BluetoothScreenPageState extends State<BluetoothScreenPage> {
  // Mock State Variables
  bool _isOfflineModeActive = true;

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
        title: Text(
          'Shipment ${widget.shipmentId}',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Real-time Status Gauges
            _buildStatusGauges(),
            const SizedBox(height: 24),

            // 2. Action Buttons (Check-in / Report Issue)
            _buildActionButtons(),
            const SizedBox(height: 24),

            // 3. Connectivity Status
            _buildConnectivityBlock(),
            const SizedBox(height: 16),
            
            // 4. Offline Mode Toggle
            _buildOfflineModeToggle(),
          ],
        ),
      ),
      // 5. Scan Button (Fixed to Bottom)
      bottomNavigationBar: _buildScanForDevicesButton(),
    );
  }

  // --- Widget Builders ---

  Widget _buildStatusGauges() {
    // Mock Data
    const double tempValue = 3.5;
    const int humidityValue = 45;
    const String status = 'In Transit';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildGaugeCard(
              'Temperature',
              '$tempValue°C',
              Colors.green.shade600,
              const Icon(Icons.thermostat_outlined, color: Colors.green),
            ),
            _buildGaugeCard(
              'Humidity',
              '$humidityValue%',
              Colors.blue.shade600,
              const Icon(Icons.water_drop_outlined, color: Colors.blue),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Row(
            children: [
              Text('Status: $status', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
              const SizedBox(width: 8),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // FIXED: Changed parameter type from Color to MaterialColor and used .shade700 property if available, 
  // but since we are already passing a shaded color, we'll just use a defined darker color for contrast.
  Widget _buildGaugeCard(String label, String value, Color color, Icon icon) {
    Color textColor = Colors.black87; // Use a standard dark color for contrast

    // Check if the passed color is actually a MaterialColor (for shade access)
    if (color is MaterialColor) {
      textColor = color.shade700;
    } else if (color == Colors.green.shade600) {
      textColor = Colors.green.shade900;
    } else if (color == Colors.blue.shade600) {
      textColor = Colors.blue.shade900;
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor, // Use the dynamically determined textColor
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'Check-in',
            icon: Icons.assignment_turned_in_outlined,
            color: Colors.blue.shade600,
            onPressed: () {
              // Action for Check-in
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            label: 'Report Issue',
            icon: Icons.report_problem_outlined,
            color: Colors.red.shade600,
            onPressed: () {
              // Action to Report Issue
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({required String label, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        elevation: 1,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
      ),
      icon: Icon(icon, size: 24),
      label: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildConnectivityBlock() {
    return Container(
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
          const Text(
            'Connectivity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Divider(height: 20, thickness: 1),
          Row(
            children: [
              Icon(Icons.bluetooth_connected, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Bluetooth Sensor Connected',
                style: TextStyle(fontSize: 16, color: Colors.blue.shade600, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineModeToggle() {
    return Container(
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Offline Mode: Active',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              Text(
                'Data will sync when online',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
          Switch(
            value: _isOfflineModeActive,
            onChanged: (val) {
              setState(() => _isOfflineModeActive = val);
            },
            activeColor: Colors.blue.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildScanForDevicesButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        height: 55,
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            // Action to initiate Bluetooth scan
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 5,
          ),
          icon: const Icon(Icons.bluetooth_searching, color: Colors.white),
          label: const Text(
            'Scan for Devices',
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
