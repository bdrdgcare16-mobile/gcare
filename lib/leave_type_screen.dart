import 'package:flutter/material.dart';

class LeaveScreen extends StatelessWidget {
  const LeaveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply Leave')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _LeaveApplicationForm(),
      ),
    );
  }
}

class _LeaveApplicationForm extends StatefulWidget {
  const _LeaveApplicationForm({super.key});

  @override
  State<_LeaveApplicationForm> createState() => _LeaveApplicationFormState();
}

class _LeaveApplicationFormState extends State<_LeaveApplicationForm> {
  String leaveOrComp = 'Leave';
  String? selectedType;
  final causeController = TextEditingController();
  final notesController = TextEditingController();
  DateTime? fromDate, toDate;
  String? uploadedDocument;

  final Map<String, String> leaveTypeDetails = {
    'Sick Leave': 'Sick Leave can be availed when you are unwell. Requires medical certificate for more than 2 days.',
    'Personal Leave': 'Personal Leave can be used for personal reasons. Approval required from manager.',
    'Casual Leave': 'Casual Leave is for urgent or unforeseen matters. Max 5 per year.',
    'Planned Leave': 'Planned Leave should be applied at least 7 days in advance.',
  };

  void _showLeaveTypeDetails(String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        content: Text(leaveTypeDetails[type] ?? 'No details available.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _uploadDocument() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Document'),
        content: const Text('Document upload functionality will be implemented here. For now, this is a simulation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                uploadedDocument = 'document.pdf';
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Document uploaded successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  void _submitLeaveApplication() {
    // Validate form
    if (selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a leave type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (fromDate == null || toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select from and to dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (causeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the reason for leave'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Leave application submitted successfully for ${selectedType}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View History',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to leave history
            Navigator.pop(context);
          },
        ),
      ),
    );

    // Clear form
    setState(() {
      selectedType = null;
      fromDate = null;
      toDate = null;
      causeController.clear();
      notesController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Card
        Card(
          color: Colors.blue[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Leave Balance', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('5/10', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Text('Status', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Available', style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Radio buttons
        Row(
          children: [
            Radio<String>(
              value: 'Leave',
              groupValue: leaveOrComp,
              activeColor: Colors.blue,
              onChanged: (v) => setState(() => leaveOrComp = v!),
            ),
            const Text('Leave', style: TextStyle(color: Colors.black)),
            // Removed Comp Off radio and label
          ],
        ),
        const SizedBox(height: 8),
        // Leave Type Dropdown (custom bar)
        LeaveTypeDropdownBar(
          selectedType: selectedType,
          onChanged: (val) {
            setState(() => selectedType = val);
            _showLeaveTypeDetails(val);
          },
        ),
        const SizedBox(height: 8),
        // Cause
        TextFormField(
          controller: causeController,
          decoration: const InputDecoration(
            labelText: 'Cause *',
            labelStyle: TextStyle(color: Colors.black),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue, width: 1),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          style: TextStyle(color: Colors.black),
        ),
        const SizedBox(height: 8),
        // From Date
        TextFormField(
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'From Date *',
            labelStyle: TextStyle(color: Colors.black),
            suffixIcon: Icon(Icons.calendar_today, color: Colors.blue),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue, width: 1),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => fromDate = picked);
          },
          controller: TextEditingController(
            text: fromDate == null ? '' : fromDate!.toString().split(' ')[0],
          ),
          style: TextStyle(color: Colors.black),
        ),
        const SizedBox(height: 8),
        // To Date
        TextFormField(
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'To Date *',
            labelStyle: TextStyle(color: Colors.black),
            suffixIcon: Icon(Icons.calendar_today, color: Colors.blue),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue, width: 1),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => toDate = picked);
          },
          controller: TextEditingController(
            text: toDate == null ? '' : toDate!.toString().split(' ')[0],
          ),
          style: TextStyle(color: Colors.black),
        ),
        const SizedBox(height: 8),
        // Apply Leave Count
        const Text('Apply Leave Count 0', style: TextStyle(color: Colors.black)),
        const SizedBox(height: 8),
        // Upload File
        OutlinedButton.icon(
          onPressed: () => _uploadDocument(),
          icon: const Icon(Icons.upload_file, color: Colors.blue),
          label: Text(uploadedDocument != null ? 'Document uploaded' : 'Upload document', style: TextStyle(color: uploadedDocument != null ? Colors.green : Colors.black)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: uploadedDocument != null ? Colors.green : Colors.blue),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),
        // Notes field (extra feature)
        TextFormField(
          controller: notesController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            labelStyle: TextStyle(color: Colors.black),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue, width: 1),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          style: TextStyle(color: Colors.black),
        ),
        const SizedBox(height: 16),
        // Submit
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _submitLeaveApplication(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class LeaveTypeDropdownBar extends StatefulWidget {
  final String? selectedType;
  final ValueChanged<String> onChanged;
  const LeaveTypeDropdownBar({super.key, this.selectedType, required this.onChanged});

  @override
  State<LeaveTypeDropdownBar> createState() => _LeaveTypeDropdownBarState();
}

class _LeaveTypeDropdownBarState extends State<LeaveTypeDropdownBar> {
  final List<String> leaveTypes = [
    'Sick Leave',
    'Personal Leave',
    'Casual Leave',
    'Planned Leave',
  ];

  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => isExpanded = !isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.selectedType ?? 'Choose Leave Type',
                  style: TextStyle(
                    color: widget.selectedType == null ? Colors.blueGrey : Colors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: Colors.blue,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: leaveTypes.map((type) {
                return ListTile(
                  title: Text(type, style: const TextStyle(color: Colors.blue)),
                  onTap: () {
                    widget.onChanged(type);
                    setState(() => isExpanded = false);
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

