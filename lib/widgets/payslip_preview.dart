import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:serv_app/features/admin/payslip_pdf_builder.dart';
import 'package:serv_app/services/api_service.dart';
import 'package:serv_app/utils/payroll_period_resolver.dart';
import 'package:serv_app/utils/payslip_pdf_downloader.dart';

// Black-and-white professional palette
const Color _kBlack = Colors.black;
const Color _kGrey100 = Color(0xFFF5F5F5);
const Color _kGrey200 = Color(0xFFE0E0E0);
const Color _kGrey700 = Color(0xFF616161);
const Color _kTextDark = _kBlack;
const Color _kTextMedium = _kGrey700;
const Color _kTextLight = _kGrey700;
const Color _kBorderColor = _kBlack;
const Color _kRowAltColor = _kGrey100;

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
  Map<String, dynamic>? _onboardingData;

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Unable to identify the payroll period for this payslip.'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
      });
      _period = const PayrollPeriod(
        month: 1,
        year: 2000,
        monthName: 'Unknown',
      );
    }
    _fetchOnboardingData();
  }

  Future<void> _fetchOnboardingData() async {
    final empid = widget.payrollData['employeeId']?.toString() ??
        widget.payrollData['empid']?.toString() ??
        widget.payrollData['employee_id']?.toString();

    if (empid == null || empid.isEmpty || empid == 'N/A') {
      return;
    }

    try {
      final data = await ApiService.fetchOnboardingByEmpId(empid);
      if (mounted) {
        setState(() {
          _onboardingData = data;
        });
      }
    } catch (_) {}
  }

  String _safeText(dynamic value) {
    final str = value?.toString().trim();
    if (str == null || str.isEmpty) return '-';
    return str;
  }

  String _formatCurrency(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '0') ?? 0;
    return 'Rs. ${NumberFormat("#,##0.00", "en_IN").format(amount)}';
  }

  String _amountToWords(double amount) {
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

  String _convertNumberToWords(int n) {
    if (n == 0) return 'Zero';
    const ones = [
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
    const tens = [
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
      backgroundColor: _kGrey100,
      appBar: AppBar(
        backgroundColor: _kBlack,
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
                    color: Colors.grey.withValues(alpha: 0.15),
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
                    const SizedBox(height: 16),
                    _buildEmployeePayInfo(),
                    const SizedBox(height: 16),
                    _buildEarningsDeductionsTables(),
                    const SizedBox(height: 16),
                    _buildNetPaySection(),
                    const SizedBox(height: 20),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isDownloading ? null : () => _downloadPayslip(context),
        backgroundColor: _kBlack,
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
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: Image.asset(
                'assets/images/myth_reality_tech_logo.jpeg',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      border: Border.all(color: _kBorderColor),
                    ),
                    child: const Center(
                      child: Text(
                        'LOGO',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: _kTextLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'MYTH REALITY TECHNOLOGIES PVT. LTD.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _kBlack,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'SERV Payroll Management System',
                    style: TextStyle(
                      fontSize: 11,
                      color: _kTextLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 70),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: _kBlack),
          ),
          child: Center(
            child: Text(
              'PAYSLIP FOR THE MONTH OF ${_period.monthName.toUpperCase()} ${_period.year}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _kBlack,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeePayInfo() {
    final personal =
        _onboardingData?['personalDetails'] as Map<String, dynamic>?;
    final company = _onboardingData?['companyDetails'] as Map<String, dynamic>?;
    final bank = _onboardingData?['bankDetails'] as Map<String, dynamic>?;

    // Left column – employee master info from onboarding
    final leftFields = <_InfoField>[];

    final fullName = personal?['fullName']?.toString();
    final payrollName = widget.payrollData['employeeName']?.toString();
    leftFields.add(_InfoField(
        'Employee Name',
        (fullName != null && fullName.isNotEmpty)
            ? fullName
            : (payrollName ?? '-')));

    final employeeId = company?['employeeId']?.toString() ??
        widget.payrollData['employeeId']?.toString() ??
        widget.payrollData['empid']?.toString() ??
        widget.payrollData['employee_id']?.toString();
    leftFields.add(_InfoField('Employee ID', employeeId ?? '-'));

    leftFields
        .add(_InfoField('Joining Date', _safeText(company?['dateOfJoining'])));
    leftFields
        .add(_InfoField('Designation', _safeText(company?['designation'])));
    leftFields.add(_InfoField('Department', _safeText(company?['department'])));
    leftFields
        .add(_InfoField('Location', _safeText(company?['branchLocation'])));
    leftFields.add(_InfoField('Payment Status', _getPaymentStatus()));

    final paymentStatus = widget.payrollData['paymentStatus']?.toString() ??
        widget.payrollData['status']?.toString();
    final isPaid = paymentStatus?.toLowerCase() == 'paid' ||
        widget.payrollData['isPaid'] == true;
    if (isPaid) {
      leftFields.add(
          _InfoField('Paid Date', widget.payrollData['paidDate']?.toString()));
    }

    // Right column – bank/statutory info from onboarding + attendance from payroll
    final rightFields = <_InfoField>[];
    rightFields.add(_InfoField('Bank Name', _safeText(bank?['bankName'])));
    rightFields
        .add(_InfoField('Bank Account No', _safeText(bank?['accountNumber'])));
    rightFields.add(_InfoField('PAN Number', _safeText(bank?['panNumber'])));
    rightFields.add(_InfoField('PF Number', _safeText(bank?['pfNumber'])));
    rightFields.add(const _InfoField('PF UAN', '-'));
    rightFields.add(_InfoField('ESI Number', _safeText(bank?['esiNumber'])));
    rightFields.add(_InfoField(
        'Payable Days', widget.payrollData['payableDays']?.toString() ?? '0'));
    rightFields.add(_InfoField(
        'LOP Days', widget.payrollData['lopDays']?.toString() ?? '0'));

    if (leftFields.isEmpty && rightFields.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxRows = leftFields.length > rightFields.length
        ? leftFields.length
        : rightFields.length;
    final rows = <Widget>[];
    for (int i = 0; i < maxRows; i++) {
      final left = i < leftFields.length ? leftFields[i] : null;
      final right = i < rightFields.length ? rightFields[i] : null;
      rows.add(_buildTwoColumnInfoRow(left, right));
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _kBlack),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _kBlack),
              ),
            ),
            child: const Text(
              'Employee & Pay Information',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _kBlack,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoColumnInfoRow(_InfoField? left, _InfoField? right) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: left != null ? _buildInfoCell(left) : const SizedBox(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: right != null ? _buildInfoCell(right) : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCell(_InfoField field) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            field.label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _kTextMedium,
            ),
          ),
        ),
        Expanded(
          child: Text(
            ': ${field.value ?? 'N/A'}',
            style: const TextStyle(
              fontSize: 11,
              color: _kTextDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsDeductionsTables() {
    final earnings = <_TableRowData>[];
    earnings.add(_TableRowData(
        'Basic Salary', _formatCurrency(widget.payrollData['basicSalary'])));
    earnings
        .add(_TableRowData('HRA', _formatCurrency(widget.payrollData['hra'])));
    earnings.add(_TableRowData(
        'Allowances', _formatCurrency(widget.payrollData['totalAllowance'])));
    earnings.add(
        _TableRowData('Bonus', _formatCurrency(widget.payrollData['bonus'])));
    earnings.add(_TableRowData(
        'Overtime', _formatCurrency(widget.payrollData['overtime'])));
    earnings.add(_TableRowData('Other Earnings',
        _formatCurrency(widget.payrollData['otherEarnings'])));

    final deductions = <_TableRowData>[];
    deductions.add(_TableRowData(
        'LOP Deduction', _formatCurrency(widget.payrollData['lopDeduction'])));
    deductions
        .add(_TableRowData('PF', _formatCurrency(widget.payrollData['pf'])));
    deductions
        .add(_TableRowData('ESI', _formatCurrency(widget.payrollData['esi'])));
    deductions.add(_TableRowData('Professional Tax',
        _formatCurrency(widget.payrollData['professionalTax'])));
    deductions
        .add(_TableRowData('TDS', _formatCurrency(widget.payrollData['tds'])));
    deductions.add(_TableRowData('Other Deductions',
        _formatCurrency(widget.payrollData['otherDeductions'])));

    final grossStr = _formatCurrency(_getGrossSalary(widget.payrollData));
    final dedStr = _formatCurrency(widget.payrollData['totalDeductions']);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildBorderedTable(
            'Earnings',
            earnings,
            'Gross Earnings',
            grossStr,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBorderedTable(
            'Deductions',
            deductions,
            'Total Deductions',
            dedStr,
          ),
        ),
      ],
    );
  }

  Widget _buildBorderedTable(
    String title,
    List<_TableRowData> rows,
    String totalLabel,
    String totalValue,
  ) {
    final children = <Widget>[];

    children.add(
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: _kBlack),
          ),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: _kBlack,
          ),
        ),
      ),
    );

    children.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: const BoxDecoration(
          color: _kGrey100,
          border: Border(
            bottom: BorderSide(color: _kBlack),
          ),
        ),
        child: const Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                'Description',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _kBlack,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Amount',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _kBlack,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );

    if (rows.isEmpty) {
      children.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: _kBlack),
              right: BorderSide(color: _kBlack),
              bottom: BorderSide(color: _kBlack),
            ),
          ),
          child: const Text(
            'Nil',
            style: TextStyle(fontSize: 10, color: _kTextLight),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      for (int i = 0; i < rows.length; i++) {
        final isAlt = i % 2 == 1;
        children.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isAlt ? _kRowAltColor : null,
              border: Border(
                left: BorderSide(color: _kBlack),
                right: BorderSide(color: _kBlack),
                bottom: i == rows.length - 1
                    ? BorderSide.none
                    : BorderSide(color: _kGrey200, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    rows[i].description,
                    style: const TextStyle(fontSize: 10, color: _kTextDark),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    rows[i].amount,
                    style: const TextStyle(fontSize: 10, color: _kTextDark),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    children.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: _kBlack),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                totalLabel,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _kBlack,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                totalValue,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _kBlack,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildNetPaySection() {
    final netPayStr = _formatCurrency(_getNetSalary(widget.payrollData));
    final netPayAmount =
        double.tryParse(_getNetSalary(widget.payrollData)) ?? 0;
    final amountInWords = _amountToWords(netPayAmount);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: _kBlack),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'NET PAY FOR THE MONTH',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _kBlack,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  netPayStr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _kBlack,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: _kBlack),
              ),
            ),
            child: Center(
              child: Text(
                '($amountInWords)',
                style: const TextStyle(
                  fontSize: 10,
                  color: _kTextLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: _kBlack, thickness: 0.5),
        const SizedBox(height: 8),
        const Text(
          'This is a system generated payslip and does not require signature.',
          style: TextStyle(
            fontSize: 9,
            color: _kTextLight,
            fontStyle: FontStyle.italic,
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
        final logoData =
            await rootBundle.load('assets/images/myth_reality_tech_logo.jpeg');
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
        onboardingData: _onboardingData,
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

class _InfoField {
  final String label;
  final String? value;
  const _InfoField(this.label, this.value);
}

class _TableRowData {
  final String description;
  final String amount;
  const _TableRowData(this.description, this.amount);
}
