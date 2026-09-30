import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_theme.dart';
import 'widgets/app_root.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: AiVmsApp(),
    ),
  );
}

class AiVmsApp extends StatelessWidget {
  const AiVmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI VMS',
      theme: buildVmsTheme(),
      home: const AppRoot(),
    );
  }
}
