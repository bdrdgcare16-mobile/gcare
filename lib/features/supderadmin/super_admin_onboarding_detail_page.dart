import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:serv_app/models/onboarding_model.dart';
import 'package:serv_app/services/super_admin_onboarding_service_new.dart';

class SuperAdminOnboardingDetailPage extends StatelessWidget {
  final OnboardingModel onboarding;

  const SuperAdminOnboardingDetailPage({super.key, required this.onboarding});

  @override
  Widget build(BuildContext context) {
    final documents = onboarding.documents;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8C6EAF),
        elevation: 0,
        title: const Text(
          'Onboarding Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal Details
              _buildSection('Personal Details', [
                _buildDetailRow('Full Name', onboarding.personalDetails['fullName']),
                _buildDetailRow('Gender', onboarding.personalDetails['gender']),
                _buildDetailRow('Date of Birth', onboarding.personalDetails['dob']),
                _buildDetailRow('Personal Email', onboarding.personalDetails['personalEmail']),
                _buildDetailRow('Mobile', '${onboarding.personalDetails['mobileCountryCode'] ?? ''} ${onboarding.personalDetails['mobileNumber'] ?? ''}'),
                _buildDetailRow('Address', onboarding.personalDetails['address']),
                _buildDetailRow('City', onboarding.personalDetails['city']),
                _buildDetailRow('State', onboarding.personalDetails['state']),
                _buildDetailRow('Pincode', onboarding.personalDetails['pincode']),
                _buildDetailRow('Country', onboarding.personalDetails['country']),
                _buildDetailRow('Permanent Address', onboarding.personalDetails['permanentAddress']),
                _buildDetailRow('Emergency Contact', onboarding.personalDetails['emergencyContactName']),
                _buildDetailRow('Emergency Mobile', '${onboarding.personalDetails['emergencyCountryCode'] ?? ''} ${onboarding.personalDetails['emergencyContactNumber'] ?? ''}'),
              ]),

              const SizedBox(height: 16),

              // Company Details
              _buildSection('Company Details', [
                _buildDetailRow('Company Name', onboarding.companyDetails['companyName']),
                _buildDetailRow('Branch Location', onboarding.companyDetails['branchLocation']),
                _buildDetailRow('Date of Joining', onboarding.companyDetails['dateOfJoining']),
                _buildDetailRow('Department', onboarding.companyDetails['department']),
                _buildDetailRow('Designation', onboarding.companyDetails['designation']),
                _buildDetailRow('Official Email', onboarding.companyDetails['officialEmail'] ?? 'Not provided'),
                _buildDetailRow('Employee ID', onboarding.companyDetails['employeeId']),
                _buildDetailRow('Shift Time', onboarding.companyDetails['shiftTime']),
                _buildDetailRow('Work Mode', onboarding.companyDetails['workMode']),
                _buildDetailRow('Employee Type', onboarding.companyDetails['employeeType']),
                _buildDetailRow('Experience Level', onboarding.companyDetails['experienceLevel']),
                _buildDetailRow('Years of Experience', onboarding.companyDetails['yearsOfExperience'] ?? 'Not applicable'),
                _buildDetailRow('Reporting Manager', onboarding.companyDetails['reportingManager']),
              ]),

              const SizedBox(height: 16),

              // Bank & Payroll Details
              _buildSection('Bank & Payroll Details', [
                _buildDetailRow('Bank Name', onboarding.bankDetails['bankName']),
                _buildDetailRow('Account Holder Name', onboarding.bankDetails['accountHolderName']),
                _buildDetailRow('Account Number', onboarding.bankDetails['accountNumber']),
                _buildDetailRow('IFSC Code', onboarding.bankDetails['ifscCode']),
                _buildDetailRow('PAN Number', onboarding.bankDetails['panNumber']),
                _buildDetailRow('Aadhaar Number', onboarding.bankDetails['aadhaarNumber']),
                _buildDetailRow('PF Number', onboarding.bankDetails['pfNumber'] ?? 'Not provided'),
                _buildDetailRow('ESI Number', onboarding.bankDetails['esiNumber'] ?? 'Not provided'),
                _buildDetailRow('Basic Salary', onboarding.bankDetails['basicSalary']),
                _buildDetailRow('HRA', onboarding.bankDetails['hra'] ?? '0'),
                _buildDetailRow('Allowances', onboarding.bankDetails['allowances'] ?? '0'),
                _buildDetailRow('Gross Salary', onboarding.bankDetails['grossSalary']),
                _buildDetailRow('Net Salary', onboarding.bankDetails['netSalary']),
              ]),

              const SizedBox(height: 16),

              // Documents
              _buildSection('Documents', [
                _buildDocumentRow(context, 'Resume', documents['resume']),
                _buildDocumentRow(context, 'Offer Letter', documents['offerLetter']),
                _buildDocumentRow(context, 'Aadhaar Card', documents['aadhaarCard']),
                _buildDocumentRow(context, 'PAN Card', documents['panCard']),
                _buildDocumentRow(context, 'Bank Proof', documents['bankProof']),
                _buildDocumentRow(context, 'Degree Certificate', documents['degreeCertificate']),
                _buildDocumentRow(context, 'Passport Photo', documents['passportPhoto']),
                if ((onboarding.companyDetails['experienceLevel']?.toString() ?? '') == 'Experienced')
                  _buildDocumentRow(context, 'Experience Certificate', documents['experienceCertificate']),
                if ((onboarding.companyDetails['experienceLevel']?.toString() ?? '') == 'Experienced')
                  _buildDocumentRow(context, 'Relieving Letter', documents['relievingLetter']),
              ]),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4B3B73),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    final displayValue = value?.toString() ?? '-';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayValue.isEmpty ? '-' : displayValue,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(
    BuildContext context,
    String label,
    dynamic url,
  ) {
    final documentUrl = url?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (documentUrl.isNotEmpty)
            GestureDetector(
              onTap: () => openDocumentUrl(context, documentUrl),
              child: const Text(
                'View Document',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const Text(
              'Not uploaded',
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Future<void> openDocumentUrl(
    BuildContext context,
    String? url,
  ) async {
    final documentUrl = url?.toString() ?? '';

    if (documentUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document not uploaded')),
      );
      return;
    }

    try {
      // Old records store a full URL directly; open those as-is. Newer
      // records store the private Firebase Storage object path, which must
      // first be resolved to a short-lived signed URL via the backend.
      final isDirectUrl = documentUrl.startsWith('http://') ||
          documentUrl.startsWith('https://');

      final resolvedUrl = isDirectUrl
          ? documentUrl
          : await SuperAdminOnboardingService.resolveDocumentUrl(documentUrl);

      final uri = Uri.parse(resolvedUrl);

      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open document')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open document: $e')),
      );
    }
  }
}
