import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Reusing Data Models (Consistency is Key!) ---
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
      latestLat = (data['latitude' ?? '--']).toString();
      latestLong = (data['longitude' ?? '--']).toString();
      //print('✅ Latest from Firebase: $latestTemperature°C, $latestHumidity%');
    }
  } catch (e) {
    print('❌ Error fetching Firebase data: $e');
  }
}

class MapScreenPage extends StatelessWidget
{
  const MapScreenPage({super.key});
  @override
  Widget build(BuildContext context)
  {
    return Scaffold
    (
      appBar: AppBar
      (
        backgroundColor: const Color(0xFF007AFF),
        title: Text('Shipment Map', 
        style: TextStyle(color: Colors.white,)),
        centerTitle: true,

        leading: IconButton
        (
            icon: Icon(Icons.arrow_back),
            color: Colors.white,
            tooltip: 'Back',
            onPressed: (){Navigator.pushNamed(context, '/');},
        ),

        actions: 
        [
          IconButton
          (
            icon: Icon(Icons.settings),
            color: Colors.white,
            tooltip: 'Settings',
            onPressed: (){Navigator.pushNamed(context, '/settings');},
          ),
        ],

      ),
      body: SafeArea
      (
        child: MapWidget(),
      ),
    );
  }
}

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State<MapWidget> createState() => ShipMapScreenState();
}

class ShipMapScreenState extends State<MapWidget> {
  final LatLng hub = LatLng(
  double.tryParse(latestLat) ?? 0.0,
  double.tryParse(latestLong) ?? 0.0,
);
  final List<Map<String, dynamic>> bins = [
    {
      //"image": 'assets/images/kk12.png',
      "name": "UMMC",
      "position": const LatLng(3.1137182, 101.6529117),
      //"storage": "52%",
      "context": "shipment_detail1",
    },
    {
      //"image": 'assets/images/kk11.png',
      "name": "TJHS",
      "position": const LatLng(2.7099559172071603, 101.94483019536577),
      //"storage": "70%",
      "context": "kk1",
    },
    {
      //"image": 'assets/images/kk2.png',
      "name": "MMC",
      "position": const LatLng(2.187564733509663, 102.25151859623307),
      //"storage": "43%",
      "context": "kk2",
    },
  ];

  String? selectedPopup;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea( child:FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(2.84082529732913, 101.96787363494908),
          initialZoom: 9.2,
          onTap: (_, __) => setState(() {
            selectedPopup = null;
          }),
        ),
        children: [
          // Tile Layer
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.mysampah',
          ),

          // Polyline Layer: connect bins to hub
          PolylineLayer(
            polylines: bins
                .map(
                  (bin) => Polyline(
                    points: [bin["position"], hub],
                    color: Colors.blue,
                    strokeWidth: 3.0,
                  ),
                )
                .toList(),
          ),

          // Marker Layer
          MarkerLayer(
            markers: [
              // Bins
              ...bins.map(
                (bin) => Marker(
                  point: bin["position"],
                  width: 300,
                  height: 60,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedPopup = bin["name"];
                      });
                    },
                    child: Column(
                      children: [
                        Icon(Icons.business, size: 35, color: Colors.black),
                        if (selectedPopup == bin["name"])
                          Flexible( 
                            child: TextButton.icon(
                              onPressed: (){Navigator.pushNamed(context, '/${bin["context"]}');},
                              label: Text("${bin["name"]}", style: const TextStyle(fontSize: 8),),
                              icon: Icon(Icons.arrow_forward),
                              style: TextButton.styleFrom
                              (
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.all(3),
                              ),
                              
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Hub
              Marker(
                point: hub,
                width: 60,
                height: 60,
                child: Column(
                  children: [
                    IconButton(icon: Icon(Icons.local_shipping), iconSize: 40, color: const Color(0xFF007AFF), onPressed:(){Navigator.pushNamed(context, '/hub');},),
                    Text("Hub", style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),),
    );
  }
}