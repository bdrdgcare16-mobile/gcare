import 'package:flutter/material.dart';

class LeaveCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Function(String) onStatusChange;

  const LeaveCard({
    super.key,
    required this.item,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    // NOTE: No GestureDetector here. Parent handles onTap to open details.
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 3,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...item.entries.where((e) => e.key != 'status').map((e) {
              final key = _formatKey(e.key);
              String value = e.value?.toString() ?? '';
              
              // Handle empty values with better fallbacks
              if (value.trim().isEmpty) {
                switch (e.key) {
                  case 'department':
                  case 'dept':
                    value = 'No department assigned';
                    break;
                  case 'shift':
                  case 'shiftGroup':
                    value = 'No shift assigned';
                    break;
                  case 'requestTime':
                    value = 'No time recorded';
                    break;
                  case 'location':
                  case 'branchName':
                    value = 'No location assigned';
                    break;
                  case 'reason':
                    value = '---'; // nicer empty reason
                    break;
                  default:
                    value = '---'; // dash for other empty fields
                    break;
                }
              }
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text("$key: $value"),
              );
            }),
            const SizedBox(height: 10),
            if ((item['status'] ?? '').toString().toLowerCase() == 'pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => onStatusChange('approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8F5E8),
                      foregroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 32),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text("Approve"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => onStatusChange('rejected'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFEBEE),
                      foregroundColor: const Color(0xFFD32F2F),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 32),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text("Reject"),
                  ),
                ],
              )
            else
              Text(
                "Status: ${_cap((item['status'] ?? '').toString())}",
                style: TextStyle(
                  color: (item['status'] == 'approved')
                      ? Colors.green
                      : (item['status'] == 'rejected')
                          ? Colors.red
                          : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatKey(String key) => key
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .split('_')
      .map(_cap)
      .join(' ');

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
