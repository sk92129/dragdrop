// Kang Engineering Systems LLC, 2026, Copyright protection

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> savePngLocal(Uint8List data, String baseName) async {
  final Directory docDir = await getApplicationDocumentsDirectory();
  final String name =
      baseName.toLowerCase().endsWith('.png') ? baseName : '$baseName.png';
  final Directory savedDir = Directory(p.join(docDir.path, 'Saved'));
  if (!await savedDir.exists()) {
    await savedDir.create(recursive: true);
  }
  final String fullPath = p.join(savedDir.path, name);
  final File out = File(fullPath);
  await out.writeAsBytes(data, flush: true);
  return out.path;
}
