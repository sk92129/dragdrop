// Kang Engineering Systems LLC, 2026, Copyright protection

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

class ImageDropZone extends StatefulWidget {
  const ImageDropZone({
    super.key,
    required this.child,
    required this.onImage,
    this.onInvalid,
    this.onDragEntered,
    this.onDragExited,
  });

  final Widget child;
  final void Function(XFile image) onImage;
  final void Function(String message)? onInvalid;
  final VoidCallback? onDragEntered;
  final VoidCallback? onDragExited;

  @override
  State<ImageDropZone> createState() => _ImageDropZoneState();
}

class _ImageDropZoneState extends State<ImageDropZone> {
  static const Set<String> _imageExtensions = <String>{
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.bmp',
    '.heic',
    '.heif',
    '.tif',
    '.tiff',
    '.avif',
  };

  static const List<FileFormat> _imageFormats = <FileFormat>[
    Formats.png,
    Formats.jpeg,
    Formats.gif,
    Formats.webp,
    Formats.heic,
    Formats.heif,
    Formats.bmp,
    Formats.tiff,
  ];

  static const List<DataFormat> _dropFormats = <DataFormat>[
    ..._imageFormats,
    Formats.fileUri,
  ];

  void _onDropEnter(DropEvent event) {
    widget.onDragEntered?.call();
  }

  void _onDropLeave(DropEvent event) {
    widget.onDragExited?.call();
  }

  DropOperation _onDropOver(DropOverEvent event) {
    if (event.session.allowedOperations.contains(DropOperation.copy)) {
      return DropOperation.copy;
    }
    if (event.session.allowedOperations.contains(DropOperation.move)) {
      return DropOperation.move;
    }
    return DropOperation.none;
  }

  Future<void> _onPerformDrop(PerformDropEvent event) async {
    widget.onDragExited?.call();
    if (event.session.items.length != 1) {
      widget.onInvalid?.call('Drop exactly one image file.');
      return;
    }
    final DataReader? reader = event.session.items.first.dataReader;
    if (reader == null) {
      widget.onInvalid?.call('Could not read dropped image.');
      return;
    }
    final FileFormat? format = _preferredImageFormat(reader);
    final ReadProgress? progress = reader.getFile(
      format,
      _handleDroppedFile,
      onError: (Object error) {
        widget.onInvalid?.call('Could not read dropped image: $error');
      },
    );
    if (progress == null) {
      widget.onInvalid?.call('Only image files can be dropped.');
    }
  }

  FileFormat? _preferredImageFormat(DataReader reader) {
    final List<DataFormat> available = reader.getFormats(_imageFormats);
    for (final DataFormat format in available) {
      if (format is FileFormat) {
        return format;
      }
    }
    return null;
  }

  Future<void> _handleDroppedFile(DataReaderFile file) async {
    try {
      final Uint8List bytes = await file.readAll();
      final String name = file.fileName ?? 'dropped_image';
      if (!_looksLikeImage(name, bytes)) {
        widget.onInvalid?.call('Only image files can be dropped.');
        return;
      }
      final String savedName = _fileNameFor(name, bytes);
      final Directory dir = await getTemporaryDirectory();
      final File out = File(p.join(dir.path, savedName));
      await out.writeAsBytes(bytes, flush: true);
      if (!mounted) {
        return;
      }
      widget.onImage(
        XFile(
          out.path,
          mimeType: lookupMimeType(savedName, headerBytes: bytes),
          name: savedName,
        ),
      );
    } catch (e) {
      widget.onInvalid?.call('Could not read dropped image: $e');
    }
  }

  bool _looksLikeImage(String name, Uint8List bytes) {
    final String lower = name.toLowerCase();
    if (_imageExtensions.any(lower.endsWith)) {
      return true;
    }
    final String? mime = lookupMimeType(name, headerBytes: bytes);
    return mime != null && mime.startsWith('image/');
  }

  String _fileNameFor(String name, Uint8List bytes) {
    final String base = p.basename(name);
    if (_imageExtensions.any(base.toLowerCase().endsWith)) {
      return base;
    }
    final String? mime = lookupMimeType(base, headerBytes: bytes);
    final String ext = switch (mime) {
      'image/jpeg' => '.jpg',
      'image/png' => '.png',
      'image/gif' => '.gif',
      'image/webp' => '.webp',
      'image/bmp' => '.bmp',
      'image/heic' => '.heic',
      'image/heif' => '.heif',
      'image/tiff' => '.tiff',
      _ => '.png',
    };
    return '$base$ext';
  }

  @override
  Widget build(BuildContext context) {
    return DropRegion(
      formats: _dropFormats,
      hitTestBehavior: HitTestBehavior.opaque,
      onDropOver: _onDropOver,
      onDropEnter: _onDropEnter,
      onDropLeave: _onDropLeave,
      onPerformDrop: _onPerformDrop,
      child: widget.child,
    );
  }
}
