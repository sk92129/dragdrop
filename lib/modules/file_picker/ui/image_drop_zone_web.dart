// Kang Engineering Systems LLC, 2026, Copyright protection

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:web/web.dart' as web;

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

  static int _nextViewId = 0;

  late final String _viewType;
  int _dragDepth = 0;

  @override
  void initState() {
    super.initState();
    _viewType = 'file-picker-image-drop-${_nextViewId++}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final web.HTMLDivElement element = web.HTMLDivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none';
      element.addEventListener('dragenter', _onDragEnter.toJS);
      element.addEventListener('dragover', _onDragOver.toJS);
      element.addEventListener('dragleave', _onDragLeave.toJS);
      element.addEventListener('drop', _onDrop.toJS);
      return element;
    });
  }

  void _dispatch(VoidCallback? callback) {
    if (callback == null) {
      return;
    }
    scheduleMicrotask(() {
      if (mounted) {
        callback();
      }
    });
  }

  void _onDragEnter(web.Event event) {
    event.preventDefault();
    _dragDepth += 1;
    if (_dragDepth == 1) {
      _dispatch(widget.onDragEntered);
    }
  }

  void _onDragOver(web.Event event) {
    event.preventDefault();
    final web.DataTransfer? transfer = (event as web.DragEvent).dataTransfer;
    if (transfer != null) {
      transfer.dropEffect = 'copy';
    }
  }

  void _onDragLeave(web.Event event) {
    event.preventDefault();
    _dragDepth = _dragDepth > 0 ? _dragDepth - 1 : 0;
    if (_dragDepth == 0) {
      _dispatch(widget.onDragExited);
    }
  }

  void _onDrop(web.Event event) {
    event.preventDefault();
    _dragDepth = 0;
    _dispatch(widget.onDragExited);
    final web.FileList? files = (event as web.DragEvent).dataTransfer?.files;
    if (files == null || files.length != 1) {
      _dispatch(
        () => widget.onInvalid?.call('Drop exactly one image file.'),
      );
      return;
    }
    final web.File file = files.item(0)!;
    if (!_isImageFile(file)) {
      _dispatch(
        () => widget.onInvalid?.call('Only image files can be dropped.'),
      );
      return;
    }
    _readFile(file);
  }

  bool _isImageFile(web.File file) {
    if (file.type.startsWith('image/')) {
      return true;
    }
    final String? mime = lookupMimeType(file.name);
    if (mime != null) {
      return mime.startsWith('image/');
    }
    final String lowerName = file.name.toLowerCase();
    return _imageExtensions.any(lowerName.endsWith);
  }

  Future<void> _readFile(web.File file) async {
    try {
      final JSArrayBuffer buffer = await file.arrayBuffer().toDart;
      final Uint8List bytes = buffer.toDart.asUint8List();
      if (!mounted) {
        return;
      }
      _dispatch(
        () => widget.onImage(
          XFile.fromData(
            bytes,
            mimeType: file.type.isEmpty
                ? lookupMimeType(file.name)
                : file.type,
            name: file.name,
          ),
        ),
      );
    } catch (e) {
      _dispatch(
        () => widget.onInvalid?.call('Could not read dropped image: $e'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        HtmlElementView(viewType: _viewType),
        IgnorePointer(child: widget.child),
      ],
    );
  }
}
