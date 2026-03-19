import 'package:flutter/material.dart';
import '../models/navigation_item.dart'; // Import the updated model

class HomeScreenPage extends StatelessWidget {
  // Define your main navigation items using routeName (String) instead of screen (Widget)
  final List<NavigationItem> mainMenuItems = const [
    NavigationItem(
      title: 'My Shipments / Fridges',
      description: 'View and manage all your shipments or storage units.',
      icon: Icons.ac_unit, // 🧊
      routeName: '/shipments_fridges', // <--- This route is defined in main.dart
      color: Color(0xFF007AFF), // ARMCOLD Blue
    ),
    NavigationItem(
      title: 'Alerts & Notifications',
      description: 'Check all critical temperature or power issues.',
      icon: Icons.notifications_active, // 🔔
      routeName: '/alerts', 
      color: Color(0xFFCC0000), // Red for alerts
    ),
    NavigationItem(
      title: 'AI Insights & Predictions',
      description: 'View AI analysis and spoilage forecasts.',
      icon: Icons.insights, // 🤖
      routeName: '/ai_insights', 
      color: Color(0xFF4CD964), // Green for insights
    ),
    NavigationItem(
      title: 'Reports & Compliance',
      description: 'Generate temperature and audit logs.',
      icon: Icons.assignment, // 📋
      routeName: '/reports', 
      color: Color(0xFFFF9500), // Orange for reports
    ),
    NavigationItem(
      title: 'Map Tracking',
      description: 'Track live shipment routes or device locations.',
      icon: Icons.map, // 🗺️
      routeName: '/map_tracking', 
      color: Color(0xFF5AC8FA), // Light Blue for map
    ),
    NavigationItem(
      title: 'Settings',
      description: 'Manage devices, thresholds, and profile.',
      icon: Icons.settings, // ⚙️
      routeName: '/settings', 
      color: Color(0xFF8E8E93), // Gray for settings
    ),
  ];

  const HomeScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder data for the footer
    const String userName = 'Dr 007';
    const String lastUpdated = '10:05 PM';
    const String alertSummary = '5 active alerts • 2 safe shipments';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Image.asset('assets/images/Logo.png', height: 65,),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF007AFF),
        elevation: 0,
      ),
      body: Column(
        children: <Widget>[
          // 1. Header Section
          Container(
            padding: const EdgeInsets.all(20.0),
            color: const Color(0xFF007AFF), // Background to match AppBar
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $userName 👋',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Quick overview of your Cold Chain network.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          // 2. Main Grid View
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                children: mainMenuItems.map((item) {
                  return _buildGridItem(context, item);
                }).toList(),
              ),
            ),
          ),

          // 3. Footer Summary
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alertSummary,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last updated: $lastUpdated',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build each Card item
  Widget _buildGridItem(BuildContext context, NavigationItem item) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // *** CRITICAL CHANGE: Navigate using the route name (String) ***
          // This requires the route to be registered in main.dart
          Navigator.pushNamed(context, item.routeName); 
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Center(child: Icon(item.icon, size: 40.0, color: item.color)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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