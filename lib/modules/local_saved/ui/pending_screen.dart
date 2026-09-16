// Kang Engineering Systems LLC, 2026, Copyright protection
import 'package:camera2image/modules/local_saved/bloc/local_bloc.dart';
import 'package:camera2image/modules/local_saved/bloc/local_event.dart';
import 'package:camera2image/modules/local_saved/bloc/local_state.dart';
import 'package:camera2image/services/ui/snackbar_service.dart';
import 'package:camera2image/shared_models/draft_object.dart';
import 'package:camera2image/shared_models/transaction_state.dart';
import 'package:camera2image/shared_widgets/offline_status_icon.dart';
import 'package:camera2image/shared_widgets/qa_semantics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:super_clipboard/super_clipboard.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key});

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  final FocusNode _tableFocus = FocusNode();
  final Map<String, Uint8List> _bytesByUri = <String, Uint8List>{};
  List<DraftObject> _drafts = <DraftObject>[];
  String? _companyId;
  String? _selectedKey;

  @override
  void initState() {
    super.initState();
    ClipboardEvents.instance?.registerCopyEventListener(_onCopyEvent);
    _loadDraftsForCurrentCompany();
  }

  @override
  void dispose() {
    ClipboardEvents.instance?.unregisterCopyEventListener(_onCopyEvent);
    _tableFocus.dispose();
    super.dispose();
  }

  Future<void> _loadDraftsForCurrentCompany() async {
    final String companyId = "123";
    if (!mounted) {
      return;
    }
    setState(() => _companyId = companyId);
    context.read<LocalBloc>().add(
      LocalDisplayAllDraftsEvent(companyId: companyId),
    );
  }

  String _formatAmount(DraftObject draft) {
    final double amount = draft.amountMinorUnits / 100;
    return '${draft.currency} ${amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  List<DraftObject>? _draftsFromState(LocalState state) {
    if (state is LocalDisplayAllDraftsSuccess) {
      return _draftsForCurrentCompany(state.drafts);
    }
    if (state is LocalSaveDraftSuccess) {
      return _draftsForCurrentCompany(state.drafts);
    }
    return null;
  }

  List<DraftObject> _draftsForCurrentCompany(List<DraftObject> drafts) {
    final String? companyId = _companyId;
    if (companyId == null) {
      return const <DraftObject>[];
    }
    return drafts
        .where((DraftObject draft) => draft.companyId == companyId)
        .toList();
  }

  DraftObject? get _selectedDraft {
    final String? key = _selectedKey;
    if (key == null) {
      return null;
    }
    for (final DraftObject draft in _drafts) {
      if (draft.idempotencyKey == key) {
        return draft;
      }
    }
    return null;
  }

  void _selectDraft(DraftObject draft) {
    setState(() => _selectedKey = draft.idempotencyKey);
    _tableFocus.requestFocus();
    _preloadBytes(draft);
  }

  Future<void> _preloadBytes(DraftObject draft) async {
    if (_bytesByUri.containsKey(draft.fileUri)) {
      return;
    }
    final Uint8List? bytes = await _readDraftBytes(draft);
    if (!mounted || bytes == null) {
      return;
    }
    setState(() => _bytesByUri[draft.fileUri] = bytes);
  }

  Future<void> _copySelected() async {
    final DraftObject? draft = _selectedDraft;
    if (draft == null) {
      SnackbarService.show(
        message: 'Select a row to copy its image.',
        type: SnackbarType.info,
      );
      return;
    }
    await _copyDraft(draft);
  }

  Future<void> _copyDraft(DraftObject draft) async {
    final DataWriterItem? item = await _clipboardItemFor(draft);
    if (item == null) {
      SnackbarService.show(
        message: 'Could not copy image.',
        type: SnackbarType.error,
      );
      return;
    }
    final SystemClipboard? clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      SnackbarService.show(
        message: 'Clipboard is not available.',
        type: SnackbarType.error,
      );
      return;
    }
    try {
      await clipboard.write(<DataWriterItem>[item]);
      SnackbarService.show(message: 'Image copied.');
    } catch (e) {
      SnackbarService.show(
        message: 'Could not copy image: $e',
        type: SnackbarType.error,
      );
    }
  }

  Future<DataWriterItem?> _clipboardItemFor(DraftObject draft) async {
    final Uint8List? bytes =
        _bytesByUri[draft.fileUri] ?? await _readDraftBytes(draft);
    if (bytes == null) {
      return null;
    }
    _bytesByUri[draft.fileUri] = bytes;
    final DataWriterItem item = DataWriterItem(
      suggestedName: _suggestedFileName(draft),
    );
    _attachImagePayload(item, draft, bytes);
    return item;
  }

  void _onCopyEvent(ClipboardWriteEvent event) {
    final DraftObject? draft = _selectedDraft;
    if (draft == null) {
      return;
    }
    final Uint8List? bytes = _bytesByUri[draft.fileUri];
    if (bytes == null) {
      return;
    }
    final DataWriterItem item = DataWriterItem(
      suggestedName: _suggestedFileName(draft),
    );
    _attachImagePayload(item, draft, bytes);
    event.write(<DataWriterItem>[item]);
  }

  Future<void> _showCopyMenu(
    BuildContext context,
    Offset globalPosition,
    DraftObject draft,
  ) async {
    _selectDraft(draft);
    final String? action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx,
        globalPosition.dy,
      ),
      items: const <PopupMenuEntry<String>>[
        PopupMenuItem<String>(value: 'copy', child: Text('Copy image')),
      ],
    );
    if (action == 'copy') {
      await _copyDraft(draft);
    }
  }

  Widget _exportable({
    required DraftObject draft,
    required Widget child,
  }) {
    Widget dropRectangle(BuildContext context, Widget child) {
      return _DraftDropRectangle(
        vendor: draft.vendor,
        bytes: _bytesByUri[draft.fileUri],
      );
    }

    return DragItemWidget(
      dragItemProvider: (DragItemRequest request) {
        return _dragItemForDraft(
          draft,
          cachedBytes: _bytesByUri[draft.fileUri],
        );
      },
      allowedOperations: () => <DropOperation>[DropOperation.copy],
      liftBuilder: dropRectangle,
      dragBuilder: dropRectangle,
      child: DraggableWidget(
        hitTestBehavior: HitTestBehavior.opaque,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _selectDraft(draft),
          onSecondaryTapUp: (TapUpDetails details) {
            _showCopyMenu(context, details.globalPosition, draft);
          },
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return myWidget(
      id: 'pending.screen',
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.keyC, meta: true):
              _copySelected,
          const SingleActivator(LogicalKeyboardKey.keyC, control: true):
              _copySelected,
        },
        child: Focus(
          autofocus: true,
          focusNode: _tableFocus,
          child: Scaffold(
            appBar: AppBar(
              key: myWidgetKey('pending.app_bar'),
              title: myWidget(
                id: 'pending.app_bar_title',
                header: true,
                child: const Text('Local Records'),
              ),
              actions: withOfflineStatusIcon(
                actions: <Widget>[
                  myWidget(
                    id: 'pending.copy_image',
                    button: true,
                    label: 'Copy image',
                    child: IconButton(
                      onPressed: _selectedDraft == null ? null : _copySelected,
                      tooltip: 'Copy image',
                      icon: const Icon(Icons.copy),
                    ),
                  ),
                ],
              ),
            ),
            body: BlocBuilder<LocalBloc, LocalState>(
              builder: (BuildContext context, LocalState state) {
                final List<DraftObject>? drafts = _draftsFromState(state);
                if (drafts != null) {
                  _drafts = drafts;
                }

                if (_companyId == null ||
                    (state is LocalDisplayAllDraftsProgressing &&
                        _drafts.isEmpty)) {
                  return myWidget(
                    id: 'pending.loading',
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is LocalDisplayAllDraftsFailure) {
                  return myWidget(
                    id: 'pending.error',
                    child: Center(
                      child: Text(state.error, textAlign: TextAlign.center),
                    ),
                  );
                }

                if (_drafts.isEmpty) {
                  return myWidget(
                    id: 'pending.empty',
                    child: const Center(
                      child: Text(
                        'No local items.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return myWidget(
                  id: 'pending.table',
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        key: myWidgetKey('pending.data_table'),
                        showCheckboxColumn: false,
                        headingRowColor: WidgetStateProperty.all(
                          Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                        dataRowMinHeight: 56,
                        dataRowMaxHeight: 64,
                        columns: const <DataColumn>[
                          DataColumn(label: Text('')),
                          DataColumn(label: Text('Vendor')),
                          DataColumn(label: Text('Amount')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('State')),
                          DataColumn(label: Text('Notes')),
                        ],
                        rows: _drafts
                            .map(
                              (DraftObject draft) => DataRow(
                                key: myWidgetKey(
                                  'pending.row.${draft.idempotencyKey}',
                                ),
                                selected:
                                    _selectedKey == draft.idempotencyKey,
                                cells: <DataCell>[
                                  DataCell(
                                    _exportable(
                                      draft: draft,
                                      child: myWidget(
                                        id: 'pending.row.${draft.idempotencyKey}.thumbnail',
                                        image: true,
                                        label: 'Receipt thumbnail',
                                        child: _DraftThumbnail(
                                          fileUri: draft.fileUri,
                                          onLoaded: (Uint8List bytes) {
                                            _bytesByUri[draft.fileUri] = bytes;
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    _exportable(
                                      draft: draft,
                                      child: myWidget(
                                        id: 'pending.row.${draft.idempotencyKey}.vendor',
                                        child: Text(draft.vendor),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    _exportable(
                                      draft: draft,
                                      child: myWidget(
                                        id: 'pending.row.${draft.idempotencyKey}.amount',
                                        child: Text(_formatAmount(draft)),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    _exportable(
                                      draft: draft,
                                      child: myWidget(
                                        id: 'pending.row.${draft.idempotencyKey}.date',
                                        child: Text(
                                          _formatDate(draft.transactionDate),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    _exportable(
                                      draft: draft,
                                      child: myWidget(
                                        id: 'pending.row.${draft.idempotencyKey}.state',
                                        child: Text(draft.state.displayName),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    _exportable(
                                      draft: draft,
                                      child: myWidget(
                                        id: 'pending.row.${draft.idempotencyKey}.notes',
                                        child: Text(draft.notes),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

String _suggestedFileName(DraftObject draft) {
  final String uri = draft.fileUri;
  if (uri.startsWith('Download: ')) {
    final String name = uri.substring('Download: '.length).trim();
    if (name.isNotEmpty) {
      return name;
    }
  }
  final String name = p.basename(uri);
  if (name.isEmpty || name == '.' || name == '/') {
    return 'receipt.png';
  }
  return name;
}

bool _isFilesystemPath(String uri) {
  if (kIsWeb || uri.isEmpty) {
    return false;
  }
  return !uri.startsWith('Download:') &&
      !uri.startsWith('blob:') &&
      !uri.startsWith('http://') &&
      !uri.startsWith('https://');
}

Future<Uint8List?> _readDraftBytes(DraftObject draft) async {
  if (draft.fileUri.isEmpty) {
    return null;
  }
  try {
    return await XFile(draft.fileUri).readAsBytes();
  } catch (_) {
    return null;
  }
}

void _attachImagePayload(
  DataWriterItem item,
  DraftObject draft,
  Uint8List bytes,
) {
  item.add(Formats.png(bytes));
  if (_isFilesystemPath(draft.fileUri)) {
    item.add(Formats.fileUri(Uri.file(draft.fileUri)));
  } else if (item.virtualFileSupported) {
    item.addVirtualFile(
      format: Formats.png,
      provider: (sinkProvider, progress) {
        final sink = sinkProvider(fileSize: bytes.length);
        sink.add(bytes);
        sink.close();
      },
    );
  }
}

Future<DragItem?> _dragItemForDraft(
  DraftObject draft, {
  Uint8List? cachedBytes,
}) async {
  final Uint8List? bytes = cachedBytes ?? await _readDraftBytes(draft);
  if (bytes == null) {
    return null;
  }
  final DragItem item = DragItem(
    localData: draft.idempotencyKey,
    suggestedName: _suggestedFileName(draft),
  );
  _attachImagePayload(item, draft, bytes);
  return item;
}

class _DraftThumbnail extends StatefulWidget {
  const _DraftThumbnail({required this.fileUri, this.onLoaded});

  final String fileUri;
  final void Function(Uint8List bytes)? onLoaded;

  @override
  State<_DraftThumbnail> createState() => _DraftThumbnailState();
}

class _DraftThumbnailState extends State<_DraftThumbnail> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _DraftThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileUri != widget.fileUri) {
      _bytes = null;
      _failed = false;
      _load();
    }
  }

  Future<void> _load() async {
    if (widget.fileUri.isEmpty) {
      if (mounted) {
        setState(() => _failed = true);
      }
      return;
    }
    try {
      final Uint8List bytes = await XFile(widget.fileUri).readAsBytes();
      if (!mounted) {
        return;
      }
      widget.onLoaded?.call(bytes);
      setState(() {
        _bytes = bytes;
        _failed = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _failed = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 40,
      height: 40,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: _bytes != null
            ? Image.memory(_bytes!, fit: BoxFit.cover)
            : ColoredBox(
                color: colors.surfaceContainerHighest,
                child: Icon(
                  _failed ? Icons.broken_image_outlined : Icons.image_outlined,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}

class _DraftDropRectangle extends StatelessWidget {
  const _DraftDropRectangle({
    required this.vendor,
    this.bytes,
  });

  static const double _border = 2;
  static const double _padding = 8;
  static const double _width = 220;
  static const double _height = 64;

  final String vendor;
  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SnapshotSettings(
      translation: (Rect rect, Offset dragPosition) {
        return Offset(
          -((_width - rect.width) / 2),
          -((_height - rect.height) / 2),
        );
      },
      constraintsTransform: (BoxConstraints constraints) {
        return const BoxConstraints.tightFor(width: _width, height: _height);
      },
      child: Material(
        color: colors.surface,
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.primary, width: _border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(_padding),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 40,
                  height: 40,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: bytes != null
                        ? Image.memory(bytes!, fit: BoxFit.cover)
                        : ColoredBox(
                            color: colors.surfaceContainerHighest,
                            child: Icon(
                              Icons.image_outlined,
                              size: 20,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
                if (vendor.isNotEmpty) ...<Widget>[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vendor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
