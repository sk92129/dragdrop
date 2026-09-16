// Kang Engineering Systems LLC, 2026, Copyright protection

import 'package:camera2image/main.dart' as app;
import 'package:camera2image/shared_widgets/qa_semantics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'take a picture, save, and view local record',
    (WidgetTester tester) async {
      await app.main();
      await _pumpUntil(
        tester,
        () => _has(tester, find.byKey(myWidgetKey('home.screen'))),
        timeout: const Duration(seconds: 30),
        onTimeout: 'Home screen did not load.',
      );
      await tester.pump(const Duration(seconds: 5));
      await _capturePhoto(tester);

      final String vendor = 'QA Cafe ${DateTime.now().millisecondsSinceEpoch}';
      await _saveReceipt(tester, vendor: vendor, amount: '12.34');

      await _openPending(tester);
      await _pumpUntil(
        tester,
        () => _has(tester, find.text(vendor)),
        timeout: const Duration(seconds: 45),
        onTimeout: 'Saved receipt "$vendor" was not listed on Pending.',
      );
      expect(find.text(vendor), findsWidgets);

      runApp(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 200));
    },
    timeout: const Timeout(Duration(minutes: 5)),
    semanticsEnabled: false,
  );
}

Future<void> _capturePhoto(WidgetTester tester) async {
  final Finder captureFab = find.byKey(myWidgetKey('home.capture_fab'));
  await _pumpUntil(
    tester,
    () => _has(tester, captureFab),
    timeout: const Duration(seconds: 15),
    onTimeout: 'Camera capture button was not on the home screen.',
  );
  await tester.tap(captureFab);
  await tester.pump(const Duration(seconds: 2));

  final Finder cameraScreen = find.byKey(myWidgetKey('camera.screen'));
  final Finder cameraCapture = find.byKey(myWidgetKey('camera.capture_fab'));
  final Finder pickedImages = find.byKey(myWidgetKey('home.picked_images_list'));
  await _pumpUntil(
    tester,
    () =>
        _has(tester, cameraCapture) ||
        _has(tester, cameraScreen) ||
        _has(tester, pickedImages),
    timeout: const Duration(seconds: 40),
    onTimeout: 'Camera did not open and no photo was captured.',
  );

  if (_has(tester, cameraCapture)) {
    await tester.tap(cameraCapture, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));
  }

  await _pumpUntil(
    tester,
    () =>
        _has(tester, find.byKey(myWidgetKey('home.save_fab'))) &&
        (_has(tester, pickedImages) ||
            _has(tester, find.byKey(myWidgetKey('home.picked_image.0')))) &&
        !_has(tester, find.byKey(myWidgetKey('camera.screen'))),
    timeout: const Duration(seconds: 45),
    onTimeout: 'Did not return to home with a captured photo.',
  );
}

Future<void> _saveReceipt(
  WidgetTester tester, {
  required String vendor,
  required String amount,
}) async {
  await tester.tap(find.byKey(myWidgetKey('home.save_fab')));
  await tester.pump(const Duration(milliseconds: 500));
  await _pumpUntil(
    tester,
    () => _has(tester, find.byKey(myWidgetKey('save.screen'))),
    timeout: const Duration(seconds: 15),
    onTimeout: 'Save screen did not open.',
  );

  await tester.enterText(find.byKey(myWidgetKey('save.vendor')), vendor);
  await tester.enterText(find.byKey(myWidgetKey('save.amount')), amount);
  await tester.pump();

  await tester.ensureVisible(find.byKey(myWidgetKey('save.date')));
  await tester.tap(find.byKey(myWidgetKey('save.date')));
  await tester.pump(const Duration(milliseconds: 800));
  await _confirmDatePicker(tester);

  await tester.tap(find.byKey(myWidgetKey('save.save')));
  await tester.pump(const Duration(milliseconds: 500));

  await _pumpUntil(
    tester,
    () {
      if (_has(tester, find.byKey(myWidgetKey('save.failed_dialog')))) {
        return true;
      }
      return _has(tester, find.byKey(myWidgetKey('home.screen'))) &&
          !_has(tester, find.byKey(myWidgetKey('save.screen')));
    },
    timeout: const Duration(minutes: 2),
    onTimeout: 'Save did not finish.',
  );

  if (_has(tester, find.byKey(myWidgetKey('save.failed_dialog')))) {
    final String message = _firstText(
      tester,
      find.byKey(myWidgetKey('save.failed_dialog_message')),
    );
    fail('Save failed: $message');
  }
}

Future<void> _confirmDatePicker(WidgetTester tester) async {
  final Finder dialogOk = find.descendant(
    of: find.byType(DatePickerDialog),
    matching: find.text('OK'),
  );
  if (_has(tester, dialogOk)) {
    await tester.tap(dialogOk);
    await tester.pump(const Duration(milliseconds: 400));
    return;
  }
  if (_has(tester, find.text('OK'))) {
    await tester.tap(find.text('OK').last);
    await tester.pump(const Duration(milliseconds: 400));
    return;
  }
  fail('Date picker OK button was not found.');
}

Future<void> _openPending(WidgetTester tester) async {
  await tester.tap(find.byKey(myWidgetKey('home.menu_button')));
  await tester.pump(const Duration(milliseconds: 500));
  final Finder pendingItem = find.byKey(myWidgetKey('home.menu_item.pending'));
  await _pumpUntil(
    tester,
    () => _has(tester, pendingItem),
    timeout: const Duration(seconds: 10),
    onTimeout: 'Pending menu item did not appear.',
  );
  await tester.tap(pendingItem);
  await tester.pump(const Duration(milliseconds: 500));
  await _pumpUntil(
    tester,
    () => _has(tester, find.byKey(myWidgetKey('pending.screen'))),
    timeout: const Duration(seconds: 20),
    onTimeout: 'Pending screen did not open.',
  );
}

bool _has(WidgetTester tester, Finder finder) {
  return tester.any(finder);
}

String _firstText(WidgetTester tester, Finder finder) {
  final Iterable<Text> texts = tester.widgetList<Text>(
    find.descendant(of: finder, matching: find.byType(Text)),
  );
  if (texts.isEmpty) {
    return finder.toString();
  }
  return texts.first.data ?? texts.first.toString();
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  required Duration timeout,
  required String onTimeout,
  Duration step = const Duration(milliseconds: 300),
}) async {
  final DateTime end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    if (condition()) {
      return;
    }
    await tester.pump(step);
  }
  fail('$onTimeout Visible keys: ${_visibleKeys(tester).join(', ')}');
}

List<String> _visibleKeys(WidgetTester tester) {
  return tester.allWidgets
      .map((Widget widget) => widget.key)
      .whereType<ValueKey<String>>()
      .map((ValueKey<String> key) => key.value)
      .toSet()
      .toList()
    ..sort();
}
