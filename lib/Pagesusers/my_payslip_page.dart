import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'payslip_model.dart';

// Theme colors
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

class MyPayslipPage extends StatefulWidget {
  final String employee;
  
  const MyPayslipPage({super.key, required this.employee});

  @override
  State<MyPayslipPage> createState() => _MyPayslipPageState();
}

class _MyPayslipPageState extends State<MyPayslipPage> {
  late List<Payslip> _all;
  List<Payslip> _filtered = [];

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  static const int _yearOtherValue = -1;

  @override
  void initState() {
    super.initState();
    _all = PayslipDataSource.samplePayslips();
    _applyFilter();
  }

  void _applyFilter() {
    final match = _all
        .where((p) => p.month == _selectedMonth && p.year == _selectedYear)
        .toList();

    setState(() {
      _filtered = match.isNotEmpty ? match : List.from(_all);
    });
  }

  String _ymd(DateTime d) => d.toLocal().toString().split(' ').first;

  int _getTotalDaysInMonth(int month, int year) {
    return DateTime(year, month + 1, 0).day;
  }

  Future<void> _pickCustomYear() async {
    final ctrl = TextEditingController(text: _selectedYear.toString());
    final res = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enter Year"),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: "e.g., 2026",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kButtonColor),
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              if (v == null || v < 2000 || v > 2100) return;
              Navigator.pop(context, v);
            },
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (res != null) setState(() => _selectedYear = res);
  }

  // ---------------- PDF (MR TECH layout) ----------------
  Future<Uint8List> _buildPayslipPdf(Payslip p) async {
    final doc = pw.Document();

    final border = PdfColor.fromInt(0xFFE0E0E0);
    final textGrey = PdfColor.fromInt(0xFF666666);
    final netPayBg = PdfColor.fromInt(0xFFE8F5E8);
    final headerBg = PdfColor.fromInt(0xFFF8F9FA);
    final totalBarBg = PdfColor.fromInt(0xFFF2F2F2);

    // No ₹ => avoids "box" + no font asset needed
    String rs0(num v) => 'Rs. ${v.toStringAsFixed(0)}';

    pw.Widget card({required pw.Widget child}) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: border, width: 1),
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: child,
      );
    }

    pw.Widget kv(String k, String v) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                k,
                style: pw.TextStyle(fontSize: 9, color: textGrey),
              ),
            ),
            pw.Text(v, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      );
    }

    pw.Widget rowItem(String label, String value, {bool boldRow = false}) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: border, width: 0.5),
          color: boldRow ? headerBg : null,
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight:
                    boldRow ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight:
                    boldRow ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(22),
        build: (_) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        p.companyName,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        p.companySubTitle,
                        style: pw.TextStyle(fontSize: 9, color: textGrey),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Payslip For the Month',
                        style: pw.TextStyle(fontSize: 9, color: textGrey),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${p.year}-${p.month.toString().padLeft(2, '0')}',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 14),

              // Employee summary + Net Pay box
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 7,
                    child: card(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'EMPLOYEE SUMMARY',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          kv('Employee Name', p.employeeName),
                           kv('Employee ID', p.employeeId),
                           kv('Department', p.department),
                          kv('Designation', p.designation),
                         
                          // kv('Date of Joining', _ymd(p.dateOfJoining)),

                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(14),
                      decoration: pw.BoxDecoration(
                        color: netPayBg,
                        border: pw.Border.all(color: border, width: 1),
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Net Pay',
                            style: pw.TextStyle(fontSize: 9, color: textGrey),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Text(
                            rs0(p.netPay),
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'Employee Net Pay',
                            style: pw.TextStyle(fontSize: 9, color: textGrey),
                          ),
                          pw.SizedBox(height: 10),

                          // Total Days + Worked Days + Per Day Salary inside box
                          pw.Container(height: 1, color: border),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            'Total Days: ${_getTotalDaysInMonth(p.month, p.year)}',
                            style: pw.TextStyle(fontSize: 9, color: textGrey),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Worked Days: ${p.paidDays} / ${_getTotalDaysInMonth(p.month, p.year)}',
                            style: pw.TextStyle(fontSize: 9, color: textGrey),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Per Day Salary: Rs. ${(p.netPay / _getTotalDaysInMonth(p.month, p.year)).toStringAsFixed(0)}',
                            style: pw.TextStyle(fontSize: 9, color: textGrey),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'LOP Days: ${p.lopDays}',
                            style: pw.TextStyle(fontSize: 9, color: textGrey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 14),

              // Earnings + Deductions
              card(
                child: pw.Column(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      decoration: pw.BoxDecoration(
                        color: headerBg,
                        border: pw.Border.all(color: border, width: 0.5),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              'EARNINGS',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 20),
                          pw.Expanded(
                            child: pw.Align(
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text(
                                'DEDUCTIONS',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              rowItem('Basic', rs0(p.basic)),
                              rowItem('House Rent Allowance', rs0(p.hra)),
                              rowItem('Allowances', rs0(p.allowance)),
                              rowItem('Bonus', rs0(p.bonus)),
                              rowItem(
                                'Gross Earnings',
                                rs0(p.grossEarnings),
                                boldRow: true,
                              ),
                            ],
                          ),
                        ),
                        pw.Container(width: 1, height: 155, color: border),
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              rowItem('Deductions', rs0(p.deductions)),
                              rowItem('Professional Tax', rs0(p.professionalTax)),
                              rowItem(
                                'Total Deductions',
                                rs0(p.totalDeductions),
                                boldRow: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // TOTAL NET PAYABLE bar
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: pw.BoxDecoration(
                  color: totalBarBg,
                  border: pw.Border.all(color: border, width: 1),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL NET PAYABLE',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      rs0(p.netPay),
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // Preview screen (Web stable)
  Future<void> _openPreview(Payslip p) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PayslipPreviewPage(
          title: 'Payslip - ${p.monthName} ${p.year}',
          fileName: 'Payslip_${p.monthName}_${p.year}.pdf',
          buildPdf: () => _buildPayslipPdf(p),
        ),
      ),
    );
  }

  // Download/Share
  Future<void> _downloadPayslip(Payslip p) async {
    final bytes = await _buildPayslipPdf(p);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Payslip_${p.monthName}_${p.year}.pdf',
    );
  }

  Future<void> _viewPayslip(Payslip p) async {
    showDialog(
      context: context,
      builder: (_) => SizedBox(
        width: 350,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE6E6FA), width: 2),
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          title: const SizedBox(
            width: double.infinity,
            child: Text(
              'Payslip Details',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Employee Name:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(p.employeeName),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              
              Row(
                children: [
                  const Text(
                    'Employee ID:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(p.employeeId),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              
              Row(
                children: [
                  const Text(
                    'Department:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(p.department),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              
              Row(
                children: [
                  const Text(
                    'Worked Days:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${p.paidDays} / ${_getTotalDaysInMonth(p.month, p.year)}'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              
              Row(
                children: [
                  const Text(
                    'Deductions:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Rs. ${p.totalDeductions.toStringAsFixed(0)}'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Container(
                width: double.infinity,
                height: 1,
                color: const Color(0xFFE6E6FA),
                margin: const EdgeInsets.symmetric(vertical: 8),
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  const Text(
                    'Net Pay:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rs. ${p.netPay.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kButtonColor),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _openPreview(p);
                  },
                  child: const Text(
                    'Preview PDF',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final years = PayslipDataSource.yearsRange(start: 2023, end: 2027);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Payslip", style: TextStyle(color: kTextColor)),
        backgroundColor: kAppBarColor,
        iconTheme: const IconThemeData(color: kTextColor),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/payslipbg.png'),
            fit: BoxFit.scaleDown, // Makes image smaller to fit within container
            opacity: 0.3, // Makes background image less visible
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              // Filter card (Responsive)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final isSmall = c.maxWidth < 420;

                    final monthDd = SizedBox(
                      width: isSmall ? double.infinity : 160,
                      child: DropdownButtonFormField<int>(
                        value: _selectedMonth,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Month',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: PayslipDataSource.months()
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(PayslipDataSource.monthName(m)),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedMonth = v ?? _selectedMonth),
                      ),
                    );

                    final yearDd = SizedBox(
                      width: isSmall ? double.infinity : 180,
                      child: DropdownButtonFormField<int>(
                        value: years.contains(_selectedYear)
                            ? _selectedYear
                            : _yearOtherValue,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          ...years.map(
                            (y) => DropdownMenuItem(
                              value: y,
                              child: Text('$y'),
                            ),
                          ),
                          const DropdownMenuItem(
                            value: _yearOtherValue,
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (v) async {
                          if (v == _yearOtherValue) {
                            await _pickCustomYear();
                          } else if (v != null) {
                            setState(() => _selectedYear = v);
                          }
                        },
                      ),
                    );

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [monthDd, yearDd],
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: _filtered.isEmpty
                    ? const Center(child: Text("No payslips available"))
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final p = _filtered[i];
                          return Card(
                            elevation: 2,
                            color: Colors.white.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Payslip - ${PayslipDataSource.monthName(_selectedMonth)} $_selectedYear',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Net Pay: Rs. ${p.netPay.toStringAsFixed(0)}'),
                                  const SizedBox(height: 4),
                                  Text('Total Days: ${_getTotalDaysInMonth(p.month, p.year)} | LOP: ${p.lopDays}'),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      SizedBox(
                                        height: 36,
                                        child: OutlinedButton(
                                          onPressed: () => _viewPayslip(p),
                                          child: const Text('View'),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 36,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: kButtonColor,
                                          ),
                                          onPressed: () => _downloadPayslip(p),
                                          child: const Text(
                                            'Download',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PayslipPreviewPage extends StatelessWidget {
  final String title;
  final Future<Uint8List> Function() buildPdf;
  final String fileName;

  const PayslipPreviewPage({
    super.key,
    required this.title,
    required this.buildPdf,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: kTextColor)),
        backgroundColor: kAppBarColor,
        iconTheme: const IconThemeData(color: kTextColor),

        // ✅ Top right icons removed
        actions: const [],
      ),
      body: PdfPreview(
        build: (_) async => await buildPdf(),

        // ✅ Bottom share/print icons removed
        allowPrinting: false,
        allowSharing: false,

        // ✅ No format / orientation controls
        canChangePageFormat: false,
        canChangeOrientation: false,

        // ✅ No custom actions
        actions: const [],
      ),
    );
  }
}