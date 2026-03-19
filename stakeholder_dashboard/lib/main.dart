import 'package:flutter/material.dart';
import 'screens/home_screen_page.dart';
import 'screens/shipments_fridges_page.dart' as fridge; 
import 'screens/shipdetail_screen_page.dart' as detail; 
import 'screens/shipdetail1_screen_page.dart' as detail1; 
import 'screens/ai_screen_page.dart'; 
import 'screens/alert_screen_page.dart'; 
import 'screens/report_screen_page.dart'; 
import 'screens/setting_screen_page.dart'; 
import 'screens/checkin_screen_page.dart';
import 'screens/map_screen_page.dart' as map; 
//import 'screens/bluetooth_screen_page.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await fridge.fetchLatestSensorData();
  await detail.fetchLatestSensorData();
  await detail1.fetchLatestSensorData();
  await map.fetchLatestSensorData();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARMCOLD App',
      theme: ThemeData(
        primaryColor: const Color(0xFF007AFF), // A main blue color
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(secondary: const Color(0xFF4CD964)),
        fontFamily: 'SF Pro Display', // Use a modern, clear font
      ),
      home: const HomeScreenPage(), // Set the new Home Screen as the starting page
      debugShowCheckedModeBanner: false,
      routes: {
        '/shipments_fridges': (context) => const fridge.ShipmentsFridgesScreen(), // The Destination Page
        '/shipment_detail': (context) => const detail.ShipmentDetailScreen(), //The Shipments Detail
        '/shipment_detail1': (context) => detail1.ShipmentDetailScreen1(), //The Shipments Detail
        '/ai_insights': (context) => const AiScreenPage(), //AI
        '/alerts': (context) => const AlertScreenPage(),
        '/reports': (context) => const ReportScreenPage(),
        '/settings': (context) => const SettingScreenPage(),
        '/map_tracking': (context) => const map.MapScreenPage(),
        '/checkin': (context) => CheckinScreenPage(),
        //'/bluetooth': (context) => const BluetoothScreenPage(),
        //'/inventory': (context) => const PlaceholderScreen(title: 'Inventory Status'), 
        //'/sensor_health': (context) => const PlaceholderScreen(title: 'Sensor Health'),
        //'/reports': (context) => const PlaceholderScreen(title: 'Reports & Analytics'),
      },
    );
  }
}