import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BluetoothScreenPage(),
    );
  }
}

class BluetoothScreenPage extends StatefulWidget {
  final String shipmentId;

  const BluetoothScreenPage({super.key, this.shipmentId = 'VAX-008'});

  @override
  State<BluetoothScreenPage> createState() => _BluetoothScreenPageState();
}

class _BluetoothScreenPageState extends State<BluetoothScreenPage> {
  // ====== BLE Variables ======
  final String serviceUuid = "12345678-1234-1234-1234-1234567890ab";
  final String tempUuid = "12345678-1234-1234-1234-1234567890ac";
  final String humUuid = "12345678-1234-1234-1234-1234567890ad";
  final String latUuid = "12345678-1234-1234-1234-1234567890ae";
  final String longUuid = "12345678-1234-1234-1234-1234567890af";

  List<ScanResult> scanResults = [];
  BluetoothDevice? connectedDevice;
  String temperature = "--";
  String humidity = "--";
  String latitude = "--";
  String longitude = "--";
  String address = "--";
  bool isScanning = false;
  bool _isOfflineModeActive = true;

  String? _selectedIssue; // Variable to hold the selected issue
  final List<String> _issueOptions = const [
    'Temperature Violation',
    'Power Loss',
    'Humidity Drift',
    'GPS Offline',
    'Container Damage',
    'Unexpected Delay',
    'Sensor Malfunction',
    'Other',
  ];
  Future<void> _showReportIssueDialog() async {
    // Reset selected issue before showing (using parent setState)
    setState(() {
      _selectedIssue = null; 
    });
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Report an Issue'),
          // Use StatefulBuilder to manage the dialog's local state
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter localSetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Select the type of issue:', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey, width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedIssue,
                        hint: const Text('Choose Issue Type'),
                        items: _issueOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          // CRITICAL FIX: Use the localSetState() to rebuild the content
                          localSetState(() {
                            _selectedIssue = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                  
                  // Move buttons into the content so they rebuild with localSetState
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        child: const Text('Submit'),
                        // The onPressed property is correctly re-evaluated on localSetState call
                        onPressed: () {
                          // If no issue is selected, use a fallback string
                          final issueToReport = _selectedIssue ?? 'Issue (No Selection)'; 
                          
                          uploadShipmentAction(
                              actionType: 'Issue',
                              issueDescription: issueToReport,
                          );
                          Navigator.of(context).pop(); // Close the dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Issue reported: $issueToReport")),
                          );
                      },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          // Actions must be empty or removed since buttons are in content now
          actions: const <Widget>[],
        );
      },
    );
  }

  Future<void> uploadToFirebase(double temperature, double humidity, String address, String latitude, String longitude) async {
    try {
      await FirebaseFirestore.instance.collection('sensor_readings').add({
        'temperature': temperature,
        'humidity': humidity,
        'location': address,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'shipmentId': widget.shipmentId,
      });
      print('✅ Data uploaded to Firebase');
    } catch (e) {
      print('❌ Error uploading to Firebase: $e');
    }
  }

  Future<void> uploadShipmentAction({
  required String actionType, // "checkin" or "issue"
  String? issueDescription,   // optional
}) async {
  try {
    await FirebaseFirestore.instance.collection('shipment_actions').add({
      'shipmentId': widget.shipmentId,
      'timestamp': FieldValue.serverTimestamp(),
      'actionType': actionType,
      'issueDescription': issueDescription ?? '',
    });

    print('✅ $actionType saved successfully');
  } catch (e) {
    print('❌ Error saving $actionType: $e');
  }
}

  Future<void> uploadCheckin({
  required String actionType, // "checkin" or "issue"
  String? issueDescription,   // optional
}) async {
  try {
    await FirebaseFirestore.instance.collection('shipment_checkin').add({
      'shipmentId': widget.shipmentId,
      'timestamp': FieldValue.serverTimestamp(),
      'actionType': actionType,
      'issueDescription': issueDescription ?? '',
    });

    print('✅ $actionType saved successfully');
  } catch (e) {
    print('❌ Error saving $actionType: $e');
  }
}

  @override
  void initState() {
    super.initState();
    FlutterBluePlus.setLogLevel(LogLevel.none);
  }

  Future<void> requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  void startScan() async {
    await requestPermissions();

    var isOn = await FlutterBluePlus.adapterState.first;
    if (isOn != BluetoothAdapterState.on) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please turn on Bluetooth")),
      );
      return;
    }

    setState(() {
      scanResults.clear();
      isScanning = true;
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      setState(() {
        isScanning = scanning;
      });
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: false);
      setState(() {
        connectedDevice = device;
      });
      await discoverServices(device);
    } catch (e) {
      print("Connection error: $e");
    }
  }
  Future<void> getAddressFromLatLng(double lat, double lng) async {
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
    Placemark place = placemarks.first;
    setState(() {
      address = "${place.locality}, ${place.country}";
    });
  } catch (e) {
    print("Error: $e");
  }
}

  Future<void> discoverServices(BluetoothDevice device) async {
  List<BluetoothService> services = await device.discoverServices();

  for (var service in services) {
    if (service.uuid.toString() == serviceUuid) {
      for (var characteristic in service.characteristics) {
        if (characteristic.uuid.toString() == tempUuid) {
          await characteristic.setNotifyValue(true);
          characteristic.lastValueStream.listen((value) {
            final tempString = String.fromCharCodes(value);
            setState(() {
              temperature = tempString;
            });

            // ✅ Convert to double safely before uploading
            final tempValue = double.tryParse(tempString);
            final humValue = double.tryParse(humidity);

            if (tempValue != null && humValue != null && address.isNotEmpty) {
              uploadToFirebase(tempValue, humValue, address, latitude, longitude);
            }
          });
        } else if (characteristic.uuid.toString() == humUuid) {
          await characteristic.setNotifyValue(true);
          characteristic.lastValueStream.listen((value) {
            final humString = String.fromCharCodes(value);
            setState(() {
              humidity = humString;
            });

            // ✅ Convert to double safely before uploading
            final tempValue = double.tryParse(temperature);
            final humValue = double.tryParse(humString);

            if (tempValue != null && humValue != null && address.isNotEmpty) {
              uploadToFirebase(tempValue, humValue, address, latitude, longitude);
            }
          });
        } // 📍 Latitude
        else if (characteristic.uuid.toString() == latUuid) {
          await characteristic.setNotifyValue(true);
          characteristic.lastValueStream.listen((value) {
            final latString = String.fromCharCodes(value);
            setState(() {
              latitude = latString;
            });
            if (latitude != "--" && longitude != "--") {
              getAddressFromLatLng(double.parse(latitude), double.parse(longitude));
            }
          });
        } 
        // 📍 Longitude
        else if (characteristic.uuid.toString() == longUuid) {
          await characteristic.setNotifyValue(true);
          characteristic.lastValueStream.listen((value) {
            final longString = String.fromCharCodes(value);
            setState(() {
              longitude = longString;
            });
            if (latitude != "--" && longitude != "--") {
              getAddressFromLatLng(double.parse(latitude), double.parse(longitude));
            }
          });
        }
      }
    }
  }
}


  void disconnectDevice() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      setState(() {
        connectedDevice = null;
        temperature = "--";
        humidity = "--";
      });
    }
  }

  // ============================
  // ======== UI Section ========
  // ============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: Text(
          'Shipment ${widget.shipmentId}',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: connectedDevice == null
          ? _buildScanListUI()
          : _buildConnectedDashboardUI(),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  // --- 1️⃣ SCANNING MODE UI ---
  Widget _buildScanListUI() {
    return Column(
      children: [
        const SizedBox(height: 20),
        isScanning
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton.icon(
                onPressed: (){},
                icon: const Icon(Icons.build),
                label: const Text("Can't find device?"),
              ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: scanResults.length,
            itemBuilder: (context, index) {
              final result = scanResults[index];
              final name = result.device.name.isNotEmpty
                  ? result.device.name
                  : "Unknown Device";

              final isESP32 = name.toLowerCase().contains("esp32");

              return ListTile(
                title: Text(name),
                subtitle: Text(result.device.id.toString()),
                trailing: ElevatedButton(
                  onPressed:
                      isESP32 ? () => connectToDevice(result.device) : null,
                  child: const Text("Connect"),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- 2️⃣ CONNECTED DASHBOARD UI ---
  Widget _buildConnectedDashboardUI() {
    const String status = 'In Transit';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusGauges(status),
          const SizedBox(height: 24),
          _buildActionButtons(),
          const SizedBox(height: 24),
          _buildConnectivityBlock(),
          const SizedBox(height: 16),
          _buildOfflineModeToggle(),
        ],
      ),
    );
  }

  // --- Dashboard Widgets ---
  Widget _buildStatusGauges(String status) {
    final double? tempVal = double.tryParse(temperature);
    final int? humVal = int.tryParse(humidity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildGaugeCard(
              'Temperature',
              temperature == "--" ? "-- °C" : "$temperature°C",
              Colors.green.shade600,
              const Icon(Icons.thermostat_outlined, color: Colors.green),
            ),
            _buildGaugeCard(
              'Humidity',
              humidity == "--" ? "-- %" : "$humidity%",
              Colors.blue.shade600,
              const Icon(Icons.water_drop_outlined, color: Colors.blue),
            ),
          ],
        ),

        //GPS
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, color: Colors.red,),
              const SizedBox(width: 4),
              Text('Location: $address',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              //Text("( $latitude, $longitude )", style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Row(
            children: [
              Text("($latitude, $longitude)", style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
            ],
          ),
        ),

        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Row(
            children: [
              Text('Status: $status',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
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


  Widget _buildGaugeCard(String label, String value, Color color, Icon icon) {
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
                color: color,
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
            onPressed: () {uploadCheckin(actionType: 'Check-in');},
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            label: 'Report Issue',
            icon: Icons.report_problem_outlined,
            color: Colors.red.shade600,
            //onPressed: () {uploadShipmentAction(actionType: 'Report Issue');},
            onPressed: () {_showReportIssueDialog();},
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
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
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(Icons.bluetooth_connected, color: Colors.blue.shade600, size: 20),
          const SizedBox(width: 8),
          Text(
            connectedDevice != null
                ? 'Connected to ${connectedDevice!.name}'
                : 'Not Connected',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineModeToggle() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: _cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Offline Mode: Active',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text('Data will sync when online',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
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
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      color: Colors.white,
      child: SizedBox(
        height: 55,
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: connectedDevice == null ? startScan : disconnectDevice,
          style: ElevatedButton.styleFrom(
            backgroundColor: connectedDevice == null
                ? Colors.blue.shade600
                : Colors.red.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: Icon(
            connectedDevice == null
                ? Icons.bluetooth_searching
                : Icons.link_off,
            color: Colors.white,
          ),
          label: Text(
            connectedDevice == null ? 'Scan for Devices' : 'Disconnect',
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
