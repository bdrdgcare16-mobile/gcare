import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:serv_app/html_stub.dart'
    if (dart.library.html) 'package:serv_app/html_web.dart' as html;

import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/services/api_service.dart';
import 'package:serv_app/config/api_config.dart';

// ---- THEME ----
const Color kBrand = Color(0xFF655193);
const Color kBrandLight = Color(0xFFF3F0F9);
const Color kBrandDark = Color(0xFF4A3870);
const Color kSurface = Color(0xFFFAFAFA);
const Color kCardBg = Color(0xFFFFFFFF);
const Color kBorder = Color(0xFFE8E2F4);
const Color kTextPrimary = Color(0xFF1A1A2E);
const Color kTextSecondary = Color(0xFF6B6B80);
const Color kTextOnBrand = Colors.white;

final String apiBase = ApiConfig.baseUrl;

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController employeeIdController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool _isLoading = false;

  // ---------------- JWT helpers ----------------
  bool _looksLikeJwt(String v) =>
      RegExp(r'^[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+$')
          .hasMatch(v);

  Future<String?> _getJwt() async {
    try {
      if (CompanyData.token != null && CompanyData.token!.isNotEmpty) {
        html.window.localStorage['token'] = CompanyData.token!;
        return CompanyData.token!;
      }
    } catch (_) {}

    const keys = ['token', 'jwt', 'access_token', 'auth_token'];

    for (final k in keys) {
      final v = html.window.localStorage[k];
      if (v != null && v.isNotEmpty) return v;
    }

    for (final k in html.window.localStorage.keys) {
      final v = html.window.localStorage[k];
      if (v != null && _looksLikeJwt(v)) return v;
    }

    return null;
  }

  // ---------------- submit ----------------
  Future<void> _handleSubmit() async {
    final name = nameController.text.trim();
    final empid = employeeIdController.text.trim();
    final department = emailController.text.trim();
    final description = descriptionController.text.trim();

    if (name.isEmpty ||
        empid.isEmpty ||
        department.isEmpty ||
        description.isEmpty) {
      _showSnackBar("Please fill all fields.", isError: true);
      return;
    }

    final token = await _getJwt();

    if (token == null || token.isEmpty) {
      _showSnackBar("Not logged in: No token provided", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    String adminName = 'Admin';

    try {
      adminName = (CompanyData.userName ??
              CompanyData.name ??
              CompanyData.email ??
              'Admin')
          .toString();
    } catch (_) {}

    final body = {
      "empid": empid,
      "name": name,
      "department": department,
      "description": description,
      "adminname": adminName,
      "date": DateTime.now().toIso8601String(),
    };

    final uri = Uri.parse('${ApiService.baseUrl}/rewards');

    try {
      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (resp.statusCode == 201) {
        _showSnackBar("Reward submitted successfully!", isError: false);

        nameController.clear();
        employeeIdController.clear();
        emailController.clear();
        descriptionController.clear();
      } else if (resp.statusCode == 401 || resp.statusCode == 403) {
        _showSnackBar(
          "Unauthorized (${resp.statusCode}): ${resp.body}",
          isError: true,
        );
      } else {
        _showSnackBar(
          "Submission failed (${resp.statusCode}): ${resp.body}",
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar("Network error: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? const Color(0xFFD32F2F) : kBrand,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF8F5FC),
              Color(0xFFEDE7F6),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPageHeader(),
                const SizedBox(height: 24),
                _buildFormCard(),
                const SizedBox(height: 24),
                _buildSubmitButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
  return AppBar(
    backgroundColor: const Color(0xFF6A1B9A), // SERV lavender shade
    centerTitle: false,
    leading: IconButton(
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        color: Colors.white,
        size: 18,
      ),
      onPressed: () => Navigator.pop(context),
    ),
    title: const Text(
      'Rewards',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 18,
        letterSpacing: -0.3,
      ),
    ),
  );
}

  Widget _buildPageHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nominate an Employee',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Recognise outstanding work by submitting a reward nomination.',
          style: TextStyle(
            color: kTextSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildField(
            controller: nameController,
            label: 'Full Name',
            hint: 'Enter employee name',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: employeeIdController,
            label: 'Employee ID',
            hint: 'e.g. EMP-0042',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: emailController,
            label: 'Department',
            hint: 'e.g. Engineering, Sales',
            icon: Icons.corporate_fare_rounded,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: descriptionController,
            label: 'Reason for Reward',
            hint: 'Describe the achievement or contribution...',
            icon: Icons.edit_note_rounded,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kTextPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(
            color: kTextPrimary,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: kTextSecondary,
              fontSize: 14,
            ),
            prefixIcon: maxLines == 1
                ? Icon(
                    icon,
                    color: kTextSecondary,
                    size: 18,
                  )
                : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: maxLines > 1 ? 14 : 0,
            ),
            filled: true,
            fillColor: kSurface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: kBorder,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: kBrand,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: kBrand,
          disabledBackgroundColor: kBrand.withOpacity(0.5),
          foregroundColor: kTextOnBrand,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Submit Nomination',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}