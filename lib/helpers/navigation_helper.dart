import 'package:flutter/material.dart';
import '/widgets/main_scaffold.dart'; 

Future<void> navigateWithNavBar(
  BuildContext context,
  Widget overridePage, {
  int initialIndex = 0,
}) {
  return Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => MainScaffold(
        overridePage: overridePage,
        initialIndex: initialIndex,
      ),
    ),
  );
}
