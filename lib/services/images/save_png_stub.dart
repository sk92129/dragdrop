// Kang Engineering Systems LLC, 2026, Copyright protection

import 'dart:typed_data';

/// Used only when neither `dart:io` nor `dart:html` is available.
Future<String> savePngLocal(Uint8List data, String baseName) {
  return Future<String>.error(
    UnsupportedError('Save PNG is not available on this platform'),
  );
}
