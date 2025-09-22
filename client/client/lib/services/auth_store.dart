// lib/services/auth_store.dart
import 'package:shared_preferences/shared_preferences.dart';
// Web localStorage shim
import 'package:serv_app/html_stub.dart'
  if (dart.library.html) 'package:serv_app/html_web.dart' as html;

import 'package:serv_app/models/company_data.dart';

Future<void> hydrateCompanyData() async {
  String? tok;
  String? role;
  String? empid;
  try {
    tok = html.window.localStorage['token'];
    role = html.window.localStorage['role'];
    empid = html.window.localStorage['empId'] ?? html.window.localStorage['empid'];
  } catch (_) {}

  final sp = await SharedPreferences.getInstance();
  tok   ??= sp.getString('token');
  role  ??= sp.getString('role');
  empid ??= (sp.getString('empId') ?? sp.getString('empid'));

  // Normalize "null"/empty → null
  if (tok == null || tok.isEmpty || tok == 'null') tok = null;
  if (empid == null || empid.isEmpty || empid == 'null') empid = null;

  CompanyData.token = tok ?? '';
  CompanyData.empid = empid ?? '';
  CompanyData.userName = sp.getString('name') ?? '';
}
