// Kang Engineering Systems LLC, 2026, Copyright protection

import 'package:camera2image/modules/local_saved/bloc/local_bloc.dart';
import 'package:camera2image/modules/local_saved/bloc/local_event.dart';
import 'package:camera2image/services/images/save_png.dart';
import 'package:camera2image/shared_models/draft_object.dart';
import 'package:camera2image/shared_models/transaction_state.dart';
import 'package:camera2image/shared_widgets/offline_status_icon.dart';
import 'package:camera2image/shared_widgets/qa_semantics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

const List<({String code, String name})> _topCurrencies =
    <({String code, String name})>[
      (code: 'USD', name: 'US Dollar'),
      (code: 'EUR', name: 'Euro'),
      (code: 'JPY', name: 'Japanese Yen'),
      (code: 'GBP', name: 'British Pound'),
      (code: 'CNY', name: 'Chinese Yuan'),
      (code: 'AUD', name: 'Australian Dollar'),
      (code: 'CAD', name: 'Canadian Dollar'),
      (code: 'CHF', name: 'Swiss Franc'),
      (code: 'HKD', name: 'Hong Kong Dollar'),
      (code: 'SGD', name: 'Singapore Dollar'),
      (code: 'INR', name: 'Indian Rupee'),
      (code: 'KRW', name: 'South Korean Won'),
      (code: 'SEK', name: 'Swedish Krona'),
      (code: 'NOK', name: 'Norwegian Krone'),
      (code: 'NZD', name: 'New Zealand Dollar'),
      (code: 'MXN', name: 'Mexican Peso'),
      (code: 'TWD', name: 'New Taiwan Dollar'),
      (code: 'BRL', name: 'Brazilian Real'),
      (code: 'DKK', name: 'Danish Krone'),
      (code: 'ZAR', name: 'South African Rand'),
    ];

class SaveScreen extends StatefulWidget {
  const SaveScreen({super.key, required this.imagePath});

  final String? imagePath;

  @override
  State<SaveScreen> createState() => _SaveScreenState();
}

class _SaveScreenState extends State<SaveScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _vendorController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _transactionDateController =
      TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _saving = false;
  String? _resultMessage;
  Uint8List? _previewBytes;
  DateTime? _transactionDate;
  String _currency = 'USD';

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  @override
  void dispose() {
    _vendorController.dispose();
    _amountController.dispose();
    _transactionDateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadPreview() async {
    final String? imagePath = widget.imagePath;
    if (imagePath == null || imagePath.isEmpty) {
      return;
    }
    try {
      final Uint8List bytes = await XFile(imagePath).readAsBytes();
      if (mounted) {
        setState(() {
          _previewBytes = bytes;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resultMessage = 'Could not load image preview.';
        });
      }
    }
  }

  Future<void> _pickTransactionDate() async {
    FocusScope.of(context).requestFocus(FocusNode());
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _transactionDate = picked;
      _transactionDateController.text =
          '${picked.month}/${picked.day}/${picked.year}';
    });
  }

  Future<bool> _saveImage() async {
    final String? imagePath = widget.imagePath;
    if (imagePath == null || imagePath.isEmpty) {
      setState(() {
        _resultMessage = 'No image to save.';
      });
      return false;
    }
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    setState(() {
      _saving = true;
      _resultMessage = null;
    });

    try {
      final XFile xfile = XFile(imagePath);
      final Uint8List input = await xfile.readAsBytes();
      final img.Image? decoded = img.decodeImage(input);
      if (decoded == null) {
        setState(() {
          _saving = false;
          _resultMessage = 'Could not decode that image.';
        });
        return false;
      }
      final Uint8List png = Uint8List.fromList(img.encodePng(decoded));
      final String name = 'image_${DateTime.now().millisecondsSinceEpoch}';
      final String path = await savePng(png, name);
      if (!mounted) {
        return false;
      }
      setState(() {
        _resultMessage = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
            ? 'Saved to Files: On My iPhone → Camera2image → Saved → $name'
            : 'Saved: $path';
      });
      if (!mounted) {
        return false;
      }
      final LocalBloc localBloc = context.read<LocalBloc>();
      final DraftObject? record = await _createDraftRecord(path, localBloc);
      if (record == null) {
        if (mounted) {
          setState(() => _saving = false);
        }
        return false;
      }

      if (mounted) {
        setState(() => _saving = false);
      }
      return true;
    } catch (e) {
      if (!mounted) {
        return false;
      }
      setState(() {
        _saving = false;
        _resultMessage = 'Save failed: $e';
      });
      return false;
    }
  }

  Future<void> _handleSavePressed() async {
    final bool saved = await _saveImage();
    if (!mounted) {
      return;
    }
    if (saved) {
      context.pop();
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          key: myWidgetKey('save.failed_dialog'),
          title: myWidget(
            id: 'save.failed_dialog_title',
            header: true,
            child: const Text('Save failed'),
          ),
          content: myWidget(
            id: 'save.failed_dialog_message',
            child: Text(_resultMessage ?? 'Could not save the receipt.'),
          ),
          actions: <Widget>[
            myWidget(
              id: 'save.failed_dialog_ok',
              button: true,
              label: 'OK',
              child: TextButton(
                key: myWidgetKey('save.failed_dialog_ok_button'),
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? imagePath = widget.imagePath;
    final bool hasImage = imagePath != null && imagePath.isNotEmpty;

    return myWidget(
      id: 'save.screen',
      child: Scaffold(
        appBar: AppBar(
          key: myWidgetKey('save.app_bar'),
          title: myWidget(
            id: 'save.app_bar_title',
            header: true,
            child: const Text('Save Image'),
          ),
          actions: withOfflineStatusIcon(
            actions: <Widget>[
              if (_saving)
                myWidget(
                  id: 'save.saving_spinner',
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                )
              else
                myWidget(
                  id: 'save.save_button',
                  button: true,
                  label: 'Save as PNG with Receipt',
                  child: IconButton(
                    key: myWidgetKey('save.save'),
                    onPressed: hasImage ? _handleSavePressed : null,
                    icon: const Icon(Icons.save),
                    tooltip: 'Save as PNG with Receipt',
                  ),
                ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          key: myWidgetKey('save.form_scroll'),
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                myWidget(
                  id: 'save.preview',
                  image: _previewBytes != null,
                  label: 'Image preview',
                  child: SizedBox(
                    height: 240,
                    child: _previewBytes != null
                        ? Image.memory(_previewBytes!, fit: BoxFit.contain)
                        : Center(
                            child: myWidget(
                              id: 'save.preview_placeholder',
                              child: Text(
                                hasImage
                                    ? 'Loading preview...'
                                    : 'No image selected.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                myWidget(
                  id: 'save.vendor_field',
                  textField: true,
                  label: 'Vendor',
                  child: TextFormField(
                    key: myWidgetKey('save.vendor'),
                    controller: _vendorController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Vendor',
                      border: OutlineInputBorder(),
                    ),
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vendor is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                myWidget(
                  id: 'save.amount_field',
                  textField: true,
                  label: 'Amount',
                  child: TextFormField(
                    key: myWidgetKey('save.amount'),
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Amount is required';
                      }
                      if (double.tryParse(value.trim()) == null) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                myWidget(
                  id: 'save.currency_field',
                  button: true,
                  label: 'Currency',
                  child: DropdownButtonFormField<String>(
                    key: myWidgetKey('save.currency'),
                    initialValue: _currency,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(),
                    ),
                    items: _topCurrencies
                        .map(
                          (
                            ({String code, String name}) currency,
                          ) => DropdownMenuItem<String>(
                            key: myWidgetKey(
                              'save.currency.option.${currency.code}',
                            ),
                            value: currency.code,
                            child: myWidget(
                              id: 'save.currency.option.${currency.code}.label',
                              child: Text(
                                '${currency.code} — ${currency.name}',
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _currency = value);
                    },
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Currency is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                myWidget(
                  id: 'save.date_field',
                  textField: true,
                  label: 'Transaction date',
                  child: TextFormField(
                    key: myWidgetKey('save.date'),
                    controller: _transactionDateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Transaction date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: _pickTransactionDate,
                    validator: (String? value) {
                      if (_transactionDate == null) {
                        return 'Transaction date is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                myWidget(
                  id: 'save.note_field',
                  textField: true,
                  label: 'Note (optional)',
                  child: TextFormField(
                    key: myWidgetKey('save.note'),
                    controller: _noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
                if (_resultMessage != null) ...<Widget>[
                  const SizedBox(height: 16),
                  myWidget(
                    id: 'save.result_message',
                    child: Text(_resultMessage!, textAlign: TextAlign.center),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<DraftObject?> _createDraftRecord(
    String path,
    LocalBloc localBloc,
  ) async {
    final String companyId = "123";
    final String vendor = _vendorController.text.trim();
    final String amount = _amountController.text.trim();
    final String currency = _currency;
    final DateTime transactionDate = _transactionDate!;
    final String note = _noteController.text.trim();
    final String recordId = 'record_${DateTime.now().millisecondsSinceEpoch}';
    final String idempotencyKey = const Uuid().v4();
    final int amountMinorUnits = amount.isEmpty
        ? 0
        : (double.parse(amount) * 100).round();
    final DraftObject record = DraftObject(
      localId: recordId,
      companyId: companyId,
      vendor: vendor,
      amountMinorUnits: amountMinorUnits,
      currency: currency,
      transactionDate: transactionDate,
      notes: note,
      fileUri: path,
      state: TransactionState.draft,
      idempotencyKey: idempotencyKey,
    );

    debugPrint('Created draft record: ${record.localId}');
    localBloc.add(LocalSaveDraftEvent(draft: record));
    return record;
  }
}
