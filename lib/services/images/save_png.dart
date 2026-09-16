// Kang Engineering Systems LLC, 2026, Copyright protection

import 'dart:typed_data';

import 'package:camera2image/services/images/save_png_stub.dart'
    if (dart.library.io) 'package:camera2image/services/images/save_png_io.dart'
    if (dart.library.html) 'package:camera2image/services/images/save_png_web.dart'
    as png_saver;

/// App documents / cache (VM) or browser download (web).
Future<String> savePng(Uint8List data, String baseName) {
  return png_saver.savePngLocal(data, baseName);
}
