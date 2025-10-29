import 'package:flutter/material.dart';
ValueNotifier<Locale> appLocale = ValueNotifier(const Locale('en'));
class L10n {
  static final all = [
    const Locale('en'),
    const Locale('es'),
    const Locale('pt'),
  ];
}