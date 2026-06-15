import 'package:flutter/services.dart';

/// Restricts a text field to a Saudi mobile number: digits only, max 10
/// characters (e.g. 05xxxxxxxx). Use on every phone input across the app.
final List<TextInputFormatter> phoneInputFormatters = [
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(10),
];
