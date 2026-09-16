// Kang Engineering Systems LLC, 2026, Copyright protection

import 'package:flutter/material.dart';

/// Stable [ValueKey] for `find.byKey` in Flutter tests.
ValueKey<String> myWidgetKey(String id) => ValueKey<String>(id);

/// Wraps [child] with a unique key and Semantics identifier for QA automation.
///
/// [id] is used as both [ValueKey] and [Semantics.identifier] (resource-id /
/// accessibilityIdentifier for Appium and similar tools).
Widget myWidget({
  required String id,
  required Widget child,
  String? label,
  bool button = false,
  bool image = false,
  bool header = false,
  bool textField = false,
}) {
  return Semantics(
    identifier: id,
    label: label,
    button: button,
    image: image,
    header: header,
    textField: textField,
    container: true,
    child: KeyedSubtree(key: myWidgetKey(id), child: child),
  );
}
