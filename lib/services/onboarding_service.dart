import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:http/http.dart' as http;

import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/services/api_service.dart';

class OnboardingService {
  static Map<String, dynamic> buildFormData({
    required String fullName,
    required String gender,
    required String dob,
    required String personalEmail,
    required String mobileCountryCode,
    required String mobileNumber,
    required String address,
    required String city,
    required String state,
    required String pincode,
    required String country,
    required String permanentAddress,
    required String emergencyContactName,
    required String emergencyCountryCode,
    required String emergencyContactNumber,
    required String companyName,
    required String branchLocation,
    required String dateOfJoining,
    required String department,
    required String designation,
    required String officialEmail,
    required String employeeId,
    required String shiftTime,
    String? shiftId,
    required String workMode,
    required String employeeType,
    required String experienceLevel,
    required String? yearsOfExperience,
    required String reportingManager,
    required String bankName,
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
    required String panNumber,
    required String aadhaarNumber,
    required String? pfNumber,
    required String? esiNumber,
    required String basicSalary,
    required String hra,
    required String allowances,
    required String grossSalary,
    required String netSalary,
    required String password,
    required String confirmPassword,
  }) {
    return {
      'fullName': fullName,
      'gender': gender,
      'dob': dob,
      'personalEmail': personalEmail,
      'mobileCountryCode': mobileCountryCode,
      'mobileNumber': mobileNumber,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'country': country,
      'permanentAddress': permanentAddress,
      'emergencyContactName': emergencyContactName,
      'emergencyCountryCode': emergencyCountryCode,
      'emergencyContactNumber': emergencyContactNumber,
      'companyName': companyName,
      'branchLocation': branchLocation,
      'dateOfJoining': dateOfJoining,
      'department': department,
      'designation': designation,
      'officialEmail': officialEmail,
      'employeeId': employeeId,
      'shiftTime': shiftTime,
      if (shiftId != null && shiftId.isNotEmpty) 'shiftId': shiftId,
      'workMode': workMode,
      'employeeType': employeeType,
      'experienceLevel': experienceLevel,
      if (yearsOfExperience != null) 'yearsOfExperience': yearsOfExperience,
      'reportingManager': reportingManager,
      'bankName': bankName,
      'accountHolderName': accountHolderName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'panNumber': panNumber,
      'aadhaarNumber': aadhaarNumber,
      if (pfNumber != null) 'pfNumber': pfNumber,
      if (esiNumber != null) 'esiNumber': esiNumber,
      'basicSalary': basicSalary,
      'hra': hra,
      'allowances': allowances,
      'grossSalary': grossSalary,
      'netSalary': netSalary,
      'password': password,
      'confirmPassword': confirmPassword,
    };
  }

  static Future<Map<String, dynamic>> submitOnboarding({
    required Map<String, dynamic> formData,
    required Map<String, PlatformFile> files,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.baseUrl}/onboarding'),
    );

    final token = CompanyData.token.trim();
    if (token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    for (final entry in formData.entries) {
      if (entry.value != null) {
        request.fields[entry.key] = entry.value.toString();
      }
    }

    // Debug log for form data (excluding sensitive fields)
    final safeFields = request.fields.keys
        .where((key) => ![
              'aadhaarNumber',
              'accountNumber',
              'panNumber',
              'password',
              'confirmPassword'
            ].contains(key))
        .toList();
    debugPrint(
        'Onboarding submission debug: fields=${safeFields.length}, files=${files.length}');

    final skipped = <String>[];
    for (final entry in files.entries) {
      final file = entry.value;
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            entry.key,
            file.bytes!,
            filename: file.name,
          ),
        );
      } else if (!kIsWeb && file.path != null && file.path!.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            entry.key,
            file.path!,
            filename: file.name,
          ),
        );
      } else {
        // Picked but unreadable (e.g. web pick returned no bytes) — surface
        // it instead of silently submitting without the document.
        skipped.add(entry.key);
      }
    }

    if (skipped.isNotEmpty) {
      return {
        'success': false,
        'message': 'Could not read file data for: ${skipped.join(', ')}. '
            'Please re-select those documents and try again.',
      };
    }

    if (kIsWeb) {
      debugPrint(
        'Onboarding multipart: web files=${request.files.length}, '
        'fields=${request.fields.length}',
      );
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final decoded = body.isEmpty ? <String, dynamic>{} : jsonDecode(body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'success': true, 'data': decoded};
    }

    return {
      'success': false,
      'message': decoded is Map ? decoded['message'] : 'Submission failed',
    };
  }
}
