// Kang Engineering Systems LLC, 2026, Copyright protection

// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';

Future<String> savePngLocal(Uint8List data, String baseName) async {
  final String name =
      baseName.toLowerCase().endsWith('.png') ? baseName : '$baseName.png';
  final html.Blob blob = html.Blob(
    <dynamic>[data],
    'image/png',
  );
  final String url = html.Url.createObjectUrlFromBlob(blob);
  final html.AnchorElement anchor = html.AnchorElement(href: url)
    ..setAttribute('download', name);
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return 'Download: $name';
}
