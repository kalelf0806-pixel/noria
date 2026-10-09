import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/chat/presentation/chat_screen.dart';

class NoriaApp extends StatelessWidget {
  const NoriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noria',
      debugShowCheckedModeBanner: false,
      theme: NoriaTheme.light,
      darkTheme: NoriaTheme.dark,
      themeMode: ThemeMode.system,
      home: const ChatScreen(),
    );
  }
}
