import 'package:flutter/material.dart';

// --- Data Models ---

enum ReportStatus { compliant, warning, nonCompliant }

class ShipmentReport {
  final String shipmentId;
  final DateTime date;
  final ReportStatus status;
  final String details;
  final String logType;

  ShipmentReport({
    required this.shipmentId,
    required this.date,
    required this.status,
    required this.details,
    required this.logType,
  });
}

// --- Main Report Screen Widget ---

class ReportScreenPage extends StatefulWidget {
  const ReportScreenPage({super.key});

  @override
  State<ReportScreenPage> createState() => _ReportScreenPageState();
}

class _ReportScreenPageState extends State<ReportScreenPage> {
  DateTime _startDate = DateTime(2023, 10, 1);
  DateTime _endDate = DateTime(2023, 10, 31);

  // Mock Report Data
  final List<ShipmentReport> _mockReports = [
    ShipmentReport(
      shipmentId: 'VAX-007',
      date: DateTime(2025, 11, 11),
      status: ReportStatus.compliant,
      details: 'Status: Compliant',
      logType: 'Temperature Log',
    ),
    ShipmentReport(
      shipmentId: 'FRDGE-ALPHA',
      date: DateTime(2025, 10, 26),
      status: ReportStatus.warning,
      details: 'Warning (Drift) Event History',
      logType: 'Dew Point History',
    ),
    ShipmentReport(
      shipmentId: 'VAX-010',
      date: DateTime(2025, 9, 20),
      status: ReportStatus.nonCompliant,
      details: 'Critical Excursion Log',
      logType: 'Detailed Audit Trail',
    ),
  ];

  Future<void> _selectDateRange(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime(2025, 11, 20),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) _endDate = _startDate;
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) _startDate = _endDate;
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
          'Reports & Compliance',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // 1. Date Range Picker
                _buildDateRangePicker(context),
                const SizedBox(height: 16),

                // 2. Generate Monthly Report Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // Action to generate the monthly report based on the selected dates
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade500,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 3,
                    ),
                    child: const Text(
                      'Generate Monthly Report',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Shipment Report Cards
                ..._mockReports.map((report) => _ReportCard(report: report)),
                const SizedBox(height: 24),

                // 4. WHO/FDA Compliance Checklist
                _buildComplianceChecklist(),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // 5. Export All Reports Button (Bottom Fixed Button)
          _buildExportAllReportsButton(),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildDateRangePicker(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildDateButton(
          context,
          label: 'From:',
          date: _formatDate(_startDate),
          onTap: () => _selectDateRange(context, true),
        ),
        _buildDateButton(
          context,
          label: 'To:',
          date: _formatDate(_endDate),
          onTap: () => _selectDateRange(context, false),
        ),
      ],
    );
  }

  Widget _buildDateButton(BuildContext context, {required String label, required String date, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Text(
                  date,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Icon(Icons.calendar_today, size: 16, color: Colors.blue.shade600),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComplianceChecklist() {
    const List<String> checklistItems = [
      'Continuous Temp Monitoring',
      'Data Log Integrity (Tamper Evident)',
      'Excursion Reporting (Detailed)',
      'Calibration Records',
    ];

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
          Text(
            'WHO/FDA Compliance Checklist',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          ...checklistItems.map((item) => _buildChecklistItem(item)),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String text) {
    bool isChecked = text != 'Excursion Reporting (Detailed)'; // Mocking uncompleted item
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isChecked ? Colors.green.shade500 : Colors.blue.shade300,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: isChecked ? Colors.black87 : Colors.grey.shade600,
              decoration: isChecked ? TextDecoration.none : TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportAllReportsButton() {
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
            // Action to Export All Reports
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 5,
          ),
          icon: const Icon(Icons.description_outlined, color: Colors.white),
          label: const Text(
            'Export All Reports (PDF Summary)',
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

// --- Individual Report Card Widget ---

class _ReportCard extends StatelessWidget {
  final ShipmentReport report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    Color statusIconColor;
    String statusText;
    
    switch (report.status) {
      case ReportStatus.compliant:
        cardColor = Colors.green.shade50;
        statusIconColor = Colors.green.shade600;
        statusText = 'Compliant';
        break;
      case ReportStatus.warning:
        cardColor = Colors.amber.shade50;
        statusIconColor = Colors.amber.shade600;
        statusText = 'Warning';
        break;
      case ReportStatus.nonCompliant:
        cardColor = Colors.red.shade50;
        statusIconColor = Colors.red.shade600;
        statusText = 'Non-Compliant';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusIconColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusIconColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (Shipment ID & Search Icon)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shipment: ${report.shipmentId}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              Icon(Icons.search, color: Colors.grey.shade400, size: 24),
            ],
          ),
          const SizedBox(height: 8),

          // Date and Status (Compliant/Non-Compliant)
          Text('Date: ${_ReportScreenPageState()._formatDate(report.date)}', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 4),

          // Status Row
          Row(
            children: [
              Icon(
                report.status == ReportStatus.compliant ? Icons.check_circle_outline : (report.status == ReportStatus.warning ? Icons.warning_amber : Icons.cancel_outlined),
                color: statusIconColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Status: $statusText',
                style: TextStyle(
                  color: statusIconColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Icon(Icons.bolt, color: Colors.green, size: 18),
              const SizedBox(width: 4),
              Text('Online', style: TextStyle(color: Colors.green.shade600)),
            ],
          ),
          const Divider(height: 20, thickness: 1),

          // Report Details and Actions
          Text(report.details, style: const TextStyle(fontSize: 15, color: Colors.black87)),
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Log Type Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusIconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  report.logType,
                  style: TextStyle(color: statusIconColor, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),

              // Action Buttons
              Row(
                children: [
                  
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      report.status == ReportStatus.compliant ? 'View (PDF/CSV)' : 'Download (PDF/CSV)',
                      style: TextStyle(
                        color: report.status == ReportStatus.compliant ? Colors.blue.shade600 : statusIconColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
