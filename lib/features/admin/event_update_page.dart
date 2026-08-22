import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:serv_app/shared/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:serv_app/html_stub.dart'
    if (dart.library.html) 'package:serv_app/html_web.dart' as html;

import 'event_model_page.dart';
import 'add_event_page.dart';
import 'package:serv_app/config/api_config.dart';
import 'package:serv_app/services/api_service.dart';
import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/utils/button_helpers.dart';

// ====== CONFIG ======
final String apiBase = ApiConfig.baseUrl;
final String _apiOrigin =
    ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

// ====== THEME (centralized)
const Color kPrimaryBackgroundTop = Colors.white;
const Color kPrimaryBackgroundBottom = kPrimaryLight;
const Color kAppBarColor = kPrimary;
const Color kButtonColor = kPrimaryDark;

// ====== TABLE LAYOUT ======
const double _tableHorizontalPadding = 6;
const double _eventNameWidth = 140;
const double _fromDateWidth = 100;
const double _toDateWidth = 100;
const double _locationWidth = 120;
const double _descriptionWidth = 220;
const double _deleteWidth = 40;

const double _tableRowContentWidth = _eventNameWidth +
    _fromDateWidth +
    _toDateWidth +
    _locationWidth +
    _descriptionWidth +
    _deleteWidth;

const double _tableTotalWidth =
    _tableRowContentWidth + (_tableHorizontalPadding * 2);

class EventUpdatesPage extends StatefulWidget {
  const EventUpdatesPage({super.key});

  @override
  State<EventUpdatesPage> createState() => _EventUpdatesPageState();
}

class _EventUpdatesPageState extends State<EventUpdatesPage> {
  List<EventModel> eventsList = [];
  List<EventModel> _filtered = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kAppBarColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Event Updates',
          style: TextStyle(color: kTextColor),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: kTextColor),
            onPressed: _search,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: kTextColor),
            onPressed: _load,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 10,
              children: [
                GuardedElevatedButton(
                  key: const ValueKey('events_add_button'),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EventUploadPage(),
                      ),
                    );
                    await _load();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kButtonColor,
                    foregroundColor: kTextColor,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 8),
                      Text("Add"),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ClipRect(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: _tableTotalWidth,
                            child: Column(
                              children: [
                                Container(
                                  width: _tableTotalWidth,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: _tableHorizontalPadding,
                                    vertical: 8,
                                  ),
                                  color: kPrimaryBackgroundBottom.withOpacity(
                                    0.5,
                                  ),
                                  child: const Row(
                                    children: [
                                      _HeaderCell(
                                        'Event Name',
                                        width: _eventNameWidth,
                                      ),
                                      _HeaderCell(
                                        'From Date',
                                        width: _fromDateWidth,
                                      ),
                                      _HeaderCell(
                                        'To Date',
                                        width: _toDateWidth,
                                      ),
                                      _HeaderCell(
                                        'Location',
                                        width: _locationWidth,
                                      ),
                                      _HeaderCell(
                                        'Description',
                                        width: _descriptionWidth,
                                      ),
                                      _HeaderCell(
                                        'Delete',
                                        width: _deleteWidth,
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                Expanded(
                                  child: _filtered.isEmpty
                                      ? const Center(child: Text('No data'))
                                      : ListView.builder(
                                          itemCount: _filtered.length,
                                          itemBuilder: (_, i) {
                                            final e = _filtered[i];
                                            return Container(
                                              width: _tableTotalWidth,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal:
                                                    _tableHorizontalPadding,
                                                vertical: 10,
                                              ),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: Colors.grey.shade300,
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  _BodyCell(
                                                    e.title,
                                                    width: _eventNameWidth,
                                                  ),
                                                  _BodyCell(
                                                    e.fromDate
                                                        .toIso8601String()
                                                        .split('T')
                                                        .first,
                                                    width: _fromDateWidth,
                                                  ),
                                                  _BodyCell(
                                                    e.toDate
                                                        .toIso8601String()
                                                        .split('T')
                                                        .first,
                                                    width: _toDateWidth,
                                                  ),
                                                  _BodyCell(
                                                    e.location,
                                                    width: _locationWidth,
                                                  ),
                                                  _BodyCell(
                                                    e.description,
                                                    width: _descriptionWidth,
                                                  ),
                                                  SizedBox(
                                                    width: _deleteWidth,
                                                    child: GuardedIconButton(
                                                      key: ValueKey(
                                                        'delete_event_${e.id}',
                                                      ),
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                        size: 20,
                                                      ),
                                                      onPressed: () =>
                                                          _delete(e.id),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _getToken() async {
    String? token = CompanyData.token;

    if ((token == null || token.isEmpty) && kIsWeb) {
      try {
        final t1 = html.window.localStorage['token'];
        final t2 = html.window.sessionStorage['token'];
        token = (t1 != null && t1.isNotEmpty) ? t1 : (t2 ?? token);
      } catch (_) {}
    }

    if ((token == null || token.isEmpty) && !kIsWeb) {
      try {
        final prefs = await _getPrefs();
        token = prefs.getString('token');
      } catch (_) {}
    }

    debugPrint(
        '[Events] Token retrieved: ${token != null && token.isNotEmpty}');
    return token;
  }

  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final token = await _getToken();

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      debugPrint('[Events] Fetching events from: ${ApiService.baseUrl}/events');

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/events'),
        headers: headers,
      );

      debugPrint('[Events] Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List rawEvents = [];

        if (decoded is List) {
          rawEvents = decoded;
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['events'] is List) {
            rawEvents = decoded['events'] as List;
          } else if (decoded['data'] is List) {
            rawEvents = decoded['data'] as List;
          } else {
            throw Exception('Invalid response format: no events list found');
          }
        } else {
          throw Exception('Invalid response format');
        }

        final List<EventModel> loadedEvents = rawEvents
            .whereType<Map>()
            .map(
              (eventJson) => EventModel.fromJson(
                Map<String, dynamic>.from(eventJson),
              ),
            )
            .toList();

        debugPrint('[Events] Parsed events count: ${loadedEvents.length}');
        eventsList = loadedEvents;

        if (mounted) {
          setState(() {
            _filtered = List<EventModel>.from(eventsList);
          });
          debugPrint('[Events] UI updated with ${_filtered.length} events');
        }
      } else if (response.statusCode == 401) {
        _toast('Unauthorized. Please log in again.');
      } else {
        String message = 'Load failed: ${response.statusCode}';

        try {
          final decodedError = jsonDecode(response.body);
          if (decodedError is Map<String, dynamic> &&
              decodedError['message'] != null) {
            message = decodedError['message'].toString();
          }
        } catch (_) {}

        _toast(message);
      }
    } catch (e) {
      _toast('Load error: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _delete(String id) async {
    try {
      final token = await _getToken();

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/events/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        _toast('Deleted successfully');
        await _load();
      } else if (response.statusCode == 401) {
        _toast('Unauthorized. Please log in again.');
      } else {
        String message = 'Delete failed: ${response.statusCode}';

        try {
          final decodedError = jsonDecode(response.body);
          if (decodedError is Map<String, dynamic> &&
              decodedError['message'] != null) {
            message = decodedError['message'].toString();
          }
        } catch (_) {}

        _toast(message);
      }
    } catch (e) {
      _toast('Delete error: $e');
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _resolveUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '$_apiOrigin$url';
    return '$_apiOrigin/$url';
  }

  void _showImagePreview(String? url) {
    final link = _resolveUrl(url);
    if (link.isEmpty) {
      _toast('No image available');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  link,
                  fit: BoxFit.contain,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return SizedBox(
                      height: 420,
                      width: 560,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (ctx, err, stack) => SizedBox(
                    height: 420,
                    width: 560,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Could not load image',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            link,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _search() {
    String q = '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Search Events'),
        content: TextField(
          autofocus: true,
          onChanged: (v) => q = v,
          decoration: const InputDecoration(hintText: 'Event title'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filtered = eventsList
                    .where(
                      (e) => e.title.toLowerCase().contains(q.toLowerCase()),
                    )
                    .toList();
              });
              Navigator.of(context).pop();
            },
            child: const Text('Search'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _filtered = List.of(eventsList));
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _downloadCsv() {
    if (!kIsWeb) {
      _toast('CSV download is supported on Web only.');
      return;
    }

    final buffer = StringBuffer()
      ..writeln('Event Name,From Date,To Date,Location,Description');

    for (final e in _filtered) {
      buffer.writeln(
        '${e.title},'
        '${e.fromDate.toIso8601String().split('T').first},'
        '${e.toDate.toIso8601String().split('T').first},'
        '${e.location},'
        '${e.description.replaceAll(',', ' ')}',
      );
    }

    final bytes = utf8.encode(buffer.toString());
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..download = 'event_updates.csv'
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final double width;

  const _HeaderCell(this.label, {required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  final String text;
  final double width;

  const _BodyCell(this.text, {required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(text, overflow: TextOverflow.ellipsis, maxLines: 1),
    );
  }
}
