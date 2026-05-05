import 'package:flutter/foundation.dart' show debugPrint;

class EventModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime fromDate;
  final DateTime toDate;
  final String? imageUrl;
  final String? fileUrl;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.fromDate,
    required this.toDate,
    this.imageUrl,
    this.fileUrl,
  });

  factory EventModel.fromJson(Map<String, dynamic> j) {
    // Enhanced date parsing that handles both ISO strings and Firestore timestamps
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) {
        debugPrint('[EventModel] Date value is null, using current time');
        return DateTime.now();
      }
      
      // Handle Firestore timestamp format: { "_seconds": 1775001600, "_nanoseconds": 0 }
      if (dateValue is Map && dateValue.containsKey('_seconds')) {
        try {
          final sec = dateValue['_seconds'];
          final nanos = dateValue['_nanoseconds'] ?? 0;
          
          if (sec is num && nanos is num) {
            final totalMs = (sec * 1000) + (nanos / 1000000).round();
            final dateTime = DateTime.fromMillisecondsSinceEpoch(totalMs.round(), isUtc: true).toLocal();
            debugPrint('[EventModel] Converted Firestore timestamp: $dateValue -> $dateTime');
            return dateTime;
          }
        } catch (e) {
          debugPrint('[EventModel] Error parsing Firestore timestamp: $e, falling back to current time');
          return DateTime.now();
        }
      }
      
      // Handle ISO string format
      if (dateValue is String) {
        final String dateStr = dateValue.trim();
        if (dateStr.isEmpty) {
          debugPrint('[EventModel] Date string is empty, using current time');
          return DateTime.now();
        }
        
        try {
          final dateTime = DateTime.tryParse(dateStr);
          if (dateTime != null) {
            debugPrint('[EventModel] Parsed ISO string: $dateStr -> $dateTime');
            return dateTime;
          }
        } catch (e) {
          debugPrint('[EventModel] Error parsing ISO string: $e, falling back to current time');
        }
      }
      
      debugPrint('[EventModel] Unhandled date format: $dateValue (${dateValue.runtimeType}), using current time');
      return DateTime.now();
    }

    return EventModel(
      id: (j['id'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      location: (j['location'] ?? '').toString(),
      fromDate: parseDate(j['fromDate']),
      toDate: parseDate(j['toDate']),
      imageUrl: j['imageUrl']?.toString(),
      fileUrl: j['fileUrl']?.toString(),
    );
  }

  Map<String, dynamic> toCsvMap() => {
        'Event Name': title,
        'From Date': fromDate.toIso8601String().split('T').first,
        'To Date': toDate.toIso8601String().split('T').first,
        'Location': location,
        'Image': (imageUrl ?? '').isNotEmpty ? 'Yes' : 'No',
        'Description': description,
      };
}

List<EventModel> eventsList = [];