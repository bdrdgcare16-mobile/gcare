import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class AdminPayrollDetailScreen extends StatefulWidget {
  final Map<String, dynamic> employee;

  const AdminPayrollDetailScreen({super.key, required this.employee});

  @override
  State<AdminPayrollDetailScreen> createState() => _AdminPayrollDetailScreenState();
}

class _AdminPayrollDetailScreenState extends State<AdminPayrollDetailScreen> {
  late Map<String, dynamic> payroll;

  @override
  void initState() {
    super.initState();
    payroll = {
      'basic': 40000,
      'allowances': 8000,
      'deductions': 3000,
      'bonus': 5000,
      'netPay': widget.employee['netPay'],
    };
  }

  void _showEditPayrollForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: _EditPayrollForm(
          payroll: payroll,
          onSave: (updatedPayroll) {
            setState(() {
              payroll = updatedPayroll;
              widget.employee['netPay'] = updatedPayroll['netPay'];
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.employee['name']} Payroll'),
        backgroundColor: const Color.fromARGB(255, 152, 180, 243),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: () async {
              await _exportPayslipPDF(context, widget.employee, payroll);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Employee ID: ${widget.employee['id']}',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Department: ${widget.employee['department']}'),
                Divider(height: 24),
                _payRow('Basic Salary', payroll['basic']),
                _payRow('Allowances', payroll['allowances']),
                _payRow('Bonus', payroll['bonus']),
                _payRow('Deductions', -payroll['deductions']),
                Divider(height: 24),
                _payRow('Net Pay', payroll['netPay'], isTotal: true),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: Icon(Icons.edit),
                  label: Text('Edit Payroll'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 152, 180, 243),
                  ),
                  onPressed: _showEditPayrollForm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _payRow(String label, int amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTotal ? 18 : 16)),
          Text(
            '₹${amount >= 0 ? amount : '-${-amount}'}',
            style: TextStyle(
              color: amount < 0 ? Colors.red : Colors.black,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditPayrollForm extends StatefulWidget {
  final Map<String, dynamic> payroll;
  final Function(Map<String, dynamic>) onSave;
  const _EditPayrollForm({required this.payroll, required this.onSave});

  @override
  State<_EditPayrollForm> createState() => _EditPayrollFormState();
}

class _EditPayrollFormState extends State<_EditPayrollForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _basicController;
  late TextEditingController _allowancesController;
  late TextEditingController _deductionsController;
  late TextEditingController _bonusController;

  @override
  void initState() {
    super.initState();
    _basicController = TextEditingController(text: widget.payroll['basic'].toString());
    _allowancesController = TextEditingController(text: widget.payroll['allowances'].toString());
    _deductionsController = TextEditingController(text: widget.payroll['deductions'].toString());
    _bonusController = TextEditingController(text: widget.payroll['bonus'].toString());
  }

  @override
  void dispose() {
    _basicController.dispose();
    _allowancesController.dispose();
    _deductionsController.dispose();
    _bonusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Edit Payroll', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            TextFormField(
              controller: _basicController,
              decoration: InputDecoration(labelText: 'Basic Salary'),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Enter basic salary' : null,
            ),
            TextFormField(
              controller: _allowancesController,
              decoration: InputDecoration(labelText: 'Allowances'),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Enter allowances' : null,
            ),
            TextFormField(
              controller: _bonusController,
              decoration: InputDecoration(labelText: 'Bonus'),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Enter bonus' : null,
            ),
            TextFormField(
              controller: _deductionsController,
              decoration: InputDecoration(labelText: 'Deductions'),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Enter deductions' : null,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              child: Text('Save'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final basic = int.tryParse(_basicController.text) ?? 0;
                  final allowances = int.tryParse(_allowancesController.text) ?? 0;
                  final deductions = int.tryParse(_deductionsController.text) ?? 0;
                  final bonus = int.tryParse(_bonusController.text) ?? 0;
                  final netPay = basic + allowances + bonus - deductions;
                  widget.onSave({
                    'basic': basic,
                    'allowances': allowances,
                    'deductions': deductions,
                    'bonus': bonus,
                    'netPay': netPay,
                  });
                }
              },
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

Future<void> _exportPayslipPDF(BuildContext context, Map<String, dynamic> employee, Map<String, dynamic> payroll) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) => pw.Padding(
        padding: const pw.EdgeInsets.all(24),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Payslip', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Text('Employee Name: ${employee['name']}'),
            pw.Text('Employee ID: ${employee['id']}'),
            pw.Text('Department: ${employee['department']}'),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text('Earnings', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Basic Salary'),
                pw.Text('₹${payroll['basic']}'),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Allowances'),
                pw.Text('₹${payroll['allowances']}'),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Bonus'),
                pw.Text('₹${payroll['bonus']}'),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text('Deductions', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Deductions'),
                pw.Text('-₹${payroll['deductions']}'),
              ],
            ),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Net Pay', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('₹${payroll['netPay']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );
} 