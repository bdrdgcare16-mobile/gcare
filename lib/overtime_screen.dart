import 'package:flutter/material.dart';

class OverTimeScreen extends StatefulWidget {
  const OverTimeScreen({super.key});

  @override
  State<OverTimeScreen> createState() => _OverTimeScreenState();
}

class _OverTimeScreenState extends State<OverTimeScreen> {
  DateTime? overtimeDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String? reason;
  String? manager;
  String? proofFile;
  String status = 'Pending';

  final List<String> managers = ['Alice', 'Bob', 'Charlie'];

  // Example past requests
  final List<Map<String, String>> pastRequests = [
    {
      'date': '2024-05-10',
      'start': '18:00',
      'end': '21:00',
      'hours': '3',
      'status': 'Approved'
    },
    {
      'date': '2024-04-15',
      'start': '19:00',
      'end': '22:00',
      'hours': '3',
      'status': 'Pending'
    },
  ];

  Future<void> _pickDate(BuildContext context, ValueChanged<DateTime> onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _pickTime(BuildContext context, ValueChanged<TimeOfDay> onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) onPicked(picked);
  }

  String _calculateTotalHours() {
    if (startTime == null || endTime == null) return '';
    final start = DateTime(0, 0, 0, startTime!.hour, startTime!.minute);
    final end = DateTime(0, 0, 0, endTime!.hour, endTime!.minute);
    final diff = end.difference(start);
    if (diff.isNegative) return '';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'Approved':
        color = Colors.green;
        break;
      case 'Rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Over Time Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overtime Date
            TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Overtime Date *',
                border: const OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today, color: Colors.blue),
              ),
              controller: TextEditingController(
                text: overtimeDate == null ? '' : overtimeDate!.toString().split(' ')[0],
              ),
              onTap: () => _pickDate(context, (d) => setState(() => overtimeDate = d)),
            ),
            const SizedBox(height: 12),
            // Start Time
            TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Start Time *',
                border: const OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time, color: Colors.blue),
              ),
              controller: TextEditingController(
                text: startTime == null ? '' : startTime!.format(context),
              ),
              onTap: () => _pickTime(context, (t) => setState(() => startTime = t)),
            ),
            const SizedBox(height: 12),
            // End Time
            TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'End Time *',
                border: const OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time, color: Colors.blue),
              ),
              controller: TextEditingController(
                text: endTime == null ? '' : endTime!.format(context),
              ),
              onTap: () => _pickTime(context, (t) => setState(() => endTime = t)),
            ),
            const SizedBox(height: 12),
            // Total Hours
            if (startTime != null && endTime != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Text('Total Hours: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(_calculateTotalHours(), style: const TextStyle(color: Colors.blue)),
                  ],
                ),
              ),
            // Reason
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Reason *',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => reason = v),
            ),
            const SizedBox(height: 12),
            // Manager/Approver
            DropdownButtonFormField<String>(
              value: manager,
              decoration: const InputDecoration(
                labelText: 'Manager/Approver *',
                border: OutlineInputBorder(),
              ),
              items: managers
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => manager = v),
            ),
            const SizedBox(height: 12),
            // Upload Proof
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement file picker
              },
              icon: const Icon(Icons.upload_file, color: Colors.blue),
              label: Text(proofFile ?? 'Upload Proof (optional)', style: const TextStyle(color: Colors.black)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.blue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            // Status badge
            Row(
              children: [
                const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                _statusBadge(status),
              ],
            ),
            const SizedBox(height: 20),
            // Submit and Cancel buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Submit logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Submit', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Cancel logic
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Past Overtime Requests
            const Text('Past Overtime Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...pastRequests.map((req) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.history, color: Colors.blue),
                    title: Text('${req['date']} (${req['hours']}h)'),
                    subtitle: Text('From: ${req['start']}  To: ${req['end']}'),
                    trailing: _statusBadge(req['status']!),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
