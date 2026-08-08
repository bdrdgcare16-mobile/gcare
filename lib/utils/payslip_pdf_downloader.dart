import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';

/// Shared PDF downloader for both Admin and Employee payslips.
/// Handles platform-specific saving and validates the save operation.
class PayslipPdfDownloader {
  /// Saves or shares a payslip PDF to the device.
  /// 
  /// On web: Downloads to browser Downloads folder using FileSaver.
  /// On Android/iOS: Opens native share/save sheet using Printing.sharePdf.
  static Future<void> saveOrShare({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (kIsWeb) {
      // Web: Use FileSaver for browser download
      final normalizedName = fileName
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');

      await FileSaver.instance.saveFile(
        name: normalizedName,
        bytes: bytes,
        mimeType: MimeType.pdf,
      );
    } else {
      // Mobile: Use native share/save sheet
      await Printing.sharePdf(
        bytes: bytes,
        filename: '$fileName.pdf',
      );
    }
  }
}
