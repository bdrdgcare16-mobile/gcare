import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:serv_app/utils/payroll_period_resolver.dart';

class PayslipPdfBuilder {
  // Black-and-white professional palette
  static final PdfColor _black = PdfColors.black;
  static final PdfColor _grey100 = PdfColor.fromInt(0xFFF5F5F5);
  static final PdfColor _grey700 = PdfColor.fromInt(0xFF616161);
  static final PdfColor _textDark = _black;
  static final PdfColor _textMedium = _grey700;
  static final PdfColor _textLight = _grey700;
  static final PdfColor _borderColor = _black;

  // Times-family fonts
  static final pw.Font _fontTimes = pw.Font.times();
  static final pw.Font _fontTimesBold = pw.Font.timesBold();
  static final pw.Font _fontTimesItalic = pw.Font.timesItalic();
  static final pw.Font _fontTimesBoldItalic = pw.Font.timesBoldItalic();

  // Convenience text-style helpers
  static pw.TextStyle _ts(double size,
      {bool bold = false,
      bool italic = false,
      PdfColor? color,
      double letterSpacing = 0}) {
    return pw.TextStyle(
      font: bold
          ? (italic ? _fontTimesBoldItalic : _fontTimesBold)
          : (italic ? _fontTimesItalic : _fontTimes),
      fontSize: size,
      color: color ?? _black,
      letterSpacing: letterSpacing,
    );
  }

  static Future<Uint8List> generatePayslipPdf({
    required Map<String, dynamic> payroll,
    required String companyId,
    Uint8List? companyLogoBytes,
    int? fallbackMonth,
    int? fallbackYear,
    Map<String, dynamic>? onboardingData,
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
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) => [
          _buildHeader(payroll, companyLogoBytes, period),
          pw.SizedBox(height: 16),
          _buildEmployeePayInfo(payroll, period, onboardingData),
          pw.SizedBox(height: 16),
          _buildEarningsDeductionsTables(payroll),
          pw.SizedBox(height: 16),
          _buildNetPaySection(payroll, period),
          pw.SizedBox(height: 20),
          _buildFooter(),
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
    return pw.Column(
      children: [
        // Company name + logo row
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Company logo – unchanged position/size
            pw.SizedBox(
              width: 70,
              height: 70,
              child: companyLogoBytes != null
                  ? pw.Image(
                      pw.MemoryImage(companyLogoBytes),
                      fit: pw.BoxFit.contain,
                    )
                  : pw.Container(
                      width: 70,
                      height: 70,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: _borderColor),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'LOGO',
                          style: _ts(8, bold: true, color: _textLight),
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
                    'MYTH REALITY TECHNOLOGIES PRIVATE LIMITED',
                    style: _ts(14, bold: true, color: _black),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'No: 33, RL Tower,',
                    style: _ts(8, color: _textLight),
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    'Gandhipuram (GH Opposite),',
                    style: _ts(8, color: _textLight),
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    'Thiruvallur - 602 001',
                    style: _ts(8, color: _textLight),
                  ),
                ],
              ),
            ),
            // Spacer to balance the logo on the left
            pw.SizedBox(width: 70),
          ],
        ),
        pw.SizedBox(height: 12),
        // Title bar – bordered, no fill
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _black),
          ),
          child: pw.Center(
            child: pw.Text(
              'PAYSLIP FOR THE MONTH OF ${period.monthName.toUpperCase()} ${period.year}',
              style: _ts(13, bold: true, color: _black, letterSpacing: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildEmployeePayInfo(
    Map<String, dynamic> payroll,
    PayrollPeriod period,
    Map<String, dynamic>? onboardingData,
  ) {
    final personal =
        onboardingData?['personalDetails'] as Map<String, dynamic>?;
    final company = onboardingData?['companyDetails'] as Map<String, dynamic>?;
    final bank = onboardingData?['bankDetails'] as Map<String, dynamic>?;

    // Left column fields
    final leftFields = <_InfoField>[];

    final fullName = personal?['fullName']?.toString();
    final payrollName = payroll['employeeName']?.toString();
    leftFields.add(_InfoField(
        'Name',
        (fullName != null && fullName.isNotEmpty)
            ? fullName
            : (payrollName ?? '-')));

    leftFields
        .add(_InfoField('Joining Date', _safeText(company?['dateOfJoining'])));
    leftFields
        .add(_InfoField('Designation', _safeText(company?['designation'])));
    leftFields.add(_InfoField('Department', _safeText(company?['department'])));
    leftFields
        .add(_InfoField('Location', _safeText(company?['branchLocation'])));

    // Effective Work Days from payroll
    final workedDays = payroll['workedDays']?.toString() ??
        payroll['presentDays']?.toString() ??
        '0';
    leftFields.add(_InfoField('Effective Work Days', workedDays));

    // LOP from payroll
    final lopDays = payroll['lopDays']?.toString() ?? '0';
    leftFields.add(_InfoField('LOP', lopDays));

    // Right column fields
    final rightFields = <_InfoField>[];

    final employeeId = company?['employeeId']?.toString() ??
        payroll['employeeId']?.toString() ??
        payroll['empid']?.toString() ??
        payroll['employee_id']?.toString();
    rightFields.add(_InfoField('Employee No', employeeId ?? '-'));

    rightFields.add(_InfoField('Bank Name', _safeText(bank?['bankName'])));
    rightFields
        .add(_InfoField('Bank Account No', _safeText(bank?['accountNumber'])));
    rightFields.add(_InfoField('PAN Number', _safeText(bank?['panNumber'])));
    rightFields.add(_InfoField('PF No', _safeText(bank?['pfNumber'])));
    rightFields.add(const _InfoField('PF UAN', '-'));
    rightFields.add(_InfoField('ESI Number', _safeText(bank?['esiNumber'])));

    final payableDays = payroll['payableDays']?.toString() ?? '0';
    rightFields.add(_InfoField('Payable Days', payableDays));

    if (leftFields.isEmpty && rightFields.isEmpty) {
      return pw.SizedBox();
    }

    final maxRows = leftFields.length > rightFields.length
        ? leftFields.length
        : rightFields.length;

    final rows = <pw.Widget>[];
    for (int i = 0; i < maxRows; i++) {
      final left = i < leftFields.length ? leftFields[i] : null;
      final right = i < rightFields.length ? rightFields[i] : null;
      rows.add(_buildTwoColumnInfoRow(left, right));
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _black),
      ),
      child: pw.Column(
        children: [
          // Section header
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: _black),
              ),
            ),
            child: pw.Text(
              'Employee & Pay Information',
              style: _ts(11, bold: true, color: _black),
            ),
          ),
          // Two-column rows
          pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(children: rows),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTwoColumnInfoRow(_InfoField? left, _InfoField? right) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left column
          pw.Expanded(
            child: left != null ? _buildInfoCell(left) : pw.SizedBox(),
          ),
          pw.SizedBox(width: 16),
          // Right column
          pw.Expanded(
            child: right != null ? _buildInfoCell(right) : pw.SizedBox(),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoCell(_InfoField field) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 110,
          child: pw.Text(
            field.label,
            style: _ts(9, bold: true, color: _textMedium),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            ': ${field.value ?? 'N/A'}',
            style: _ts(9, color: _textDark),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildEarningsDeductionsTables(
      Map<String, dynamic> payroll) {
    // Build earnings rows – always show all supported rows even when zero
    final earnings = <_TableRow>[];
    earnings.add(
        _TableRow('Basic Salary', _formatCurrency(payroll['basicSalary'])));
    earnings.add(_TableRow('HRA', _formatCurrency(payroll['hra'])));
    earnings.add(
        _TableRow('Allowances', _formatCurrency(payroll['totalAllowance'])));
    earnings.add(_TableRow('Bonus', _formatCurrency(payroll['bonus'])));
    earnings.add(_TableRow('Overtime', _formatCurrency(payroll['overtime'])));
    earnings.add(
        _TableRow('Other Earnings', _formatCurrency(payroll['otherEarnings'])));

    // Build deductions rows – always show all supported rows even when zero
    final deductions = <_TableRow>[];
    deductions.add(
        _TableRow('LOP Deduction', _formatCurrency(payroll['lopDeduction'])));
    deductions.add(_TableRow('PF', _formatCurrency(payroll['pf'])));
    deductions.add(_TableRow('ESI', _formatCurrency(payroll['esi'])));
    deductions.add(_TableRow(
        'Professional Tax', _formatCurrency(payroll['professionalTax'])));
    deductions.add(_TableRow('TDS', _formatCurrency(payroll['tds'])));
    deductions.add(_TableRow(
        'Other Deductions', _formatCurrency(payroll['otherDeductions'])));

    final grossStr = _formatCurrency(_getGrossSalary(payroll));
    final dedStr = _formatCurrency(payroll['totalDeductions']);

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Earnings table
        pw.Expanded(
          child: _buildBorderedTable(
            'Earnings',
            ['Description', 'Amount'],
            earnings,
            'Gross Earnings',
            grossStr,
          ),
        ),
        pw.SizedBox(width: 12),
        // Deductions table
        pw.Expanded(
          child: _buildBorderedTable(
            'Deductions',
            ['Description', 'Amount'],
            deductions,
            'Total Deductions',
            dedStr,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildBorderedTable(
    String title,
    List<String> headers,
    List<_TableRow> rows,
    String totalLabel,
    String totalValue,
  ) {
    final children = <pw.Widget>[];

    // Section title
    children.add(
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: _black),
          ),
        ),
        child: pw.Text(
          title,
          style: _ts(10, bold: true, color: _black),
        ),
      ),
    );

    // Column header row – thin line below, light grey background
    children.add(
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: pw.BoxDecoration(
          color: _grey100,
          border: pw.Border(
            bottom: pw.BorderSide(color: _black, width: 0.5),
          ),
        ),
        child: pw.Row(
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Text(
                headers[0],
                style: _ts(8, bold: true, color: _black),
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                headers[1],
                style: _ts(8, bold: true, color: _black),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );

    // Data rows – no individual cell boxes, no alternating fill
    for (final row in rows) {
      children.add(
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  row.description,
                  style: _ts(9, color: _textDark),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  row.amount,
                  style: _ts(9, color: _textDark),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Total row – thin line above and below, no side borders
    children.add(
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: _black, width: 0.5),
            bottom: pw.BorderSide(color: _black, width: 0.5),
          ),
        ),
        child: pw.Row(
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Text(
                totalLabel,
                style: _ts(9, bold: true, color: _black),
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                totalValue,
                style: _ts(9, bold: true, color: _black),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
  }

  static pw.Widget _buildNetPaySection(
    Map<String, dynamic> payroll,
    PayrollPeriod period,
  ) {
    final netPayStr = _formatCurrency(_getNetSalary(payroll));
    final netPayAmount = double.tryParse(_getNetSalary(payroll)) ?? 0;
    final amountInWords = _amountToWords(netPayAmount);

    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _black),
      ),
      child: pw.Column(
        children: [
          pw.Padding(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'NET PAY FOR THE MONTH',
                  style: _ts(12, bold: true, color: _black, letterSpacing: 0.5),
                ),
                pw.Text(
                  netPayStr,
                  style: _ts(18, bold: true, color: _black),
                ),
              ],
            ),
          ),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: _black),
              ),
            ),
            child: pw.Center(
              child: pw.Text(
                '($amountInWords)',
                style: _ts(9, italic: true, color: _textLight),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(color: _black, thickness: 0.5),
        pw.SizedBox(height: 8),
        pw.Text(
          'This is a system generated payslip and does not require signature.',
          style: _ts(8, italic: true, color: _textLight),
        ),
      ],
    );
  }

  // Helper methods
  static String _safeText(dynamic value) {
    final str = value?.toString().trim();
    if (str == null || str.isEmpty) return '-';
    return str;
  }

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

  static String _amountToWords(double amount) {
    final rupees = amount.truncate();
    final paise = ((amount - rupees) * 100).round();

    final rupeesStr = _convertNumberToWords(rupees);
    final paiseStr = paise > 0 ? _convertNumberToWords(paise) : '';

    String result = 'Rupees $rupeesStr';
    if (paise > 0) {
      result += ' and $paiseStr Paise';
    }
    result += ' Only';
    return result;
  }

  static String _convertNumberToWords(int n) {
    if (n == 0) return 'Zero';

    final ones = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen'
    ];
    final tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety'
    ];

    String twoDigits(int num) {
      if (num < 20) return ones[num];
      return '${tens[num ~/ 10]} ${ones[num % 10]}'.trim();
    }

    String threeDigits(int num) {
      final h = num ~/ 100;
      final r = num % 100;
      String result = '';
      if (h > 0) result += '${ones[h]} Hundred';
      if (r > 0) {
        result += result.isNotEmpty ? ' ${twoDigits(r)}' : twoDigits(r);
      }
      return result;
    }

    String result = '';
    final crore = n ~/ 10000000;
    n %= 10000000;
    final lakh = n ~/ 100000;
    n %= 100000;
    final thousand = n ~/ 1000;
    n %= 1000;
    final hundred = n;

    if (crore > 0) {
      result += '${threeDigits(crore)} Crore';
    }
    if (lakh > 0) {
      result += result.isNotEmpty
          ? ' ${threeDigits(lakh)} Lakh'
          : '${threeDigits(lakh)} Lakh';
    }
    if (thousand > 0) {
      result += result.isNotEmpty
          ? ' ${threeDigits(thousand)} Thousand'
          : '${threeDigits(thousand)} Thousand';
    }
    if (hundred > 0) {
      result +=
          result.isNotEmpty ? ' ${threeDigits(hundred)}' : threeDigits(hundred);
    }

    return result.trim();
  }
}

class _InfoField {
  final String label;
  final String? value;
  const _InfoField(this.label, this.value);
}

class _TableRow {
  final String description;
  final String amount;
  const _TableRow(this.description, this.amount);
}
