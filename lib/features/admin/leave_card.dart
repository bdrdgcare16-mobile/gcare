import 'package:flutter/material.dart';

class LeaveCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Function(String) onStatusChange;
  final bool isProcessing;
  final double? paidLeaveDays;
  final double? unpaidLeaveDays;

  const LeaveCard({
    super.key,
    required this.item,
    required this.onStatusChange,
    this.isProcessing = false,
    this.paidLeaveDays,
    this.unpaidLeaveDays,
  });

  // Determine if request requires paid/unpaid classification
  // A request is a genuine leave request only when type == "Leave Type"
  bool _isLeaveRequest() {
    final normalizedType = item['type']
        ?.toString()
        .trim()
        .toLowerCase();
    return normalizedType == 'leave type';
  }

  // Format leave days: 1.0 -> 1, 0.5 -> 0.5
  String _formatLeaveDays(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final hiddenKeys = <String>{
      'status',
      'selectedLeavePayType',
      'isLeaveRequest',
      'source',
      'id',
      'docId',
      'requestId',
      'leaveId',
      'attendanceId',
      'otherLocId',
      'leaveType', // Hide leaveType by default, will show conditionally
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 3,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...item.entries
                .where((entry) => !hiddenKeys.contains(entry.key))
                .map((e) {
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

              // Use resolved leave type for display if available (only for leave requests)
              // For leave requests with a real leaveType value, display it instead of the "Leave Type" label
              final displayValue = (key == 'type' && _isLeaveRequest() && item['leaveType'] != null && item['leaveType'].toString().trim().isNotEmpty)
                  ? item['leaveType']
                  : value;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        "$key: $displayValue",
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),

            // Display Leave Type detail row only for leave requests with a real value
            if (_isLeaveRequest() && item['leaveType'] != null && item['leaveType'].toString().trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Leave Type: ${item['leaveType']}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),

            // Display paid/unpaid leave totals only for genuine leave requests
            if (_isLeaveRequest() && (paidLeaveDays != null || unpaidLeaveDays != null))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    if (paidLeaveDays != null && paidLeaveDays! > 0)
                      Text(
                        'Paid Leave: ${_formatLeaveDays(paidLeaveDays!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (paidLeaveDays != null && paidLeaveDays! > 0 && unpaidLeaveDays != null && unpaidLeaveDays! > 0)
                      const SizedBox(width: 16),
                    if (unpaidLeaveDays != null && unpaidLeaveDays! > 0)
                      Text(
                        'Unpaid Leave: ${_formatLeaveDays(unpaidLeaveDays!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 10),

            if ((item['status'] ?? '').toString().toLowerCase() == 'pending')
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 500;
                  final isLeaveRequest = _isLeaveRequest();

                  if (isMobile) {
                    // Mobile layout: Wrap buttons
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isLeaveRequest)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isProcessing ? null : () => onStatusChange('approved_paid'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE8F5E8),
                                foregroundColor: const Color(0xFF2E7D32),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                minimumSize: const Size(0, 40),
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
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text("Approve as Paid"),
                            ),
                          ),
                        if (isLeaveRequest) const SizedBox(height: 8),
                        if (isLeaveRequest)
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isProcessing ? null : () => onStatusChange('approved_unpaid'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFF3E0),
                                    foregroundColor: const Color(0xFFEF6C00),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    minimumSize: const Size(0, 40),
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text("Approve as Unpaid"),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isProcessing ? null : () => onStatusChange('rejected'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFEBEE),
                                    foregroundColor: const Color(0xFFD32F2F),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    minimumSize: const Size(0, 40),
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
                              ),
                            ],
                          ),
                        if (!isLeaveRequest)
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isProcessing ? null : () => onStatusChange('approved'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE8F5E8),
                                    foregroundColor: const Color(0xFF2E7D32),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    minimumSize: const Size(0, 40),
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
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Text("Approve"),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isProcessing ? null : () => onStatusChange('rejected'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFEBEE),
                                    foregroundColor: const Color(0xFFD32F2F),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    minimumSize: const Size(0, 40),
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
                              ),
                            ],
                          ),
                      ],
                    );
                  } else {
                    // Desktop/tablet layout: Row
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isLeaveRequest)
                          ElevatedButton(
                            onPressed: isProcessing ? null : () => onStatusChange('approved_paid'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE8F5E8),
                              foregroundColor: const Color(0xFF2E7D32),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: const Size(0, 32),
                              textStyle: const TextStyle(
                                fontSize: 11,
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
                                : const Text("Approve as Paid"),
                          ),
                        if (isLeaveRequest) const SizedBox(width: 8),
                        if (isLeaveRequest)
                          ElevatedButton(
                            onPressed: isProcessing ? null : () => onStatusChange('approved_unpaid'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFF3E0),
                              foregroundColor: const Color(0xFFEF6C00),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: const Size(0, 32),
                              textStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text("Approve as Unpaid"),
                          ),
                        if (isLeaveRequest) const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isProcessing ? null : () => onStatusChange(isLeaveRequest ? 'rejected' : 'approved'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLeaveRequest 
                                ? const Color(0xFFFFEBEE)
                                : const Color(0xFFE8F5E8),
                            foregroundColor: isLeaveRequest
                                ? const Color(0xFFD32F2F)
                                : const Color(0xFF2E7D32),
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
                              : Text(isLeaveRequest ? "Reject" : "Approve"),
                        ),
                        if (!isLeaveRequest) const SizedBox(width: 8),
                        if (!isLeaveRequest)
                          ElevatedButton(
                            onPressed: isProcessing ? null : () => onStatusChange('rejected'),
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
                    );
                  }
                },
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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
                  if (item['leavePayType'] != null && item['status'] == 'approved')
                    Text(
                      "Approved as: ${_cap(item['leavePayType'].toString())}",
                      style: TextStyle(
                        fontSize: 11,
                        color: item['leavePayType'] == 'paid' ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
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

  // payroll button removed: use `leavePayType` as source of truth
}
