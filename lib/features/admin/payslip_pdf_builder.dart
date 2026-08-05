import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:serv_app/utils/payroll_period_resolver.dart';
import 'package:serv_app/utils/date_formatter.dart';

class PayslipPdfBuilder {
  static Future<Uint8List> generatePayslipPdf({
    required Map<String, dynamic> payroll,
    required String companyId,
    Uint8List? companyLogoBytes,
    int? fallbackMonth,
    int? fallbackYear,
  }) async {
    final pdf = pw.Document();

    // Resolve payroll period using shared resolver
    final period = resolvePayrollPeriod(
      payroll,
      fallbackMonth: fallbackMonth,
      fallbackYear: fallbackYear,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          _buildHeader(payroll, companyLogoBytes, period),
          pw.SizedBox(height: 24),
          _buildEmployeePayInfo(payroll, period),
          pw.SizedBox(height: 24),
          _buildEntitlementsTable(payroll),
          pw.SizedBox(height: 24),
          _buildDeductionsTable(payroll),
          pw.SizedBox(height: 24),
          _buildNetPaySection(payroll, period),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
    Map<String, dynamic> payroll,
    Uint8List? companyLogoBytes,
    PayrollPeriod period,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Company logo
        pw.SizedBox(
          width: 80,
          height: 80,
          child: companyLogoBytes != null
              ? pw.Image(
                  pw.MemoryImage(companyLogoBytes),
                  fit: pw.BoxFit.contain,
                )
              : pw.Container(
                  width: 80,
                  height: 80,
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF0F4F8),
                    border: pw.Border.all(color: PdfColor.fromInt(0xFFD0D0D0)),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'COMPANY\nLOGO',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColor.fromInt(0xFF808080),
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ),
        ),
        pw.SizedBox(width: 16),
        // Company information
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'PAYSLIP',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Myth Reality Technologies Pvt. Ltd.',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF333333),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                period.toString(),
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColor.fromInt(0xFF666666),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildEmployeePayInfo(
    Map<String, dynamic> payroll,
    PayrollPeriod period,
  ) {
    // Build list of available fields
    final fields = <pw.Widget>[];
    
    // Always show Employee Name
    fields.add(_buildInfoRow('Employee Name', payroll['employeeName']));
    
    // Show Employee ID if available
    final employeeId = payroll['employeeId']?.toString() ??
                      payroll['empid']?.toString() ??
                      payroll['employee_id']?.toString();
    if (employeeId != null && employeeId.isNotEmpty) {
      fields.add(_buildInfoRow('Employee ID', employeeId));
    }
    
    // Show Payment Status
    fields.add(_buildInfoRow('Payment Status', _getPaymentStatus(payroll)));
    
    // Show Paid Date only when status is paid
    final paymentStatus = payroll['paymentStatus']?.toString() ??
                          payroll['status']?.toString();
    final isPaid = paymentStatus?.toLowerCase() == 'paid' || payroll['isPaid'] == true;
    if (isPaid) {
      fields.add(_buildInfoRow('Paid Date', formatPayrollDateFromDynamic(payroll['paidAt'])));
    }
    
    // Show Worked Days if available and non-zero
    final workedDays = payroll['workedDays']?.toString() ??
                       payroll['presentDays']?.toString();
    if (workedDays != null && workedDays != '0' && workedDays.isNotEmpty) {
      fields.add(_buildInfoRow('Worked Days', workedDays));
    }
    
    // Show Paid Weekly Off if available and non-zero
    final weekOffDays = payroll['weekOffDays']?.toString() ??
                        payroll['paidWeeklyOffDays']?.toString() ??
                        payroll['paidWeeklyOff']?.toString();
    if (weekOffDays != null && weekOffDays != '0' && weekOffDays.isNotEmpty) {
      fields.add(_buildInfoRow('Paid Weekly Off', weekOffDays));
    }
    
    // Show Paid Leave if available and non-zero
    final paidLeave = payroll['paidLeaveDays']?.toString();
    if (paidLeave != null && paidLeave != '0' && paidLeave.isNotEmpty) {
      fields.add(_buildInfoRow('Paid Leave', paidLeave));
    }
    
    // Show Unpaid Leave if available and non-zero
    final unpaidLeave = payroll['unpaidLeaveDays']?.toString();
    if (unpaidLeave != null && unpaidLeave != '0' && unpaidLeave.isNotEmpty) {
      fields.add(_buildInfoRow('Unpaid Leave', unpaidLeave));
    }
    
    // Show LOP Days if available and non-zero
    final lopDays = payroll['lopDays']?.toString();
    if (lopDays != null && lopDays != '0' && lopDays.isNotEmpty) {
      fields.add(_buildInfoRow('LOP Days', lopDays));
    }
    
    // Show Payable Days if available
    final payableDays = payroll['payableDays']?.toString();
    if (payableDays != null && payableDays.isNotEmpty) {
      fields.add(_buildInfoRow('Payable Days', payableDays));
    }
    
    // Show Scheduled Working Days only when calculation method is SCHEDULED_WORKING_DAYS
    final calcMethod = payroll['salaryCalculationMethod']?.toString() ??
                       payroll['calculationMethod']?.toString();
    if (calcMethod == 'SCHEDULED_WORKING_DAYS') {
      final scheduledDays = payroll['scheduledWorkingDays']?.toString();
      if (scheduledDays != null && scheduledDays.isNotEmpty) {
        fields.add(_buildInfoRow('Scheduled Working Days', scheduledDays));
      }
    }
    
    // Show Divisor and Per-Day Salary only when valid values are available
    final divisor = payroll['divisor']?.toString() ??
                    payroll['baseDays']?.toString() ??
                    payroll['salaryDivisor']?.toString();
    if (divisor != null && divisor != 'N/A' && divisor.isNotEmpty) {
      fields.add(_buildInfoRow('Divisor', divisor));
    }
    
    final perDaySalary = payroll['perDaySalary']?.toString() ??
                         payroll['dailyRate']?.toString();
    if (perDaySalary != null && perDaySalary != '0' && perDaySalary.isNotEmpty) {
      fields.add(_buildInfoRow('Per-Day Salary', _formatCurrency(perDaySalary)));
    }
    
    if (fields.isEmpty) {
      return pw.SizedBox();
    }
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF0F4F8),
          ),
          child: pw.Text(
            'Employee & Pay Information',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF333333),
            ),
          ),
        ),
        pw.SizedBox(height: 12),
        ...fields,
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, dynamic value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF666666),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value?.toString() ?? 'N/A',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColor.fromInt(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildEntitlementsTable(Map<String, dynamic> payroll) {
    // Build list of available entitlement rows
    final rows = <pw.Widget>[];
    
    // Basic Salary - always show
    rows.add(_buildTableRow('Basic Salary', '-', '-', _formatCurrency(payroll['basicSalary'])));
    
    // HRA - show only when available
    final hra = payroll['hra'];
    if (hra != null && hra != 0) {
      rows.add(_buildTableRow('HRA', '-', '-', _formatCurrency(hra)));
    }
    
    // Allowances - show only when available
    final allowances = payroll['totalAllowance'];
    if (allowances != null && allowances != 0) {
      rows.add(_buildTableRow('Allowances', '-', '-', _formatCurrency(allowances)));
    }
    
    // Bonus - show only when available
    final bonus = payroll['bonus'];
    if (bonus != null && bonus != 0) {
      rows.add(_buildTableRow('Bonus', '-', '-', _formatCurrency(bonus)));
    }
    
    // Overtime - show only when available
    final overtime = payroll['overtime'];
    if (overtime != null && overtime != 0) {
      rows.add(_buildTableRow('Overtime', '-', '-', _formatCurrency(overtime)));
    }
    
    // Other Earnings - show only when available
    final otherEarnings = payroll['otherEarnings'];
    if (otherEarnings != null && otherEarnings != 0) {
      rows.add(_buildTableRow('Other Earnings', '-', '-', _formatCurrency(otherEarnings)));
    }
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF0F4F8),
          ),
          child: pw.Text(
            'Entitlements',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF333333),
            ),
          ),
        ),
        pw.SizedBox(height: 12),
        _buildTableHeader(['Description', 'Hours/Units', 'Rate', 'Total']),
        ...rows,
        _buildTableTotalRow('Gross Earnings', _formatCurrency(_getGrossSalary(payroll))),
      ],
    );
  }

  static pw.Widget _buildDeductionsTable(Map<String, dynamic> payroll) {
    // Build list of available deduction rows
    final rows = <pw.Widget>[];
    
    // LOP Deduction - show only when available
    final lopDeduction = payroll['lopDeduction'];
    if (lopDeduction != null && lopDeduction != 0) {
      rows.add(_buildDeductionTableRow('LOP Deduction', _formatCurrency(lopDeduction)));
    }
    
    // PF - show only when available
    final pf = payroll['pf'];
    if (pf != null && pf != 0) {
      rows.add(_buildDeductionTableRow('PF', _formatCurrency(pf)));
    }
    
    // ESI - show only when available
    final esi = payroll['esi'];
    if (esi != null && esi != 0) {
      rows.add(_buildDeductionTableRow('ESI', _formatCurrency(esi)));
    }
    
    // Professional Tax - show only when available
    final profTax = payroll['professionalTax'];
    if (profTax != null && profTax != 0) {
      rows.add(_buildDeductionTableRow('Professional Tax', _formatCurrency(profTax)));
    }
    
    // TDS - show only when available
    final tds = payroll['tds'];
    if (tds != null && tds != 0) {
      rows.add(_buildDeductionTableRow('TDS', _formatCurrency(tds)));
    }
    
    // Other Deductions - show only when available
    final otherDeductions = payroll['otherDeductions'];
    if (otherDeductions != null && otherDeductions != 0) {
      rows.add(_buildDeductionTableRow('Other Deductions', _formatCurrency(otherDeductions)));
    }
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF0F4F8),
          ),
          child: pw.Text(
            'Deductions',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF333333),
            ),
          ),
        ),
        pw.SizedBox(height: 12),
        _buildTableHeader(['Description', 'Hours/Units', 'Total']),
        ...rows,
        _buildTableTotalRow('Total Deductions', _formatCurrency(payroll['totalDeductions'])),
      ],
    );
  }

  static pw.Widget _buildTableHeader(List<String> headers) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF0F4F8),
        border: pw.Border.all(color: PdfColor.fromInt(0xFFD0D0D0)),
      ),
      child: pw.Row(
        children: headers.map((header) {
          final flex = headers.length == 4 ? [3, 2, 2, 2] : [3, 2, 2];
          final index = headers.indexOf(header);
          return pw.Expanded(
            flex: flex[index],
            child: pw.Text(
              header,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF333333),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  static pw.Widget _buildTableRow(String description, String hoursUnits, String rate, String total) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromInt(0xFFE0E0E0)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(flex: 3, child: pw.Text(description, style: pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0xFF333333)))),
          pw.Expanded(flex: 2, child: pw.Text(hoursUnits, style: pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0xFF333333)))),
          pw.Expanded(flex: 2, child: pw.Text(rate, style: pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0xFF333333)))),
          pw.Expanded(flex: 2, child: pw.Text(total, style: pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0xFF333333)))),
        ],
      ),
    );
  }

  static pw.Widget _buildDeductionTableRow(String description, String total) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromInt(0xFFE0E0E0)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(flex: 3, child: pw.Text(description, style: pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0xFF333333)))),
          pw.Expanded(flex: 2, child: pw.Text('-', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0xFF333333)))),
          pw.Expanded(flex: 2, child: pw.Text(total, style: pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0xFF333333)))),
        ],
      ),
    );
  }

  static pw.Widget _buildTableTotalRow(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF0F4F8),
        border: pw.Border.all(color: PdfColor.fromInt(0xFFD0D0D0)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF333333),
              ),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF333333),
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildNetPaySection(
    Map<String, dynamic> payroll,
    PayrollPeriod period,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF0F4F8),
          ),
          child: pw.Text(
            'Net Pay',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF333333),
            ),
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF0F4F8),
            border: pw.Border.all(color: PdfColor.fromInt(0xFFB0B0B0)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total Net Pay',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF333333),
                ),
              ),
              pw.Text(
                _formatCurrency(_getNetSalary(payroll)),
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper methods
  static String _formatCurrency(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '0') ?? 0;
    return 'Rs. ${NumberFormat("#,##0.00", "en_IN").format(amount)}';
  }

  static String _getGrossSalary(Map<String, dynamic> payroll) {
    return payroll['grossSalary']?.toString() ??
           payroll['grossEarnings']?.toString() ??
           payroll['monthlySalary']?.toString() ??
           '0';
  }

  static String _getNetSalary(Map<String, dynamic> payroll) {
    return payroll['netSalary']?.toString() ??
           payroll['salary']?.toString() ??
           payroll['finalSalary']?.toString() ??
           '0';
  }

  static String _getPaymentStatus(Map<String, dynamic> payroll) {
    final status = payroll['paymentStatus']?.toString() ??
                   payroll['status']?.toString() ??
                   (payroll['isPaid'] == true ? 'paid' : 'pending');
    
    // Normalize to title case
    if (status.toLowerCase() == 'paid') return 'Paid';
    if (status.toLowerCase() == 'pending') return 'Pending';
    return status;
  }
}
