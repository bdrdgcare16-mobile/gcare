import 'package:flutter/material.dart';

class LeaveCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Function(String) onStatusChange;
  final Function(String) onPayrollStatusChange;
  final bool isProcessing;

  const LeaveCard({
    super.key,
    required this.item,
    required this.onStatusChange,
    required this.onPayrollStatusChange,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
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
                    value = '---';
                    break;
                  default:
                    value = '---';
                    break;
                }
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text("$key: $value"),
              );
            }),
            const SizedBox(height: 10),

            // Row(
            //   mainAxisAlignment: MainAxisAlignment.end,
            //   children: [
            //     _buildPayrollButton('Paid', 'paid'),
            //     const SizedBox(width: 8),
            //     _buildPayrollButton('Unpaid', 'unpaid'),
            //   ],
            // ),

            const SizedBox(height: 10),

            if ((item['status'] ?? '').toString().toLowerCase() == 'pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed:
                        isProcessing ? null : () => onStatusChange('approved'),
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
                    child: isProcessing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Approve"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed:
                        isProcessing ? null : () => onStatusChange('rejected'),
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

  Widget _buildPayrollButton(String label, String status) {
    final currentPayrollStatus =
        (item['payrollStatus'] ?? '').toString().toLowerCase();
    final isSelected = currentPayrollStatus == status;

    Color backgroundColor;
    Color foregroundColor;

    if (isSelected) {
      if (status == 'paid') {
        backgroundColor = const Color(0xFF4CAF50);
        foregroundColor = Colors.white;
      } else if (status == 'unpaid') {
        backgroundColor = const Color(0xFFFF9800);
        foregroundColor = Colors.white;
      } else {
        backgroundColor = const Color(0xFFE0E0E0);
        foregroundColor = const Color(0xFF757575);
      }
    } else {
      backgroundColor = const Color(0xFFE0E0E0);
      foregroundColor = const Color(0xFF757575);
    }

    return ElevatedButton(
      onPressed: isProcessing ? null : () => onPayrollStatusChange(status),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
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
      child: Text(label),
    );
  }
}