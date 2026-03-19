import 'package:flutter/material.dart';

class SettingScreenPage extends StatefulWidget {
  const SettingScreenPage({super.key});

  @override
  State<SettingScreenPage> createState() => _SettingScreenPageState();
}

class _SettingScreenPageState extends State<SettingScreenPage> {
  // Mock State Variables for Toggles
  bool _isAppNotificationEnabled = true;
  bool _isOfflineModeEnabled = false;
  bool _isDataSyncIntervalEnabled = true;

  // Mock State Variables for Inputs
  TextEditingController _tempThresholdController = TextEditingController(text: '4.0');
  TextEditingController _syncIntervalController = TextEditingController(text: '5');

  @override
  void dispose() {
    _tempThresholdController.dispose();
    _syncIntervalController.dispose();
    super.dispose();
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
          'Settings Management',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(top: 16.0, bottom: 100.0),
            children: [
              // 1. Device Management Section
              _buildSettingsBlock(
                title: 'Device Management',
                children: [
                  _buildDeviceHeader(),
                  _buildSubText('Add / Remove IOT Devices'),
                  const SizedBox(height: 16),
                  _buildPairDeviceButton(),
                ],
              ),
              
              // 2. Alert Configuration Section
              _buildSettingsBlock(
                title: 'Alert Configuration',
                children: [
                  _buildTemperatureThresholdInput(),
                  _buildAlertMethodCheckboxes(),
                  _buildToggleRow(
                    label: 'Offline Mode',
                    value: _isOfflineModeEnabled,
                    onChanged: (val) {
                      setState(() => _isOfflineModeEnabled = val);
                    },
                    subtext: ('When enabled, only critical notifications are sent.'),
                    subtextSize: 10.2,
                  ),
                ],
              ),

              // 3. Account Settings Section
              _buildSettingsBlock(
                title: 'Account Settings',
                children: [
                  _buildChangePasswordButton(),
                  _buildAccountDetail('Data Sync Interval (e.g. 5 min)', isToggle: true),
                  _buildAccountDetail('Version: 1.2.0', subtext: 'Updated recently.'),
                  _buildAccountDetail('Contact Support'),
                ],
              ),
            ],
          ),
          
          // Fixed Bottom Button
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildLogoutButton(),
          ),
        ],
      ),
    );
  }

  // --- Core Layout Widgets ---

  Widget _buildSettingsBlock({required String title, required List<Widget> children}) {
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSubText(String text, {double fontSize = 14}) {
  return Text(
    text,
    style: TextStyle(
      fontSize: fontSize,
      color: Colors.grey.shade600,
    ),
  );
}

  // --- Device Management Sub-Widgets ---

  Widget _buildDeviceHeader() {
    return Row(
      children: [
        Icon(Icons.widgets_outlined, color: Colors.blue.shade400, size: 28),
        const SizedBox(width: 8),
        const Text(
          'ARMCOLD',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPairDeviceButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () {
          // Action for pairing device
          //Navigator.pushNamed(context, '/bluetooth');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 3,
        ),
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: const Text(
          'Pair Device (QR Scan / BLE)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // --- Alert Configuration Sub-Widgets ---

  Widget _buildTemperatureThresholdInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSubText('Set Temperature Threshold °C'),
          SizedBox(
            width: 80,
            height: 35,
            child: TextField(
              controller: _tempThresholdController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertMethodCheckboxes() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Checkbox(
                value: _isAppNotificationEnabled,
                onChanged: (val) {
                  setState(() => _isAppNotificationEnabled = val ?? false);
                },
                activeColor: Colors.blue.shade600,
              ),
              _buildSubText('App Notification', fontSize: 12),
            ],
          ),
          const SizedBox(width: 1),
          Row(
            children: [
              Icon(Icons.email_outlined, color: Colors.grey.shade600, size: 20),
              _buildSubText(' Email',fontSize: 12),
            ],
          ),
          const SizedBox(width: 1),
          Row(
            children: [
              Icon(Icons.sms_outlined, color: Colors.grey.shade600, size: 20),
              _buildSubText(' SMS',fontSize: 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({required String label, required bool value, required ValueChanged<bool> onChanged, String? subtext,double subtextSize = 14,}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              if (subtext != null) _buildSubText(subtext, fontSize: subtextSize),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue.shade600,
          ),
        ],
      ),
    );
  }

  // --- Account Settings Sub-Widgets ---

  Widget _buildChangePasswordButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Change Password',
            style: TextStyle(fontSize: 15, color: Colors.black87),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.keyboard_arrow_right, color: Colors.blue.shade600, size: 20),
                Text(
                  '+',
                  style: TextStyle(color: Colors.blue.shade600, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDetail(String label, {bool isToggle = false, String? subtext}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: isToggle
          ? _buildToggleRow(
              label: label,
              value: _isDataSyncIntervalEnabled,
              onChanged: (val) {
                setState(() => _isDataSyncIntervalEnabled = val);
              },
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                    if (subtext != null) _buildSubText(subtext),
                  ],
                ),
                if (label.contains('Contact Support')) Icon(Icons.support_agent, color: Colors.blue.shade600),
              ],
            ),
    );
  }

  // --- Bottom Button ---

  Widget _buildLogoutButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      color: Colors.white,
      child: SizedBox(
        height: 55,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // Action to log out
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 5,
          ),
          child: const Text(
            'ARMCOLD Logout',
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