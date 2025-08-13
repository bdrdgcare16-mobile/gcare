import 'package:flutter/material.dart';

class CompOffScreen extends StatefulWidget {
  const CompOffScreen({super.key});

  @override
  State<CompOffScreen> createState() => _CompOffScreenState();
}

class _CompOffScreenState extends State<CompOffScreen> {
  String? compOffType;
  DateTime? workedDate;
  DateTime? requestedOffDate;
  String? shiftGroup;
  String? manager;
  String? reason;
  String? proofFile;
  String status = 'Pending';

  final List<String> compOffTypes = ['Week Off', 'Holiday', 'Festival'];
  final List<String> shiftGroups = ['Morning', 'Evening', 'Night'];
  final List<String> managers = ['Alice', 'Bob', 'Charlie'];
  final List<String> reasons = ['Project Deadline', 'Support', 'Other'];

  // Example past requests
  final List<Map<String, String>> pastRequests = [
    {
      'type': 'Week Off',
      'workedDate': '2024-05-10',
      'offDate': '2024-05-20',
      'status': 'Approved'
    },
    {
      'type': 'Holiday',
      'workedDate': '2024-04-15',
      'offDate': '2024-04-25',
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
      appBar: AppBar(title: const Text('Comp Off Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Comp Off Type
            DropdownButtonFormField<String>(
              value: compOffType,
              decoration: const InputDecoration(
                labelText: 'CompOff Type *',
                border: OutlineInputBorder(),
              ),
              items: compOffTypes
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (v) => setState(() => compOffType = v),
            ),
            const SizedBox(height: 12),
            // Worked Date
            TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Worked Date *',
                border: const OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today, color: Colors.blue),
              ),
              controller: TextEditingController(
                text: workedDate == null ? '' : workedDate!.toString().split(' ')[0],
              ),
              onTap: () => _pickDate(context, (d) => setState(() => workedDate = d)),
            ),
            const SizedBox(height: 12),
            // Requested Off Date
            TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Requested Off Date *',
                border: const OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today, color: Colors.blue),
              ),
              controller: TextEditingController(
                text: requestedOffDate == null ? '' : requestedOffDate!.toString().split(' ')[0],
              ),
              onTap: () => _pickDate(context, (d) => setState(() => requestedOffDate = d)),
            ),
            const SizedBox(height: 12),
            // Shift Group
            DropdownButtonFormField<String>(
              value: shiftGroup,
              decoration: const InputDecoration(
                labelText: 'Shift Group *',
                border: OutlineInputBorder(),
              ),
              items: shiftGroups
                  .map((group) => DropdownMenuItem(value: group, child: Text(group)))
                  .toList(),
              onChanged: (v) => setState(() => shiftGroup = v),
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
            // Reason
            DropdownButtonFormField<String>(
              value: reason,
              decoration: const InputDecoration(
                labelText: 'Reason *',
                border: OutlineInputBorder(),
              ),
              items: reasons
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => reason = v),
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
            // Past Comp Off Requests
            const Text('Past Comp Off Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...pastRequests.map((req) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.history, color: Colors.blue),
                    title: Text('${req['type']} (${req['workedDate']})'),
                    subtitle: Text('Off: ${req['offDate']}'),
                    trailing: _statusBadge(req['status']!),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
