import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:serv_app/features/admin/payslip_pdf_builder.dart';
import 'package:serv_app/utils/payroll_period_resolver.dart';
import 'package:serv_app/utils/date_formatter.dart';
import 'package:serv_app/utils/payslip_pdf_downloader.dart';
import 'package:serv_app/widgets/payslip_preview.dart';
import 'package:serv_app/services/api_service.dart';

// Theme colors
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kTextColor = Colors.white;
const Color kPrimaryBackground = Color(0xFFF5F0FF);

class EmployeePayslipPage extends StatefulWidget {
  const EmployeePayslipPage({super.key});

  @override
  State<EmployeePayslipPage> createState() => _EmployeePayslipPageState();
}

class _EmployeePayslipPageState extends State<EmployeePayslipPage> {
  // Month and year selection
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // Loading states
  bool _isLoading = false;
  bool _isDownloading = false;

  // Payroll data
  Map<String, dynamic>? _payrollData;
  String? _errorMessage;

  // Month names
  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryBackground,
      appBar: AppBar(
        title: const Text(
          'Payslip',
          style: TextStyle(
            fontSize: 18,
            color: kTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: kAppBarColor,
        iconTheme: const IconThemeData(color: kTextColor),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month and Year selectors
              _buildSelectors(),
              const SizedBox(height: 24),

              // View Payslip button
              _buildViewPayslipButton(),
              const SizedBox(height: 24),

              // Payslip result section
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_errorMessage != null)
                _buildErrorMessage()
              else if (_payrollData != null)
                _buildPayslipResult()
              else
                _buildEmptyState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectors() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month dropdown
            _buildDropdown(
              label: 'Select Month',
              value: _selectedMonth,
              items: List.generate(12, (index) => index + 1),
              itemLabel: (value) => _monthNames[value - 1],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedMonth = value;
                    _payrollData = null;
                    _errorMessage = null;
                  });
                }
              },
            ),
            SizedBox(height: isSmallScreen ? 12 : 0),
            
            if (!isSmallScreen) const SizedBox(width: 16),
            
            // Year dropdown
            _buildDropdown(
              label: 'Select Year',
              value: _selectedYear,
              items: List.generate(5, (index) => DateTime.now().year - index),
              itemLabel: (value) => value.toString(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedYear = value;
                    _payrollData = null;
                    _errorMessage = null;
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D1B4E),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD1C4E9)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabel(item),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2D1B4E),
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF8C6EAF)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewPayslipButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _loadPayroll,
        style: ElevatedButton.styleFrom(
          backgroundColor: kAppBarColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'View Payslip',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: const Color(0xFFD1C4E9),
          ),
          const SizedBox(height: 16),
          const Text(
            'No payslip loaded',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D1B4E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a month and year, then click View Payslip',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF655193),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayslipResult() {
    final period = PayrollPeriod(
      month: _selectedMonth,
      year: _selectedYear,
      monthName: _monthNames[_selectedMonth - 1],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${period.monthName} ${period.year} Payslip',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D1B4E),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Paid',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Employee details
          _buildDetailRow('Employee Name', _payrollData!['employeeName']),
          if (_payrollData!['employeeId'] != null)
            _buildDetailRow('Employee ID', _payrollData!['employeeId'].toString()),
          _buildDetailRow('Payment Status', 'Paid'),
          if (_payrollData!['paidAt'] != null)
            _buildDetailRow('Paid Date', formatPayrollDateFromDynamic(_payrollData!['paidAt'])),
          const SizedBox(height: 16),

          // Salary summary
          _buildSalaryRow('Basic Salary', _payrollData!['basicSalary']),
          _buildSalaryRow('Gross Earnings', _payrollData!['grossSalary'] ?? _payrollData!['grossEarnings']),
          _buildSalaryRow('Total Deductions', _payrollData!['totalDeductions']),
          const SizedBox(height: 8),
          _buildSalaryRow('Net Salary', _payrollData!['netSalary'], isBold: true),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _previewPayslip(period),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF8C6EAF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Preview Payslip',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8C6EAF),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isDownloading ? null : () => _downloadPayslip(period),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAppBarColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isDownloading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Download PDF',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF655193),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2D1B4E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryRow(String label, dynamic value, {bool isBold = false}) {
    final formattedValue = _formatCurrency(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: Color(0xFF655193),
            ),
          ),
          Text(
            formattedValue,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: Color(0xFF2D1B4E),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '0') ?? 0;
    return 'Rs. ${NumberFormat("#,##0.00", "en_IN").format(amount)}';
  }

  Future<void> _loadPayroll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _payrollData = null;
    });

    try {
      final response = await ApiService.get(
        '/payroll/my-payroll',
        queryParameters: {
          'month': _selectedMonth.toString(),
          'year': _selectedYear.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data is Map<String, dynamic>) {
          setState(() {
            _payrollData = data;
          });
        } else {
          setState(() {
            _errorMessage = 'No confirmed payslip is available for the selected period.';
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Your session has expired. Please log in again.';
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = 'No confirmed payslip is available for the selected period.';
        });
      } else if (response.statusCode == 400) {
        setState(() {
          _errorMessage = 'Invalid month or year.';
        });
      } else {
        setState(() {
          _errorMessage = 'Unable to load the payslip. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to load the payslip. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _previewPayslip(PayrollPeriod period) {
    if (_payrollData == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PayslipPreview(
          payrollData: _payrollData!,
          fallbackMonth: _selectedMonth,
          fallbackYear: _selectedYear,
        ),
      ),
    );
  }

  Future<void> _downloadPayslip(PayrollPeriod period) async {
    if (_payrollData == null) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      // Load company logo bytes
      Uint8List? logoBytes;
      try {
        final logoData = await rootBundle.load('assets/images/myth_reality_tech_logo.jpeg');
        logoBytes = logoData.buffer.asUint8List();
      } catch (e) {
        // If logo fails to load, continue without it (PDF will use placeholder)
      }

      // Generate PDF using the shared PDF builder
      final pdfBytes = await PayslipPdfBuilder.generatePayslipPdf(
        payroll: _payrollData!,
        companyId: _payrollData!['companyId']?.toString() ?? 'unknown',
        companyLogoBytes: logoBytes,
        fallbackMonth: _selectedMonth,
        fallbackYear: _selectedYear,
      );

      // Generate filename
      final filename = 'Payslip_${period.monthName}_${period.year}';

      // Save or share using platform-specific method
      await PayslipPdfDownloader.saveOrShare(
        bytes: pdfBytes,
        fileName: filename,
      );

      if (!mounted) return;

      // Platform-specific success message
      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF downloaded successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF is ready. Select where to save or share it.'),
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Payslip PDF error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to create or save PDF: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }
}
