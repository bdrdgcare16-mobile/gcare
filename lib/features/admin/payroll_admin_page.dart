import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:serv_app/services/api_service.dart';
import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/widgets/payslip_preview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PayrollAdminPage extends StatefulWidget {
  const PayrollAdminPage({super.key});

  @override
  State<PayrollAdminPage> createState() => _PayrollAdminPageState();
}

class _PayrollAdminPageState extends State<PayrollAdminPage> {
  String? currentCompanyId;
  List<Map<String, dynamic>> payrollList = [];
  List<Map<String, dynamic>> failedPayrollList = [];
  List<Map<String, dynamic>> previewPayrollList = [];
  List<Map<String, dynamic>> previewFailedPayrollList = [];
  bool isLoading = false;
  bool isPreviewing = false;
  bool hasGenerated = false;
  bool hasPreviewed = false;
  bool _isMarkingPaid = false;
  String? _markingPaidPayrollId;
  String? errorMessage;
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  String selectedSalaryCalculationMethod = 'ACTUAL_CALENDAR_DAYS';

  // Shared helper to determine payment status
  String _getPaymentStatus(Map<String, dynamic> payroll) {
    final status = payroll['paymentStatus'] ?? payroll['status'];
    if (status != null) {
      return status.toString().trim().toLowerCase();
    }
    return payroll['isPaid'] == true ? 'paid' : 'pending';
  }

  // Shared helper to check if payroll is paid
  bool _isPayrollPaid(Map<String, dynamic> payroll) {
    return _getPaymentStatus(payroll) == 'paid' || payroll['isPaid'] == true;
  }

  double _getTotalAllowance(Map<String, dynamic> payroll) {
    final allowances = payroll['allowances'] as List? ?? [];
    double total = 0;

    for (final item in allowances) {
      final amount = double.tryParse(item['amount'].toString()) ?? 0;
      total += amount;
    }

    return total;
  }

  void _confirmPaid(String payrollId) {
    _markPayrollPaid(payrollId);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  Future<void> _markPayrollPaid(String payrollId) async {
    if (_isMarkingPaid) return;

    final apiBase = ApiService.baseUrl;
    final cleanApiBase = apiBase.trim().replaceAll(RegExp(r'/+$'), '');

    if (cleanApiBase.isEmpty) {
      _showError('Payroll API base URL is not configured.');
      return;
    }

    if (payrollId.isEmpty) {
      _showError('Payroll ID is required to confirm payment.');
      return;
    }

    final endpoint = '$cleanApiBase/payroll/$payrollId/paid';

    setState(() {
      _isMarkingPaid = true;
      _markingPaidPayrollId = payrollId;
    });

    try {
      final response = await ApiService.patch(
        '/payroll/$payrollId/paid',
        authRequired: true,
      );

      debugPrint('[PAYROLL] Mark paid status: ${response.statusCode}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message = 'Unable to confirm payroll payment.';

        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['message'] != null) {
            message = decoded['message'].toString();
          }
        } catch (_) {}

        throw Exception(message);
      }

      // Update the exact payroll item in the displayed list
      if (!mounted) return;

      setState(() {
        final index = payrollList.indexWhere((item) => item['id'] == payrollId);
        if (index != -1) {
          payrollList[index] = {
            ...payrollList[index],
            'paymentStatus': 'paid',
            'status': 'paid',
            'isPaid': true,
          };
        }
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payroll marked as paid successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('[PAYROLL] Mark paid error occurred');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingPaid = false;
          _markingPaidPayrollId = null;
        });
      }
    }
  }

  void _viewPayroll(Map<String, dynamic> payroll) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (bottomSheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Payroll Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4B3B73),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(bottomSheetContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow('Employee Name', payroll['employeeName']),
              _buildDetailRow('Employee ID', payroll['employeeId']),
              _buildDetailRow('Payment Status', payroll['status']?.toString()),
              _buildDetailRow(
                  'Basic Salary', _formatCurrency(payroll['basicSalary'])),
              _buildDetailRow('Worked Days', payroll['workedDays']?.toString()),
              _buildDetailRow(
                  'Paid Weekly Off Days', payroll['weekOffDays']?.toString()),
              _buildDetailRow(
                  'Paid Holiday Days', payroll['holidayDays']?.toString()),
              _buildDetailRow(
                  'Paid Leave Days', payroll['paidLeaveDays']?.toString()),
              _buildDetailRow(
                  'Unpaid Leave Days', payroll['unpaidLeaveDays']?.toString()),
              _buildDetailRow('Total LOP Days', payroll['lopDays']?.toString()),
              _buildDetailRow(
                  'Payable Days', payroll['payableDays']?.toString()),
              _buildDetailRow(
                  'Salary Calculation Method',
                  payroll['salaryCalculationMethod']?.toString() ??
                      'ACTUAL_CALENDAR_DAYS'),
              _buildDetailRow(
                  'Divisor Used',
                  payroll['perDaySalary'] != null
                      ? (payroll['basicSalary'] / payroll['perDaySalary'])
                          .toStringAsFixed(1)
                      : 'N/A'),
              _buildDetailRow(
                  'Per-Day Salary', _formatCurrency(payroll['perDaySalary'])),
              _buildDetailRow(
                  'LOP Deduction', _formatCurrency(payroll['lopDeduction'])),
              _buildDetailRow(
                  'Earned Basic', _formatCurrency(payroll['earnedBasic'])),
              _buildDetailRow('Earned Allowance',
                  _formatCurrency(payroll['earnedAllowance'])),
              _buildDetailRow(
                  'Gross Salary', _formatCurrency(payroll['grossSalary'])),
              _buildDetailRow(
                  'Net Salary', _formatCurrency(payroll['netSalary'])),
              const SizedBox(height: 16),
              const Text(
                'Allowances',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B3B73),
                ),
              ),
              const SizedBox(height: 12),
              _buildAllowancesSection(
                payroll['allowances'] as List<dynamic>? ?? [],
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Total Allowance Amount',
                _formatCurrency(payroll['totalAllowance']),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewPayslip(Map<String, dynamic> payroll) {
    // Ensure the payroll data includes the selected period as fallback
    final payslipData = {
      ...payroll,
      'month': payroll['month'] ?? selectedMonth,
      'year': payroll['year'] ?? selectedYear,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PayslipPreview(
          payrollData: payslipData,
          fallbackMonth: selectedMonth,
          fallbackYear: selectedYear,
        ),
      ),
    );
  }

  Widget _buildAllowancesSection(List<dynamic> allowances) {
    if (allowances.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text(
          'No Allowance',
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      children: allowances.map((allowance) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  allowance['type']?.toString() ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '₹${allowance['amount']?.toString() ?? '0'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B3B73),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatCurrency(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '0') ?? 0;
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _formatPayrollPeriod(int? year, int? month) {
    if (year == null || month == null) return 'N/A';
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> _normalizeUpdatedPayrollForDisplay(
    Map<String, dynamic> updated,
    Map<String, dynamic> previous,
  ) {
    final normalized = <String, dynamic>{
      ...previous,
      ...updated,
    };

    for (final key in [
      'workedDays',
      'weekOffDays',
      'paidLeaveDays',
      'absentDays',
      'lopDays',
      'payableDays',
    ]) {
      normalized[key] = normalized[key]?.toString() ?? '0';
    }

    normalized['salary'] = _formatCurrency(
      updated['netSalary'] ??
          updated['grossSalary'] ??
          previous['netSalary'] ??
          previous['grossSalary'] ??
          0,
    );
    normalized['salaryDate'] = _formatPayrollPeriod(
      int.tryParse(
          (updated['year'] ?? previous['year'] ?? selectedYear).toString()),
      int.tryParse(
          (updated['month'] ?? previous['month'] ?? selectedMonth).toString()),
    );

    return normalized;
  }

  String _getSalaryMethodDescription() {
    switch (selectedSalaryCalculationMethod) {
      case 'ACTUAL_CALENDAR_DAYS':
        return 'Pay is calculated using actual calendar days in the payroll period.';
      case 'FIXED_30_DAYS':
        return 'Pay is calculated on a fixed 30-day month basis regardless of month length.';
      case 'SCHEDULED_WORKING_DAYS':
        return 'Pay is calculated using scheduled working days after weekends and holidays are excluded.';
      default:
        return '';
    }
  }

  Future<void> _loadCurrentCompanyId() async {
    try {
      // Try CompanyData first (already loaded in memory)
      if (CompanyData.companyId.isNotEmpty) {
        currentCompanyId = CompanyData.companyId;
        return;
      }

      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      currentCompanyId = prefs.getString('companyId');

      if (currentCompanyId == null || currentCompanyId!.trim().isEmpty) {
        throw Exception('Company ID not found for the logged-in admin');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Company ID not found for the logged-in admin';
        });
      }
      debugPrint('[PAYROLL] Error loading companyId');
    }
  }

  Future<void> _generatePayroll() async {
    if (currentCompanyId == null || currentCompanyId!.trim().isEmpty) {
      _loadCurrentCompanyId();
      return;
    }

    // Future-month validation
    final now = DateTime.now();
    final selectedDate = DateTime(selectedYear, selectedMonth);
    if (selectedDate.isAfter(DateTime(now.year, now.month))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot generate payroll for a future month'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Generate Payroll'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Company: $currentCompanyId'),
            const SizedBox(height: 8),
            Text('Period: ${_getMonthName(selectedMonth)} $selectedYear'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF655193),
              foregroundColor: Colors.white,
            ),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final requestCompanyId = currentCompanyId!.trim();
    final requestYear = selectedYear;
    final requestMonth = selectedMonth;
    final requestSalaryCalculationMethod = selectedSalaryCalculationMethod;

    setState(() {
      isLoading = true;
      errorMessage = null;
      payrollList = [];
      failedPayrollList = [];
      hasGenerated = false;
    });

    final requestBody = {
      'companyId': requestCompanyId,
      'year': requestYear,
      'month': requestMonth,
      'salaryCalculationMethod': requestSalaryCalculationMethod,
    };

    final uri = Uri.parse('${ApiService.baseUrl}/payroll/generate');

    try {
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(minutes: 5));

      if (!mounted) return;

      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode}');
      }

      final responseJson = jsonDecode(resp.body) as Map<String, dynamic>;
      final generated = (responseJson['data']?['generated'] as List?) ?? [];
      final failed = (responseJson['data']?['failed'] as List?) ?? [];

      // Strict frontend filtering for companyId and period
      final filteredGenerated = generated.where((item) {
        final itemCompanyId = item['companyId']?.toString();
        final itemYear = int.tryParse(item['year']?.toString() ?? '');
        final itemMonth = int.tryParse(item['month']?.toString() ?? '');

        return itemCompanyId == requestCompanyId &&
            itemYear == requestYear &&
            itemMonth == requestMonth;
      }).toList();

      final mapped = filteredGenerated.map<Map<String, dynamic>>((item) {
        final id = item['id']?.toString() ?? '';

        // Preserve backend payment status without forcing default
        final rawPaymentStatus = item['paymentStatus'] ?? item['status'];
        final normalizedPaymentStatus = (rawPaymentStatus != null &&
                rawPaymentStatus.toString().trim().isNotEmpty)
            ? rawPaymentStatus.toString().trim().toLowerCase()
            : (item['isPaid'] == true ? 'paid' : 'pending');
        final normalizedIsPaid =
            item['isPaid'] == true || normalizedPaymentStatus == 'paid';

        final mappedItem = {
          'id': id,
          'companyId': item['companyId']?.toString() ?? '',
          'employeeName': item['employeeName']?.toString() ?? 'N/A',
          'employeeId': item['empid']?.toString() ?? 'N/A',
          'paymentStatus': normalizedPaymentStatus,
          'status': normalizedPaymentStatus,
          'isPaid': normalizedIsPaid,
          'paidAt': item['paidAt'],
          'paidBy': item['paidBy'],
          'salary':
              _formatCurrency(item['netSalary'] ?? item['grossSalary'] ?? 0),
          'salaryDate': _formatPayrollPeriod(
              item['year'] ?? selectedYear, item['month'] ?? selectedMonth),
          'workedDays': item['workedDays']?.toString() ?? '0',
          'weekOffDays': item['weekOffDays']?.toString() ?? '0',
          'absentDays': item['absentDays']?.toString() ?? '0',
          'lopDays': item['lopDays']?.toString() ?? '0',
          'payableDays': item['payableDays']?.toString() ?? '0',
          'basicSalary': item['basicSalary'] ?? 0,
          'earnedBasic': item['earnedBasic'] ?? 0,
          'grossSalary': item['grossSalary'] ?? 0,
          'netSalary': item['netSalary'] ?? 0,
          'allowances': List<Map<String, dynamic>>.from(
              item['allowances'] as List? ?? []),
          'totalAllowance': item['totalAllowance'] ?? 0,
        };

        return mappedItem;
      }).toList();

      // Deduplicate by payroll ID
      final uniquePayrolls = <String, Map<String, dynamic>>{};
      for (final item in mapped) {
        final id = item['id']?.toString() ?? '';
        if (id.isNotEmpty) uniquePayrolls[id] = item;
      }

      if (!mounted) return;
      setState(() {
        previewPayrollList = [];
        previewFailedPayrollList = [];
        payrollList = uniquePayrolls.values.toList();
        failedPayrollList = List<Map<String, dynamic>>.from(failed);
        hasGenerated = true;
        hasPreviewed = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e is TimeoutException
              ? 'Failed to generate payroll: Request timed out. Please try again.'
              : 'Failed to generate payroll: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _previewPayroll() async {
    if (currentCompanyId == null || currentCompanyId!.trim().isEmpty) {
      _loadCurrentCompanyId();
      return;
    }

    final now = DateTime.now();
    final selectedDate = DateTime(selectedYear, selectedMonth);
    if (selectedDate.isAfter(DateTime(now.year, now.month))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot preview payroll for a future month'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      isPreviewing = true;
      errorMessage = null;
      previewPayrollList = [];
      previewFailedPayrollList = [];
      hasPreviewed = false;
    });

    final requestBody = {
      'companyId': currentCompanyId,
      'year': selectedYear,
      'month': selectedMonth,
      'salaryCalculationMethod': selectedSalaryCalculationMethod,
    };

    final uri = Uri.parse('${ApiService.baseUrl}/payroll/generate/preview');

    try {
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (!mounted) return;

      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode}');
      }

      final responseJson = jsonDecode(resp.body) as Map<String, dynamic>;
      final generated = (responseJson['data']?['generated'] as List?) ?? [];
      final failed = (responseJson['data']?['failed'] as List?) ?? [];

      final mapped = generated.map<Map<String, dynamic>>((item) {
        final id = item['id']?.toString() ?? '';

        // Preserve backend payment status without forcing default
        final rawPaymentStatus = item['paymentStatus'] ?? item['status'];
        final normalizedPaymentStatus = (rawPaymentStatus != null &&
                rawPaymentStatus.toString().trim().isNotEmpty)
            ? rawPaymentStatus.toString().trim().toLowerCase()
            : (item['isPaid'] == true ? 'paid' : 'pending');
        final normalizedIsPaid =
            item['isPaid'] == true || normalizedPaymentStatus == 'paid';

        return {
          'id': id,
          'companyId': item['companyId']?.toString() ?? '',
          'employeeName': item['employeeName']?.toString() ?? 'N/A',
          'employeeId': item['empid']?.toString() ?? 'N/A',
          'paymentStatus': normalizedPaymentStatus,
          'status': normalizedPaymentStatus,
          'isPaid': normalizedIsPaid,
          'paidAt': item['paidAt'],
          'paidBy': item['paidBy'],
          'salary':
              _formatCurrency(item['netSalary'] ?? item['grossSalary'] ?? 0),
          'salaryDate': _formatPayrollPeriod(
              item['year'] ?? selectedYear, item['month'] ?? selectedMonth),
          'workedDays': item['workedDays']?.toString() ?? '0',
          'weekOffDays': item['weekOffDays']?.toString() ?? '0',
          'absentDays': item['absentDays']?.toString() ?? '0',
          'lopDays': item['lopDays']?.toString() ?? '0',
          'payableDays': item['payableDays']?.toString() ?? '0',
          'basicSalary': item['basicSalary'] ?? 0,
          'earnedBasic': item['earnedBasic'] ?? 0,
          'grossSalary': item['grossSalary'] ?? 0,
          'netSalary': item['netSalary'] ?? 0,
          'allowances': List<Map<String, dynamic>>.from(
              item['allowances'] as List? ?? []),
          'totalAllowance': item['totalAllowance'] ?? 0,
          'salaryCalculationMethod':
              item['salaryCalculationMethod']?.toString() ??
                  selectedSalaryCalculationMethod,
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        previewPayrollList = mapped;
        previewFailedPayrollList = List<Map<String, dynamic>>.from(failed);
        hasPreviewed = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to preview payroll: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isPreviewing = false;
        });
      }
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editPayroll(Map<String, dynamic> payroll) async {
    final workedDaysController = TextEditingController(
      text: payroll['workedDays']?.toString() ?? '',
    );

    final lopDaysController = TextEditingController(
      text: payroll['lopDays']?.toString() ?? '',
    );

    final allowanceAmountController = TextEditingController();

    String selectedAllowance = 'Overtime Allowance';
    String? dialogErrorMessage;
    bool isSaving = false;

    final List<String> allowanceTypes = [
      'Overtime Allowance',
      'Shift Allowance',
      'Food Allowance',
      'Travel Allowance',
      'Bonus',
    ];

    final List<Map<String, String>> tempAllowances =
        List<Map<String, String>>.from(
      (payroll['allowances'] as List? ?? []).map(
        (item) => {
          'type': item['type'].toString(),
          'amount': item['amount'].toString(),
        },
      ),
    );

    final Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            void addAllowance() {
              final amount = allowanceAmountController.text.trim();

              if (amount.isEmpty) {
                setDialogState(() {
                  dialogErrorMessage = 'Please enter allowance amount';
                });
                return;
              }

              final alreadyExists = tempAllowances.any(
                (item) => item['type'] == selectedAllowance,
              );

              if (alreadyExists) {
                setDialogState(() {
                  dialogErrorMessage = 'This allowance is already added';
                });
                return;
              }

              setDialogState(() {
                tempAllowances.add({
                  'type': selectedAllowance,
                  'amount': amount,
                });

                allowanceAmountController.clear();
                dialogErrorMessage = null;
              });
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              backgroundColor: const Color(0xFFF1EAF7),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(dialogContext).size.height * 0.82,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit Payroll',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2F2940),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildEditTextField(
                          label: 'Worked Days',
                          controller: workedDaysController,
                        ),
                        const SizedBox(height: 12),
                        _buildEditTextField(
                          label: 'LOP Days',
                          controller: lopDaysController,
                        ),
                        const SizedBox(height: 12),
                        _buildEditDropdownField(
                          label: 'Allowance Type',
                          value: selectedAllowance,
                          items: allowanceTypes,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedAllowance = value ?? 'Overtime Allowance';
                              dialogErrorMessage = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildEditTextField(
                          label: 'Allowance Amount',
                          controller: allowanceAmountController,
                        ),
                        const SizedBox(height: 8),
                        if (dialogErrorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              dialogErrorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ElevatedButton(
                          onPressed: addAllowance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8C6EAF),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: const Text(
                            'Add Allowance',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (tempAllowances.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Added Allowances',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4B3B73),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...tempAllowances.map((allowance) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF9E95A8),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${allowance['type']} - ₹${allowance['amount']}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2F2940),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setDialogState(() {
                                        tempAllowances.remove(allowance);
                                        dialogErrorMessage = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop(null);
                              },
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Color(0xFF8C6EAF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      final workedDays = int.tryParse(
                                        workedDaysController.text.trim(),
                                      );
                                      final lopDays = int.tryParse(
                                        lopDaysController.text.trim(),
                                      );
                                      final allowances =
                                          <Map<String, dynamic>>[];

                                      for (final allowance in tempAllowances) {
                                        final type =
                                            allowance['type']?.trim() ?? '';
                                        final amount = double.tryParse(
                                          allowance['amount']?.trim() ?? '',
                                        );
                                        if (type.isEmpty ||
                                            amount == null ||
                                            amount < 0) {
                                          setDialogState(() {
                                            dialogErrorMessage =
                                                'Invalid allowance values';
                                          });
                                          return;
                                        }
                                        allowances.add({
                                          'type': type,
                                          'amount': amount,
                                        });
                                      }

                                      if (workedDays == null ||
                                          workedDays < 0 ||
                                          lopDays == null ||
                                          lopDays < 0) {
                                        setDialogState(() {
                                          dialogErrorMessage =
                                              'Worked Days and LOP Days must be valid non-negative numbers';
                                        });
                                        return;
                                      }

                                      setDialogState(() {
                                        isSaving = true;
                                        dialogErrorMessage = null;
                                      });

                                      try {
                                        final response =
                                            await ApiService.updatePayroll(
                                          payrollId:
                                              payroll['id']?.toString() ?? '',
                                          workedDays: workedDays,
                                          lopDays: lopDays,
                                          allowances: allowances,
                                        );
                                        if (!mounted) return;
                                        final updatedPayroll =
                                            Map<String, dynamic>.from(
                                          response['data'] as Map? ?? response,
                                        );
                                        Navigator.of(dialogContext).pop(
                                          _normalizeUpdatedPayrollForDisplay(
                                            updatedPayroll,
                                            payroll,
                                          ),
                                        );
                                      } catch (error) {
                                        setDialogState(() {
                                          isSaving = false;
                                          dialogErrorMessage = error
                                              .toString()
                                              .replaceFirst('Exception: ', '');
                                        });
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF655193),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    workedDaysController.dispose();
    lopDaysController.dispose();
    allowanceAmountController.dispose();

    if (!mounted || result == null) return;

    final index = payrollList.indexWhere(
      (item) => item['id'] == payroll['id'],
    );

    if (index != -1) {
      setState(() {
        payrollList[index] = {
          ...payrollList[index],
          ...result,
        };
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payroll updated successfully')),
      );
    }
  }

  Widget _buildEditTextField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF6F6280),
          fontSize: 13,
        ),
        filled: true,
        fillColor: const Color(0xFFF1EAF7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(
            color: Color(0xFF9E95A8),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(
            color: Color(0xFF655193),
            width: 1.4,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: Colors.grey.shade400,
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildEditDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6F6280),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF1EAF7),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(
                color: Color(0xFF9E95A8),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(
                color: Color(0xFF655193),
                width: 1.4,
              ),
            ),
          ),
          isExpanded: true,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPreviewStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4B3B73),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    String statusText;

    switch (status.toLowerCase()) {
      case 'pending':
        badgeColor = Colors.orange;
        statusText = 'Pending';
        break;
      case 'approved':
      case 'paid':
        badgeColor = Colors.green;
        statusText = 'Paid';
        break;
      default:
        badgeColor = Colors.grey;
        statusText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPayrollCard(Map<String, dynamic> payroll) {
    final isPaid = _isPayrollPaid(payroll);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payroll['employeeName'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B3B73),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${payroll['employeeId'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(_getPaymentStatus(payroll)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallInfo('Worked', payroll['workedDays'] ?? '0'),
              _buildSmallInfo('Paid Weekly Off', payroll['weekOffDays'] ?? '0'),
              _buildSmallInfo('Paid Leave', payroll['paidLeaveDays'] ?? '0'),
              _buildSmallInfo('LOP', payroll['lopDays'] ?? '0'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallInfo(
                'Allowances',
                '${(payroll['allowances'] as List<dynamic>? ?? []).length}',
              ),
              _buildSmallInfo(
                'Total',
                '₹${_getTotalAllowance(payroll).toStringAsFixed(0)}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Salary',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    payroll['salary'] ?? '₹0',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4B3B73),
                    ),
                  ),
                ],
              ),
              Text(
                payroll['salaryDate'] ?? 'N/A',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              // Use Wrap for responsive button layout
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                children: [
                  SizedBox(
                    width: constraints.maxWidth > 400
                        ? 120
                        : constraints.maxWidth > 320
                            ? 100
                            : 80,
                    child: OutlinedButton(
                      onPressed: () => _viewPayroll(payroll),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF8C6EAF)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: const Text(
                          'View',
                          style: TextStyle(color: Color(0xFF8C6EAF)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: constraints.maxWidth > 400
                        ? 120
                        : constraints.maxWidth > 320
                            ? 100
                            : 80,
                    child: OutlinedButton(
                      onPressed: () => _viewPayslip(payroll),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF655193)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: const Text(
                          'View Payslip',
                          style: TextStyle(color: Color(0xFF655193)),
                        ),
                      ),
                    ),
                  ),
                  if (!isPaid)
                    SizedBox(
                      width: constraints.maxWidth > 400
                          ? 120
                          : constraints.maxWidth > 320
                              ? 100
                              : 80,
                      child: ElevatedButton(
                        onPressed: () => _editPayroll(payroll),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8C6EAF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: const Text('Edit'),
                        ),
                      ),
                    ),
                  if (!isPaid)
                    SizedBox(
                      width: constraints.maxWidth > 400
                          ? 120
                          : constraints.maxWidth > 320
                              ? 100
                              : 80,
                      child: ElevatedButton(
                        onPressed: _markingPaidPayrollId == payroll['id']
                            ? null
                            : () => _confirmPaid(payroll['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _markingPaidPayrollId == payroll['id']
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Confirm Paid',
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B3B73),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentCompanyId();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.15,
                    ),
                    children: [
                      TextSpan(
                        text: 'Payroll',
                        style: TextStyle(color: Color(0xFF1E1B4B)),
                      ),
                      TextSpan(
                        text: ' Management',
                        style: TextStyle(color: Color(0xFF8B5CF6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Period Selector and Generate Button
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Month',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4B3B73),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButton<int>(
                            value: selectedMonth,
                            isExpanded: true,
                            items: List.generate(12, (index) {
                              return DropdownMenuItem<int>(
                                value: index + 1,
                                child: Text(_getMonthName(index + 1)),
                              );
                            }),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedMonth = value;
                                  payrollList = [];
                                  failedPayrollList = [];
                                  hasGenerated = false;
                                  errorMessage = null;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Year',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4B3B73),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButton<int>(
                            value: selectedYear,
                            isExpanded: true,
                            items: List.generate(5, (index) {
                              final year = DateTime.now().year - 2 + index;
                              return DropdownMenuItem<int>(
                                value: year,
                                child: Text(year.toString()),
                              );
                            }),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedYear = value;
                                  payrollList = [];
                                  failedPayrollList = [];
                                  hasGenerated = false;
                                  errorMessage = null;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Salary Method',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4B3B73),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButton<String>(
                            value: selectedSalaryCalculationMethod,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: 'ACTUAL_CALENDAR_DAYS',
                                child: Text('Actual calendar days'),
                              ),
                              DropdownMenuItem(
                                value: 'FIXED_30_DAYS',
                                child: Text('Fixed 30 days'),
                              ),
                              DropdownMenuItem(
                                value: 'SCHEDULED_WORKING_DAYS',
                                child: Text('Scheduled working days'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedSalaryCalculationMethod = value;
                                  payrollList = [];
                                  failedPayrollList = [];
                                  previewPayrollList = [];
                                  previewFailedPayrollList = [];
                                  hasGenerated = false;
                                  hasPreviewed = false;
                                  errorMessage = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getSalaryMethodDescription(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _generatePayroll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF655193),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Generate Payroll',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          // Payroll List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(errorMessage!),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadCurrentCompanyId,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : hasPreviewed
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Payroll Preview Summary',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF4B3B73),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        runSpacing: 12,
                                        spacing: 12,
                                        children: [
                                          _buildPreviewStat(
                                              'Generated',
                                              previewPayrollList.length
                                                  .toString()),
                                          _buildPreviewStat(
                                              'Failed',
                                              previewFailedPayrollList.length
                                                  .toString()),
                                          _buildPreviewStat('Salary method',
                                              selectedSalaryCalculationMethod),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (previewFailedPayrollList.isNotEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.orange.shade300),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Preview failures',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF8C4A00),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...previewFailedPayrollList
                                            .take(5)
                                            .map((item) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8),
                                            child: Text(
                                              '${item['empid'] ?? 'Unknown'} — ${item['reason'] ?? 'Unknown reason'}',
                                              style:
                                                  const TextStyle(fontSize: 13),
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                if (previewPayrollList.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Previewed Payroll Entries',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4B3B73),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...previewPayrollList.take(10).map(
                                      (payroll) => _buildPayrollCard(payroll)),
                                ],
                              ],
                            ),
                          )
                        : payrollList.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'No generated payroll found for the selected month.',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (hasGenerated &&
                                        failedPayrollList.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.orange.shade300),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              'Generated Employees: ${payrollList.length}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF4B3B73),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Failed Employees: ${failedPayrollList.length}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: Colors.grey.shade300),
                                            ),
                                            child: Column(
                                              children: [
                                                const Text(
                                                  'Generated Employees',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '${payrollList.length}',
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF4B3B73),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: Colors.grey.shade300),
                                            ),
                                            child: Column(
                                              children: [
                                                const Text(
                                                  'Failed Employees',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '${failedPayrollList.length}',
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: Colors.grey.shade300),
                                            ),
                                            child: Column(
                                              children: [
                                                const Text(
                                                  'Pending Payment',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '${payrollList.where((p) => p['status'] == 'pending').length}',
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    ...payrollList.map((payroll) =>
                                        _buildPayrollCard(payroll)),
                                  ],
                                ),
                              ),
          ),
        ],
      ),
    );
  }
}
