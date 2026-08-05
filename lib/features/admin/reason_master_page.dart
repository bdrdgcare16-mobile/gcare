// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:serv_app/config/api_config.dart';
// import 'package:serv_app/models/company_data.dart';
// import 'package:serv_app/services/api_service.dart';

// /* ===========================
//    CONFIG
//    =========================== */
// final String apiBase = ApiConfig.baseUrl;
// const String kDefaultTypeName = 'General';

// // Theme
// const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// const Color kAppBarColor = Color(0xFF8C6EAF);
// const Color kButtonColor = Color(0xFF655193);
// const Color kTextColor = Colors.white;

// /* ===========================
//    MODELS
//    =========================== */
// class ReasonType {
//   final String id;
//   final String name;

//   ReasonType({
//     required this.id,
//     required this.name,
//   });

//   factory ReasonType.fromJson(Map<String, dynamic> j) {
//     return ReasonType(
//       id: '${j["id"] ?? j["_id"] ?? ""}',
//       name: '${j["name"] ?? ""}',
//     );
//   }
// }

// class ReasonItem {
//   final String id;
//   final String reason;
//   final DateTime? createdAt;
//   final String status;

//   ReasonItem({
//     required this.id,
//     required this.reason,
//     required this.createdAt,
//     required this.status,
//   });

//   factory ReasonItem.fromJson(Map<String, dynamic> j) {
//     DateTime? ts;
//     final c = j['createdAt'];

//     if (c is String) {
//       ts = DateTime.tryParse(c);
//     } else if (c is Map && c['_seconds'] != null) {
//       ts = DateTime.fromMillisecondsSinceEpoch((c['_seconds'] as int) * 1000);
//     }

//     return ReasonItem(
//       id: '${j["id"] ?? j["_id"] ?? ""}',
//       reason: '${j["reason"] ?? ""}',
//       createdAt: ts,
//       status: '${j["status"] ?? (j["deleted"] == true ? "Deleted" : "Active")}',
//     );
//   }
// }

// /* ===========================
//    PAGE
//    =========================== */
// class ReasonMasterPage extends StatefulWidget {
//   const ReasonMasterPage({super.key});

//   @override
//   State<ReasonMasterPage> createState() => _ReasonMasterPageState();
// }

// class _ReasonMasterPageState extends State<ReasonMasterPage> {
//   final TextEditingController _searchController = TextEditingController();
//   final TextEditingController _reasonInputController = TextEditingController();

//   List<ReasonItem> _all = [];
//   List<ReasonItem> _filtered = [];

//   bool _loading = true;
//   bool _booting = true;
//   String? _defaultTypeId;

//   @override
//   void initState() {
//     super.initState();
//     _searchController.addListener(_applyFilter);
//     _bootstrap();
//   }

//   /* ===========================
//      AUTH HELPERS
//      =========================== */
//   Future<String?> _getJwt() async {
//     final token = CompanyData.token;
//     if (token.isNotEmpty) return token;
//     return null;
//   }

//   Future<Map<String, String>> _authHeaders({bool json = true}) async {
//     final token = await _getJwt();
//     if (token == null || token.isEmpty) {
//       throw Exception('Missing auth token');
//     }

//     return {
//       if (json) 'Content-Type': 'application/json',
//       'Authorization': 'Bearer $token',
//     };
//   }

//   /* ===========================
//      BOOTSTRAP
//      =========================== */
//   Future<void> _bootstrap() async {
//     await _ensureDefaultType();
//     await _loadReasons();
//     if (mounted) {
//       setState(() => _booting = false);
//     }
//   }

//   /* ===========================
//      TYPES (hidden default)
//      =========================== */
//   Future<void> _ensureDefaultType() async {
//     try {
//       final headers = await _authHeaders();

//       // 1) List types
//       final r = await http.get(
//         Uri.parse('${ApiService.baseUrl}/reasons/types'),
//         headers: headers,
//       );

//       if (r.statusCode == 200) {
//         final decoded = jsonDecode(r.body);
//         final List data = decoded is List
//             ? decoded
//             : (decoded is Map<String, dynamic> && decoded['items'] is List)
//                 ? decoded['items'] as List
//                 : <dynamic>[];

//         final types = data
//             .map((e) => ReasonType.fromJson(Map<String, dynamic>.from(e as Map)))
//             .toList();

//         final existing = types.firstWhere(
//           (t) => t.name.trim().toLowerCase() == kDefaultTypeName.toLowerCase(),
//           orElse: () => ReasonType(id: '', name: ''),
//         );

//         if (existing.id.isNotEmpty) {
//           _defaultTypeId = existing.id;
//           return;
//         }
//       } else if (r.statusCode == 401) {
//         _toast('Unauthorized while loading reason types');
//         return;
//       }

//       // 2) If not found, create it
//       final c = await http.post(
//         Uri.parse('${ApiService.baseUrl}/reasons/types'),
//         headers: headers,
//         body: jsonEncode({'name': kDefaultTypeName}),
//       );

//       if (c.statusCode == 200 || c.statusCode == 201) {
//         final m = jsonDecode(c.body) as Map<String, dynamic>;
//         _defaultTypeId = '${m["id"] ?? m["_id"] ?? ""}';
//       } else if (c.statusCode == 401) {
//         _toast('Unauthorized while creating default type');
//       } else {
//         _toast('Could not ensure default type (${c.statusCode})');
//       }
//     } catch (e) {
//       _toast('Could not ensure default type: $e');
//     }
//   }

//   /* ===========================
//      REASONS
//      =========================== */
//   Future<void> _loadReasons() async {
//     setState(() => _loading = true);

//     try {
//       final headers = await _authHeaders();

//       final r = await http.get(
//         Uri.parse('${ApiService.baseUrl}/reasons'),
//         headers: headers,
//       );

//       if (r.statusCode == 200) {
//         final body = jsonDecode(r.body);
//         final List items = (body is List)
//             ? body
//             : (body is Map<String, dynamic> && body['items'] is List)
//                 ? body['items'] as List
//                 : <dynamic>[];

//         _all = items
//             .map((e) => ReasonItem.fromJson(Map<String, dynamic>.from(e as Map)))
//             .toList();
//       } else if (r.statusCode == 401) {
//         _toast('Failed to load reasons (401 Unauthorized)');
//       } else {
//         _toast('Failed to load reasons (${r.statusCode})');
//       }
//     } catch (e) {
//       _toast('Failed to load reasons: $e');
//     } finally {
//       _applyFilter();
//       if (mounted) {
//         setState(() => _loading = false);
//       }
//     }
//   }

//   Future<void> _createReason(String reason) async {
//     if (_defaultTypeId == null || _defaultTypeId!.isEmpty) {
//       _toast('No default type available; cannot create reason.');
//       return;
//     }

//     try {
//       final headers = await _authHeaders();

//       final r = await http.post(
//         Uri.parse('${ApiService.baseUrl}/reasons'),
//         headers: headers,
//         body: jsonEncode({
//           'typeId': _defaultTypeId,
//           'reason': reason,
//         }),
//       );

//       if (r.statusCode == 200 || r.statusCode == 201) {
//         _toast('Reason created');

//         try {
//           final m = jsonDecode(r.body);
//           if (m is Map<String, dynamic>) {
//             final created = ReasonItem.fromJson(m);
//             if (created.id.isNotEmpty) {
//               setState(() {
//                 _all.insert(0, created);
//                 _applyFilter();
//               });
//               return;
//             }
//           }
//         } catch (_) {}

//         await _loadReasons();
//       } else if (r.statusCode == 401) {
//         _toast('Create failed (401 Unauthorized)');
//       } else {
//         String serverMsg = '';
//         try {
//           serverMsg = (jsonDecode(r.body)['message'] ?? '').toString();
//         } catch (_) {}

//         _toast(
//           'Create failed (${r.statusCode})'
//           '${serverMsg.isNotEmpty ? " - $serverMsg" : ""}',
//         );
//       }
//     } catch (e) {
//       _toast('Create failed: $e');
//     }
//   }

//   Future<void> _deleteReason(String id) async {
//     try {
//       final headers = await _authHeaders(json: false);

//       final r = await http.delete(
//         Uri.parse('${ApiService.baseUrl}/reasons/$id'),
//         headers: headers,
//       );

//       if (r.statusCode == 200) {
//         setState(() {
//           _all.removeWhere((x) => x.id == id);
//           _applyFilter();
//         });
//         _toast('Deleted');
//       } else if (r.statusCode == 401) {
//         _toast('Delete failed (401 Unauthorized)');
//       } else {
//         _toast('Delete failed (${r.statusCode})');
//       }
//     } catch (e) {
//       _toast('Delete failed: $e');
//     }
//   }

//   /* ===========================
//      UI HELPERS
//      =========================== */
//   void _toast(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(msg)),
//     );
//   }

//   void _applyFilter() {
//     final q = _searchController.text.toLowerCase();

//     setState(() {
//       _filtered = _all.where((r) {
//         final d = _formatDate(r.createdAt);
//         return r.reason.toLowerCase().contains(q) ||
//             d.toLowerCase().contains(q) ||
//             r.status.toLowerCase().contains(q);
//       }).toList();
//     });
//   }

//   String _formatDate(DateTime? d) {
//     if (d == null) return '';
//     return '${d.day.toString().padLeft(2, '0')}-'
//         '${d.month.toString().padLeft(2, '0')}-'
//         '${d.year}';
//   }

//   /* ===========================
//      DIALOGS
//      =========================== */
//   Future<void> _openAddReasonDialog() async {
//     _reasonInputController.clear();

//     await showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text(
//           'Add New Reason',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         content: TextField(
//           controller: _reasonInputController,
//           autofocus: true,
//           decoration: const InputDecoration(
//             labelText: 'Enter Reason',
//             border: OutlineInputBorder(),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               final text = _reasonInputController.text.trim();
//               if (text.isEmpty) return;
//               Navigator.pop(context);
//               await _createReason(text);
//             },
//             child: const Text('Create'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _confirmDelete(ReasonItem r) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Confirm Delete'),
//         content: Text('Delete this reason?\n\n${r.reason}'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _deleteReason(r.id);
//             },
//             child: const Text(
//               'Delete',
//               style: TextStyle(color: Colors.red),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /* ===========================
//      BUILD
//      =========================== */
//   @override
//   Widget build(BuildContext context) {
//     final booting = _booting;
//     final loading = _loading;

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: kAppBarColor,
//         title: const Text(
//           'Reason Master',
//           style: TextStyle(fontSize: 16, color: kTextColor),
//         ),
//         actions: [
//           IconButton(
//             tooltip: 'Refresh',
//             onPressed: _loadReasons,
//             icon: const Icon(Icons.refresh, color: kTextColor),
//           ),
//         ],
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
//           ),
//         ),
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _searchController,
//                     decoration: InputDecoration(
//                       hintText: 'Search',
//                       prefixIcon: const Icon(Icons.search),
//                       contentPadding: const EdgeInsets.symmetric(
//                         vertical: 0,
//                         horizontal: 12,
//                       ),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 ElevatedButton(
//                   onPressed: booting ? null : _openAddReasonDialog,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: kButtonColor,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 14,
//                     ),
//                   ),
//                   child: const Text(
//                     'Create',
//                     style: TextStyle(color: kTextColor),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),

//             Container(
//               color: const Color(0xFF655193),
//               padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
//               child: const Row(
//                 children: [
//                   Expanded(
//                     flex: 3,
//                     child: Text(
//                       'Reason',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 13,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: Text(
//                       'Date',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 13,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: Text(
//                       'Status',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 13,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: Center(
//                       child: Text(
//                         'Delete',
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 13,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             Expanded(
//               child: booting || loading
//                   ? const Center(child: CircularProgressIndicator())
//                   : _filtered.isEmpty
//                       ? const Center(
//                           child: Padding(
//                             padding: EdgeInsets.all(32.0),
//                             child: Text(
//                               'No results found',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 color: Colors.black,
//                               ),
//                             ),
//                           ),
//                         )
//                       : RefreshIndicator(
//                           onRefresh: _loadReasons,
//                           child: ListView.builder(
//                             itemCount: _filtered.length,
//                             itemBuilder: (context, i) {
//                               final r = _filtered[i];
//                               return Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   vertical: 8,
//                                   horizontal: 8,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   border: Border(
//                                     bottom: BorderSide(
//                                       color: Colors.grey.shade300,
//                                     ),
//                                   ),
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     Expanded(
//                                       flex: 3,
//                                       child: Text(
//                                         r.reason,
//                                         style: const TextStyle(fontSize: 13),
//                                       ),
//                                     ),
//                                     Expanded(
//                                       child: Text(
//                                         _formatDate(r.createdAt),
//                                         style: const TextStyle(fontSize: 13),
//                                       ),
//                                     ),
//                                     Expanded(
//                                       child: Text(
//                                         r.status,
//                                         style: const TextStyle(fontSize: 13),
//                                       ),
//                                     ),
//                                     Expanded(
//                                       child: Center(
//                                         child: IconButton(
//                                           icon: const Icon(
//                                             Icons.delete_outline,
//                                             size: 18,
//                                           ),
//                                           onPressed: () => _confirmDelete(r),
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _reasonInputController.dispose();
//     super.dispose();
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:serv_app/shared/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:serv_app/config/api_config.dart';
import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/services/api_service.dart';

/* ===========================
   CONFIG
   =========================== */
final String apiBase = ApiConfig.baseUrl;
const String kDefaultTypeName = 'General';

// Theme (use shared theme values)
const Color kPrimaryBackgroundTop = Colors.white;
const Color kPrimaryBackgroundBottom = kPrimaryLight;
const Color kAppBarColor = kPrimary;
const Color kButtonColor = kPrimaryDark;

/* ===========================
   MODELS
   =========================== */
class ReasonType {
  final String id;
  final String name;

  ReasonType({
    required this.id,
    required this.name,
  });

  factory ReasonType.fromJson(Map<String, dynamic> j) {
    return ReasonType(
      id: '${j["id"] ?? j["_id"] ?? ""}',
      name: '${j["name"] ?? ""}',
    );
  }
}

class ReasonItem {
  final String id;
  final String reason;
  final DateTime? createdAt;
  final String status;

  ReasonItem({
    required this.id,
    required this.reason,
    required this.createdAt,
    required this.status,
  });

  factory ReasonItem.fromJson(Map<String, dynamic> j) {
    DateTime? ts;
    final c = j['createdAt'];

    if (c is String) {
      ts = DateTime.tryParse(c);
    } else if (c is Map && c['_seconds'] != null) {
      ts = DateTime.fromMillisecondsSinceEpoch((c['_seconds'] as int) * 1000);
    }

    return ReasonItem(
      id: '${j["id"] ?? j["_id"] ?? ""}',
      reason: '${j["reason"] ?? ""}',
      createdAt: ts,
      status: '${j["status"] ?? (j["deleted"] == true ? "Deleted" : "Active")}',
    );
  }
}

/* ===========================
   PAGE
   =========================== */
class ReasonMasterPage extends StatefulWidget {
  const ReasonMasterPage({super.key});

  @override
  State<ReasonMasterPage> createState() => _ReasonMasterPageState();
}

class _ReasonMasterPageState extends State<ReasonMasterPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _reasonInputController = TextEditingController();

  List<ReasonItem> _all = [];
  List<ReasonItem> _filtered = [];

  bool _loading = true;
  bool _booting = true;
  String? _defaultTypeId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilter);
    _bootstrap();
  }

  /* ===========================
     AUTH HELPERS
     =========================== */
  Future<String?> _getJwt() async {
    final token = CompanyData.token;
    if (token.isNotEmpty) return token;
    return null;
  }

  Future<Map<String, String>> _authHeaders({bool json = true}) async {
    final token = await _getJwt();
    if (token == null || token.isEmpty) {
      throw Exception('Missing auth token');
    }

    return {
      if (json) 'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /* ===========================
     BOOTSTRAP
     =========================== */
  Future<void> _bootstrap() async {
    await _ensureDefaultType();
    await _loadReasons();

    if (mounted) {
      setState(() => _booting = false);
    }
  }

  /* ===========================
     TYPES (hidden default)
     =========================== */
  Future<void> _ensureDefaultType() async {
    try {
      final headers = await _authHeaders();

      // 1) List types
      final r = await http.get(
        Uri.parse('${ApiService.baseUrl}/reasons/types'),
        headers: headers,
      );

      if (r.statusCode == 200) {
        final decoded = jsonDecode(r.body);

        final List data = decoded is List
            ? decoded
            : (decoded is Map<String, dynamic> && decoded['items'] is List)
                ? decoded['items'] as List
                : <dynamic>[];

        final types = data
            .map(
              (e) => ReasonType.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();

        final existing = types.firstWhere(
          (t) => t.name.trim().toLowerCase() == kDefaultTypeName.toLowerCase(),
          orElse: () => ReasonType(id: '', name: ''),
        );

        if (existing.id.isNotEmpty) {
          _defaultTypeId = existing.id;
          return;
        }
      } else if (r.statusCode == 401) {
        _toast('Unauthorized while loading reason types');
        return;
      }

      // 2) If not found, create it
      final c = await http.post(
        Uri.parse('${ApiService.baseUrl}/reasons/types'),
        headers: headers,
        body: jsonEncode({'name': kDefaultTypeName}),
      );

      if (c.statusCode == 200 || c.statusCode == 201) {
        final m = jsonDecode(c.body) as Map<String, dynamic>;
        _defaultTypeId = '${m["id"] ?? m["_id"] ?? ""}';
      } else if (c.statusCode == 401) {
        _toast('Unauthorized while creating default type');
      } else {
        _toast('Could not ensure default type (${c.statusCode})');
      }
    } catch (e) {
      _toast('Could not ensure default type: $e');
    }
  }

  /* ===========================
     REASONS
     =========================== */
  Future<void> _loadReasons() async {
    setState(() => _loading = true);

    try {
      final headers = await _authHeaders();

      final r = await http.get(
        Uri.parse('${ApiService.baseUrl}/reasons'),
        headers: headers,
      );

      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);

        final List items = body is List
            ? body
            : (body is Map<String, dynamic> && body['items'] is List)
                ? body['items'] as List
                : <dynamic>[];

        _all = items
            .map(
              (e) => ReasonItem.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
      } else if (r.statusCode == 401) {
        _toast('Failed to load reasons (401 Unauthorized)');
      } else {
        _toast('Failed to load reasons (${r.statusCode})');
      }
    } catch (e) {
      _toast('Failed to load reasons: $e');
    } finally {
      _applyFilter();

      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _createReason(String reason) async {
    if (_defaultTypeId == null || _defaultTypeId!.isEmpty) {
      _toast('No default type available; cannot create reason.');
      return;
    }

    try {
      final headers = await _authHeaders();

      final r = await http.post(
        Uri.parse('${ApiService.baseUrl}/reasons'),
        headers: headers,
        body: jsonEncode({
          'typeId': _defaultTypeId,
          'reason': reason,
        }),
      );

      if (r.statusCode == 200 || r.statusCode == 201) {
        _toast('Reason created');

        try {
          final m = jsonDecode(r.body);

          if (m is Map<String, dynamic>) {
            final created = ReasonItem.fromJson(m);

            if (created.id.isNotEmpty) {
              setState(() {
                _all.insert(0, created);
                _applyFilter();
              });
              return;
            }
          }
        } catch (_) {}

        await _loadReasons();
      } else if (r.statusCode == 401) {
        _toast('Create failed (401 Unauthorized)');
      } else {
        String serverMsg = '';

        try {
          serverMsg = (jsonDecode(r.body)['message'] ?? '').toString();
        } catch (_) {}

        _toast(
          'Create failed (${r.statusCode})'
          '${serverMsg.isNotEmpty ? " - $serverMsg" : ""}',
        );
      }
    } catch (e) {
      _toast('Create failed: $e');
    }
  }

  Future<void> _deleteReason(String id) async {
    try {
      final headers = await _authHeaders(json: false);

      final r = await http.delete(
        Uri.parse('${ApiService.baseUrl}/reasons/$id'),
        headers: headers,
      );

      if (r.statusCode == 200) {
        setState(() {
          _all.removeWhere((x) => x.id == id);
          _applyFilter();
        });

        _toast('Deleted');
      } else if (r.statusCode == 401) {
        _toast('Delete failed (401 Unauthorized)');
      } else {
        _toast('Delete failed (${r.statusCode})');
      }
    } catch (e) {
      _toast('Delete failed: $e');
    }
  }

  /* ===========================
     UI HELPERS
     =========================== */
  void _toast(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _applyFilter() {
    final q = _searchController.text.toLowerCase();

    setState(() {
      _filtered = _all.where((r) {
        final d = _formatDate(r.createdAt);

        return r.reason.toLowerCase().contains(q) ||
            d.toLowerCase().contains(q) ||
            r.status.toLowerCase().contains(q);
      }).toList();
    });
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '';

    return '${d.day.toString().padLeft(2, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.year}';
  }

  bool _isOthersReason(ReasonItem r) {
    return r.reason.trim().toLowerCase() == 'others';
  }

  /* ===========================
     DIALOGS
     =========================== */

  // Existing Create button popup
  Future<void> _openAddReasonDialog() async {
    _reasonInputController.clear();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Add New Reason',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: _reasonInputController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Enter Reason',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kButtonColor,
            ),
            onPressed: () async {
              final text = _reasonInputController.text.trim();

              if (text.isEmpty) {
                _toast('Please enter a reason');
                return;
              }

              Navigator.pop(context);
              await _createReason(text);
            },
            child: const Text(
              'Create',
              style: TextStyle(color: kTextColor),
            ),
          ),
        ],
      ),
    );
  }

  // New Others row popup
  Future<void> _openOtherReasonPopup() async {
    _reasonInputController.clear();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text(
          'Enter Other Reason',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: _reasonInputController,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Type your reason',
            hintText: 'Enter other reason here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _reasonInputController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kButtonColor,
            ),
            onPressed: () async {
              final text = _reasonInputController.text.trim();

              if (text.isEmpty) {
                _toast('Please enter a reason');
                return;
              }

              Navigator.pop(context);
              await _createReason(text);
            },
            child: const Text(
              'Submit',
              style: TextStyle(color: kTextColor),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ReasonItem r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete this reason?\n\n${r.reason}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteReason(r.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /* ===========================
     BUILD
     =========================== */
  @override
  Widget build(BuildContext context) {
    final booting = _booting;
    final loading = _loading;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kAppBarColor,
        title: const Text(
          'Reason Master',
          style: TextStyle(fontSize: 16, color: kTextColor),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadReasons,
            icon: const Icon(Icons.refresh, color: kTextColor),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
          ),
        ),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: booting ? null : _openAddReasonDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kButtonColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  child: const Text(
                    'Create',
                    style: TextStyle(color: kTextColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              color: const Color(0xFF655193),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Reason',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Date',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: booting || loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'No results found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadReasons,
                          child: ListView.builder(
                            itemCount: _filtered.length,
                            itemBuilder: (context, i) {
                              final r = _filtered[i];
                              final isOthers = _isOthersReason(r);

                              return InkWell(
                                onTap: isOthers ? _openOtherReasonPopup : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isOthers
                                        ? const Color(0xFFF4EEFF)
                                        : Colors.transparent,
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                r.reason,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: isOthers
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                                  color: isOthers
                                                      ? kButtonColor
                                                      : Colors.black,
                                                ),
                                              ),
                                            ),
                                            if (isOthers)
                                              const Padding(
                                                padding:
                                                    EdgeInsets.only(left: 6),
                                                child: Icon(
                                                  Icons.edit_note_rounded,
                                                  size: 18,
                                                  color: kButtonColor,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          _formatDate(r.createdAt),
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          r.status,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                            ),
                                            onPressed: () => _confirmDelete(r),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reasonInputController.dispose();
    super.dispose();
  }
}