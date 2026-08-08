import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:serv_app/features/admin/payslip_pdf_builder.dart';
import 'package:serv_app/utils/payroll_period_resolver.dart';
import 'package:serv_app/utils/payslip_pdf_downloader.dart';

class PayslipPreview extends StatefulWidget {
  final Map<String, dynamic> payrollData;
  final int? fallbackMonth;
  final int? fallbackYear;

  const PayslipPreview({
    super.key,
    required this.payrollData,
    this.fallbackMonth,
    this.fallbackYear,
  });

  @override
  State<PayslipPreview> createState() => _PayslipPreviewState();
}

class _PayslipPreviewState extends State<PayslipPreview> {
  bool _isDownloading = false;
  late PayrollPeriod _period;

  @override
  void initState() {
    super.initState();
    try {
      _period = resolvePayrollPeriod(
        widget.payrollData,
        fallbackMonth: widget.fallbackMonth,
        fallbackYear: widget.fallbackYear,
      );
    } catch (e) {
      // If period cannot be resolved, show error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Unable to identify the payroll period for this payslip.'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
      });
      // Set a default period to prevent crashes
      _period = const PayrollPeriod(
        month: 1,
        year: 2000,
        monthName: 'Unknown',
      );
    }
  }

  String _formatCurrency(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '0') ?? 0;
    return 'Rs. ${NumberFormat("#,##0.00", "en_IN").format(amount)}';
  }

  // Normalized field accessors for consistency with PDF
  String _getGrossSalary(Map<String, dynamic> payroll) {
    return payroll['grossSalary']?.toString() ??
           payroll['grossEarnings']?.toString() ??
           payroll['monthlySalary']?.toString() ??
           '0';
  }

  String _getNetSalary(Map<String, dynamic> payroll) {
    return payroll['netSalary']?.toString() ??
           payroll['salary']?.toString() ??
           payroll['finalSalary']?.toString() ??
           '0';
  }

  String _getPaymentStatus() {
    final status = widget.payrollData['paymentStatus']?.toString() ??
                   widget.payrollData['status']?.toString() ??
                   (widget.payrollData['isPaid'] == true ? 'paid' : 'pending');
    
    // Normalize to title case
    if (status.toLowerCase() == 'paid') return 'Paid';
    if (status.toLowerCase() == 'pending') return 'Pending';
    return status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // Light blue/pale blue background
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3E50), // Dark professional header
        elevation: 0,
        title: const Text(
          'Payslip Preview',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildEmployeePayInfo(),
                    const SizedBox(height: 24),
                    _buildEntitlementsTable(),
                    const SizedBox(height: 24),
                    _buildDeductionsTable(),
                    const SizedBox(height: 24),
                    _buildNetPaySection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isDownloading ? null : () => _downloadPayslip(context),
        backgroundColor: const Color(0xFF2C3E50),
        icon: _isDownloading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.download, color: Colors.white),
        label: Text(
          _isDownloading ? 'Generating...' : 'Download PDF',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company logo
            SizedBox(
              width: 90,
              height: 90,
              child: Image.asset(
                'assets/images/myth_reality_tech_logo.jpeg',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F8),
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Text(
                        'COMPANY\nLOGO',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            // Company information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'PAYSLIP',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Myth Reality Technologies Pvt. Ltd.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _period.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEmployeePayInfo() {
    // Build list of available fields
    final fields = <Widget>[];
    
    // Always show Employee Name
    fields.add(_buildInfoRow('Employee Name', widget.payrollData['employeeName']));
    
    // Show Employee ID if available
    final employeeId = widget.payrollData['employeeId']?.toString() ??
                      widget.payrollData['empid']?.toString() ??
                      widget.payrollData['employee_id']?.toString();
    if (employeeId != null && employeeId.isNotEmpty) {
      fields.add(_buildInfoRow('Employee ID', employeeId));
    }
    
    // Show Payment Status
    fields.add(_buildInfoRow('Payment Status', _getPaymentStatus()));
    
    // Show Paid Date only when status is paid
    final paymentStatus = widget.payrollData['paymentStatus']?.toString() ??
                          widget.payrollData['status']?.toString();
    final isPaid = paymentStatus?.toLowerCase() == 'paid' || widget.payrollData['isPaid'] == true;
    if (isPaid) {
      fields.add(_buildInfoRow('Paid Date', widget.payrollData['paidDate']));
    }
    
    // Show Worked Days if available and non-zero
    final workedDays = widget.payrollData['workedDays']?.toString() ??
                       widget.payrollData['presentDays']?.toString();
    if (workedDays != null && workedDays != '0' && workedDays.isNotEmpty) {
      fields.add(_buildInfoRow('Worked Days', workedDays));
    }
    
    // Show Paid Weekly Off if available and non-zero
    final weekOffDays = widget.payrollData['weekOffDays']?.toString() ??
                        widget.payrollData['paidWeeklyOffDays']?.toString() ??
                        widget.payrollData['paidWeeklyOff']?.toString();
    if (weekOffDays != null && weekOffDays != '0' && weekOffDays.isNotEmpty) {
      fields.add(_buildInfoRow('Paid Weekly Off', weekOffDays));
    }
    
    // Show Paid Leave if available and non-zero
    final paidLeave = widget.payrollData['paidLeaveDays']?.toString();
    if (paidLeave != null && paidLeave != '0' && paidLeave.isNotEmpty) {
      fields.add(_buildInfoRow('Paid Leave', paidLeave));
    }
    
    // Show Unpaid Leave if available and non-zero
    final unpaidLeave = widget.payrollData['unpaidLeaveDays']?.toString();
    if (unpaidLeave != null && unpaidLeave != '0' && unpaidLeave.isNotEmpty) {
      fields.add(_buildInfoRow('Unpaid Leave', unpaidLeave));
    }
    
    // Show LOP Days if available and non-zero
    final lopDays = widget.payrollData['lopDays']?.toString();
    if (lopDays != null && lopDays != '0' && lopDays.isNotEmpty) {
      fields.add(_buildInfoRow('LOP Days', lopDays));
    }
    
    // Show Payable Days if available
    final payableDays = widget.payrollData['payableDays']?.toString();
    if (payableDays != null && payableDays.isNotEmpty) {
      fields.add(_buildInfoRow('Payable Days', payableDays));
    }
    
    // Show Scheduled Working Days only when calculation method is SCHEDULED_WORKING_DAYS
    final calcMethod = widget.payrollData['salaryCalculationMethod']?.toString() ??
                       widget.payrollData['calculationMethod']?.toString();
    if (calcMethod == 'SCHEDULED_WORKING_DAYS') {
      final scheduledDays = widget.payrollData['scheduledWorkingDays']?.toString();
      if (scheduledDays != null && scheduledDays.isNotEmpty) {
        fields.add(_buildInfoRow('Scheduled Working Days', scheduledDays));
      }
    }
    
    // Show Divisor and Per-Day Salary only when valid values are available
    final divisor = widget.payrollData['divisor']?.toString() ??
                    widget.payrollData['baseDays']?.toString() ??
                    widget.payrollData['salaryDivisor']?.toString();
    if (divisor != null && divisor != 'N/A' && divisor.isNotEmpty) {
      fields.add(_buildInfoRow('Divisor', divisor));
    }
    
    final perDaySalary = widget.payrollData['perDaySalary']?.toString() ??
                         widget.payrollData['dailyRate']?.toString();
    if (perDaySalary != null && perDaySalary != '0' && perDaySalary.isNotEmpty) {
      fields.add(_buildInfoRow('Per-Day Salary', _formatCurrency(perDaySalary)));
    }
    
    if (fields.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Employee & Pay Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...fields,
      ],
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntitlementsTable() {
    // Build list of available entitlement rows
    final rows = <Widget>[];
    
    // Basic Salary - always show
    rows.add(_buildTableRow('Basic Salary', '-', '-', _formatCurrency(widget.payrollData['basicSalary'])));
    
    // HRA - show only when available
    final hra = widget.payrollData['hra'];
    if (hra != null && hra != 0) {
      rows.add(_buildTableRow('HRA', '-', '-', _formatCurrency(hra)));
    }
    
    // Allowances - show only when available
    final allowances = widget.payrollData['totalAllowance'];
    if (allowances != null && allowances != 0) {
      rows.add(_buildTableRow('Allowances', '-', '-', _formatCurrency(allowances)));
    }
    
    // Bonus - show only when available
    final bonus = widget.payrollData['bonus'];
    if (bonus != null && bonus != 0) {
      rows.add(_buildTableRow('Bonus', '-', '-', _formatCurrency(bonus)));
    }
    
    // Overtime - show only when available
    final overtime = widget.payrollData['overtime'];
    if (overtime != null && overtime != 0) {
      rows.add(_buildTableRow('Overtime', '-', '-', _formatCurrency(overtime)));
    }
    
    // Other Earnings - show only when available
    final otherEarnings = widget.payrollData['otherEarnings'];
    if (otherEarnings != null && otherEarnings != 0) {
      rows.add(_buildTableRow('Other Earnings', '-', '-', _formatCurrency(otherEarnings)));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Entitlements',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildTableHeader(['Description', 'Hours/Units', 'Rate', 'Total']),
        ...rows,
        _buildTableTotalRow('Gross Earnings', _formatCurrency(_getGrossSalary(widget.payrollData))),
      ],
    );
  }

  Widget _buildDeductionsTable() {
    // Build list of available deduction rows
    final rows = <Widget>[];
    
    // LOP Deduction - show only when available
    final lopDeduction = widget.payrollData['lopDeduction'];
    if (lopDeduction != null && lopDeduction != 0) {
      rows.add(_buildDeductionTableRow('LOP Deduction', _formatCurrency(lopDeduction)));
    }
    
    // PF - show only when available
    final pf = widget.payrollData['pf'];
    if (pf != null && pf != 0) {
      rows.add(_buildDeductionTableRow('PF', _formatCurrency(pf)));
    }
    
    // ESI - show only when available
    final esi = widget.payrollData['esi'];
    if (esi != null && esi != 0) {
      rows.add(_buildDeductionTableRow('ESI', _formatCurrency(esi)));
    }
    
    // Professional Tax - show only when available
    final profTax = widget.payrollData['professionalTax'];
    if (profTax != null && profTax != 0) {
      rows.add(_buildDeductionTableRow('Professional Tax', _formatCurrency(profTax)));
    }
    
    // TDS - show only when available
    final tds = widget.payrollData['tds'];
    if (tds != null && tds != 0) {
      rows.add(_buildDeductionTableRow('TDS', _formatCurrency(tds)));
    }
    
    // Other Deductions - show only when available
    final otherDeductions = widget.payrollData['otherDeductions'];
    if (otherDeductions != null && otherDeductions != 0) {
      rows.add(_buildDeductionTableRow('Other Deductions', _formatCurrency(otherDeductions)));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Deductions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildTableHeader(['Description', 'Hours/Units', 'Total']),
        ...rows,
        _buildTableTotalRow('Total Deductions', _formatCurrency(widget.payrollData['totalDeductions'])),
      ],
    );
  }

  Widget _buildTableHeader(List<String> headers) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: headers.map((header) {
          final flex = headers.length == 4 ? [3, 2, 2, 2] : [3, 2, 2];
          final index = headers.indexOf(header);
          return Expanded(
            flex: flex[index],
            child: Text(
              header,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTableRow(String description, String hoursUnits, String rate, String total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(description, style: const TextStyle(fontSize: 13, color: Colors.black87))),
          Expanded(flex: 2, child: Text(hoursUnits, style: const TextStyle(fontSize: 13, color: Colors.black87))),
          Expanded(flex: 2, child: Text(rate, style: const TextStyle(fontSize: 13, color: Colors.black87))),
          Expanded(flex: 2, child: Text(total, style: const TextStyle(fontSize: 13, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildDeductionTableRow(String description, String total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(description, style: const TextStyle(fontSize: 13, color: Colors.black87))),
          Expanded(flex: 2, child: Text('-', style: const TextStyle(fontSize: 13, color: Colors.black87))),
          Expanded(flex: 2, child: Text(total, style: const TextStyle(fontSize: 13, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildTableTotalRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetPaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Net Pay',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F8),
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Net Pay',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                _formatCurrency(_getNetSalary(widget.payrollData)),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _downloadPayslip(BuildContext context) async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      final filename = 'Payslip_${_period.monthName}_${_period.year}';
      
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Generating PDF...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

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
        payroll: widget.payrollData,
        companyId: widget.payrollData['companyId']?.toString() ?? 'unknown',
        companyLogoBytes: logoBytes,
        fallbackMonth: widget.fallbackMonth,
        fallbackYear: widget.fallbackYear,
      );
      
      // Save or share using platform-specific method
      await PayslipPdfDownloader.saveOrShare(
        bytes: pdfBytes,
        fileName: filename,
      );

      if (!context.mounted) return;

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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to create or save PDF: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }
}
