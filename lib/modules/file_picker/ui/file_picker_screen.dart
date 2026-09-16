// Kang Engineering Systems LLC, 2026, Copyright protection

import 'package:camera2image/modules/file_picker/ui/image_drop_zone.dart';
import 'package:camera2image/services/routing/router.dart';
import 'package:camera2image/services/ui/snackbar_service.dart';
import 'package:camera2image/shared_widgets/offline_status_icon.dart';
import 'package:camera2image/shared_widgets/qa_semantics.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class FilePickerScreen extends StatefulWidget {
  const FilePickerScreen({super.key});

  @override
  State<FilePickerScreen> createState() => _FilePickerScreenState();
}

class _FilePickerScreenState extends State<FilePickerScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _picking = false;
  bool _dragging = false;

  Future<void> _pickImage() async {
    if (_picking) {
      return;
    }
    setState(() => _picking = true);
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (!mounted || image == null) {
        return;
      }
      _useImage(image);
    } catch (e) {
      SnackbarService.show(
        message: 'Could not pick image: $e',
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _picking = false);
      }
    }
  }

  void _useImage(XFile image) {
    context.pushNamed(AppRoutes.save.name, extra: image.path);
  }

  Widget _dropZone(ThemeData theme) {
    return myWidget(
      id: 'file_picker.drop_zone',
      label: 'Drop one image file',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 220,
          child: ImageDropZone(
            onImage: _useImage,
            onInvalid: (String message) {
              SnackbarService.show(
                message: message,
                type: SnackbarType.error,
              );
            },
            onDragEntered: () => setState(() => _dragging = true),
            onDragExited: () => setState(() => _dragging = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: _dragging
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _dragging
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  width: 2,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Drop one image here',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Only one image file is accepted',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return myWidget(
      id: 'file_picker.screen',
      child: Scaffold(
        appBar: AppBar(
          key: myWidgetKey('file_picker.app_bar'),
          title: myWidget(
            id: 'file_picker.app_bar_title',
            header: true,
            child: const Text('File Picker'),
          ),
          actions: withOfflineStatusIcon(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              myWidget(
                id: 'file_picker.pick_image_button',
                button: true,
                label: 'Pick an image',
                child: FilledButton.icon(
                  onPressed: _picking ? null : _pickImage,
                  icon: _picking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_library_outlined),
                  label: const Text('Pick image'),
                ),
              ),
              const SizedBox(height: 24),
              _dropZone(theme),
            ],
          ),
        ),
      ),
    );
  }
}
