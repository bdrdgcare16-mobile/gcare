import 'package:flutter/material.dart';

class PermissionTimeScreen extends StatefulWidget {
  const PermissionTimeScreen({super.key});

  @override
  State<PermissionTimeScreen> createState() => _PermissionTimeScreenState();
}

class _PermissionTimeScreenState extends State<PermissionTimeScreen> {
  String? permissionType;
  DateTime? permissionDate;
  TimeOfDay? fromTime;
  TimeOfDay? toTime;
  String? reason;
  String? manager;
  String? proofFile;
  String status = 'Pending';

  final List<String> permissionTypes = ['Personal', 'Official', 'Medical'];
  final List<String> managers = ['Nishali', 'Aishwarya', 'Archana'];

  // Example past requests
  final List<Map<String, String>> pastRequests = [
    {
      'type': 'Personal',
      'date': '2024-05-10',
      'from': '10:00',
      'to': '12:00',
      'status': 'Approved'
    },
    {
      'type': 'Medical',
      'date': '2024-04-15',
      'from': '14:00',
      'to': '16:00',
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
      appBar: AppBar(title: const Text('Permission Time Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Permission Type
            DropdownButtonFormField<String>(
              value: permissionType,
              decoration: const InputDecoration(
                labelText: 'Permission Type *',
                border: OutlineInputBorder(),
              ),
              items: permissionTypes
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (v) => setState(() => permissionType = v),
            ),
            const SizedBox(height: 12),
            // Permission Date
            TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Permission Date *',
                border: const OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today, color: Colors.blue),
              ),
              controller: TextEditingController(
                text: permissionDate == null ? '' : permissionDate!.toString().split(' ')[0],
              ),
              onTap: () => _pickDate(context, (d) => setState(() => permissionDate = d)),
            ),
            const SizedBox(height: 12),
            // From Time
            TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'From Time *',
                border: const OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time, color: Colors.blue),
              ),
              controller: TextEditingController(
                text: fromTime == null ? '' : fromTime!.format(context),
              ),
              onTap: () => _pickTime(context, (t) => setState(() => fromTime = t)),
            ),
            const SizedBox(height: 12),
            // To Time
            TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'To Time *',
                border: const OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time, color: Colors.blue),
              ),
              controller: TextEditingController(
                text: toTime == null ? '' : toTime!.format(context),
              ),
              onTap: () => _pickTime(context, (t) => setState(() => toTime = t)),
            ),
            const SizedBox(height: 12),
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
            // Past Permission Requests
            const Text('Past Permission Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...pastRequests.map((req) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.history, color: Colors.blue),
                    title: Text('${req['type']} (${req['date']})'),
                    subtitle: Text('From: ${req['from']}  To: ${req['to']}'),
                    trailing: _statusBadge(req['status']!),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
