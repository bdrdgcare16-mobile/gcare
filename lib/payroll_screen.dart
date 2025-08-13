import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'services/payroll_service.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  bool _isLoading = false;
  String _selectedYear = DateTime.now().year.toString();

  // Color scheme
  static const Color primaryColor = Color(0xFF223A5E);
  static const Color accentColor = Color(0xFF00BFAE);
  static const Color backgroundColor = Color(0xFFE3F2FD);
  static const Color cardColor = Colors.white;
  static const Color mainTextColor = Color(0xFF222B45);
  static const Color secondaryTextColor = Color(0xFF6B7A8F);

  // Example data
  final currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());
  final netPay = 42000.00;
  final grossPay = 50000.00;
  final deductions = 8000.00;
  
  // Currency formatter with Rupees symbol
  String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }
  
  final payslips = [
    {
      'date': DateTime(2024, 8, 1),
      'grossPay': 50000.0,
      'netPay': 42000.0,
      'deductions': 8000.0,
      'status': 'Paid',
      'paymentMethod': 'Bank Transfer',
      'accountNumber': '****1234',
    },
    {
      'date': DateTime(2024, 7, 1),
      'grossPay': 50000.0,
      'netPay': 42000.0,
      'deductions': 8000.0,
      'status': 'Paid',
      'paymentMethod': 'Bank Transfer',
      'accountNumber': '****1234',
    },
    {
      'date': DateTime(2024, 6, 1),
      'grossPay': 48000.0,
      'netPay': 41000.0,
      'deductions': 7000.0,
      'status': 'Paid',
      'paymentMethod': 'Bank Transfer',
      'accountNumber': '****1234',
    },
    {
      'date': DateTime(2024, 5, 1),
      'grossPay': 48000.0,
      'netPay': 41000.0,
      'deductions': 7000.0,
      'status': 'Paid',
      'paymentMethod': 'Bank Transfer',
      'accountNumber': '****1234',
    },
  ];

  final statusColors = {
    'Paid': Colors.green,
    'Pending': Colors.orange,
    'Failed': Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Payroll',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showYearFilterDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salary Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your earnings and payment history',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryCard('Net Pay', '₹${netPay.toStringAsFixed(0)}', Icons.account_balance_wallet, Colors.green),
                    _summaryCard('Gross Pay', '₹${grossPay.toStringAsFixed(0)}', Icons.money, Colors.blue),
                    _summaryCard('Deductions', '₹${deductions.toStringAsFixed(0)}', Icons.remove_circle, Colors.orange),
                  ],
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Month Salary Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [accentColor.withValues(alpha: 0.1), accentColor.withValues(alpha: 0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current Month Salary',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: mainTextColor,
                                      ),
                                    ),
                                    Text(
                                      currentMonth,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildSalaryBreakdown(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Payslips Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Payslips',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: mainTextColor,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          _showPayslipHistory();
                        },
                        icon: const Icon(Icons.history, size: 16),
                        label: const Text('View All'),
                        style: TextButton.styleFrom(
                          foregroundColor: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Payslips List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: payslips.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final slip = payslips[index];
                      return _buildPayslipCard(slip);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryBreakdown() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gross Pay',
              style: TextStyle(
                fontSize: 16,
                color: secondaryTextColor,
              ),
            ),
            Text(
              '₹${grossPay.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: mainTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Deductions',
              style: TextStyle(
                fontSize: 16,
                color: secondaryTextColor,
              ),
            ),
            Text(
              '-₹${deductions.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Net Pay',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: mainTextColor,
              ),
            ),
            Text(
              '₹${netPay.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPayslipCard(Map<String, dynamic> slip) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showPayslipDetail(slip);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (statusColors[slip['status']] ?? Colors.grey).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: statusColors[slip['status']] ?? Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(slip['date'] as DateTime),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: mainTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Net: ₹${(slip['netPay'] as double).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gross: ₹${(slip['grossPay'] as double).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (statusColors[slip['status']] ?? Colors.grey).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      slip['status'] as String,
                      style: TextStyle(
                        color: statusColors[slip['status']] ?? Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: secondaryTextColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPayslipDetail(Map<String, dynamic> slip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PayslipDetailSheet(slip: slip),
    );
  }

  void _showYearFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Year'),
        content: DropdownButton<String>(
          value: _selectedYear,
          isExpanded: true,
          items: List.generate(5, (index) {
            final year = DateTime.now().year - index;
            return DropdownMenuItem(
              value: year.toString(),
              child: Text(year.toString()),
            );
          }),
          onChanged: (value) {
            setState(() {
              _selectedYear = value!;
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showPayslipHistory() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Payslip History'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: payslips.length,
              itemBuilder: (context, index) {
                final slip = payslips[index];
                final month = DateFormat('MMMM yyyy').format(slip['date'] as DateTime);
                return ListTile(
                  leading: const Icon(Icons.receipt),
                  title: Text('Payslip - $month'),
                  subtitle: Text('Amount: ₹${(slip['netPay'] as double).toStringAsFixed(2)}'),
                  trailing: Text(slip['status'] as String),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _PayslipDetailSheet extends StatelessWidget {
  final Map<String, dynamic> slip;
  const _PayslipDetailSheet({required this.slip});

  Future<void> _generateAndDownloadPDF(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Payslip',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Employee: Nishali Employee'),
            pw.Text('Month: ${DateFormat('MMMM yyyy').format(slip['date'] as DateTime)}'),
            pw.Text('Employee ID: EMP123456'),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text('Earnings', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text('Basic Salary: ₹${(slip['grossPay'] as double).toStringAsFixed(2)}'),
            pw.SizedBox(height: 10),
            pw.Text('Deductions', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text('Tax: ₹${((slip['deductions'] as double) * 0.6).toStringAsFixed(2)}'),
            pw.Text('Insurance: ₹${((slip['deductions'] as double) * 0.4).toStringAsFixed(2)}'),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              'Net Pay: ₹${(slip['netPay'] as double).toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Payment Details'),
            pw.Text('Method: ${slip['paymentMethod']}'),
            pw.Text('Account: ${slip['accountNumber']}'),
            pw.Text('Status: ${slip['status']}'),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Payslip_${DateFormat('yyyy_MM').format(slip['date'] as DateTime)}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF223A5E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payslip Details',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: const Color(0xFF222B45),
                        ),
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(slip['date'] as DateTime),
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF6B7A8F),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Salary breakdown
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection('Earnings', [
                      _buildDetailRow('Basic Salary', '₹${(slip['grossPay'] as double).toStringAsFixed(2)}'),
                    ]),
                    const SizedBox(height: 16),
                    _buildDetailSection('Deductions', [
                      _buildDetailRow('Income Tax', '₹${((slip['deductions'] as double) * 0.6).toStringAsFixed(2)}'),
                      _buildDetailRow('Insurance', '₹${((slip['deductions'] as double) * 0.4).toStringAsFixed(2)}'),
                    ]),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BFAE).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00BFAE).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Net Pay',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: const Color(0xFF222B45),
                            ),
                          ),
                          Text(
                            '₹${(slip['netPay'] as double).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: const Color(0xFF00BFAE),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDetailSection('Payment Details', [
                      _buildDetailRow('Payment Method', slip['paymentMethod'] as String),
                      _buildDetailRow('Account Number', slip['accountNumber'] as String),
                      _buildDetailRow('Status', slip['status'] as String),
                      _buildDetailRow('Transaction ID', 'TXN${(slip['date'] as DateTime).millisecondsSinceEpoch}'),
                    ]),
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _generateAndDownloadPDF(context),
                            icon: const Icon(Icons.download),
                            label: const Text('Download PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF223A5E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _sharePayslip(context);
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Share'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF223A5E),
                              side: const BorderSide(color: Color(0xFF223A5E)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: const Color(0xFF222B45),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF6B7A8F),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF222B45),
            ),
          ),
        ],
      ),
    );
  }

  void _sharePayslip(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payslip shared successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }
} 