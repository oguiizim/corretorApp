import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'app_bootstrapper.dart';

class CorretorApp extends StatelessWidget {
  const CorretorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Corretor de Imoveis',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AppBootstrapper(),
    );
  }
}
