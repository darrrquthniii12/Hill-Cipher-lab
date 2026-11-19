import 'package:flutter/material.dart';

import 'state/cipher_controller.dart';
import 'ui/main_shell.dart';
import 'ui/widgets/common_widgets.dart';

void main() {
  runApp(const HillCipherLabApp());
}

/// Root aplikasi **Hill Cipher Lab** lintas platform (Windows & Android) 100% offline.
class HillCipherLabApp extends StatefulWidget {
  const HillCipherLabApp({
    super.key,
    this.controller,
  });

  final CipherController? controller;

  @override
  State<HillCipherLabApp> createState() => _HillCipherLabAppState();
}

class _HillCipherLabAppState extends State<HillCipherLabApp> {
  late CipherController _controller;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? CipherController();
  }

  @override
  void didUpdateWidget(covariant HillCipherLabApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (_ownsController) {
        _controller.dispose();
      }
      _ownsController = widget.controller == null;
      _controller = widget.controller ?? CipherController();
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (BuildContext context, _) {
        return MaterialApp(
          title: 'Hill Cipher Lab',
          debugShowCheckedModeBanner: false,
          themeMode: _controller.themeMode,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          home: MainShell(controller: _controller),
        );
      },
    );
  }

  /// Tema Dark Mode default ("Modern Crypto Lab").
  ThemeData _buildDarkTheme() {
    const LabColors colors = LabColors.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.dark(
        primary: colors.emerald,
        onPrimary: Colors.white,
        secondary: colors.cyan,
        onSecondary: colors.background,
        error: colors.rose,
        onError: Colors.white,
        surface: colors.card,
        onSurface: colors.textPrimary,
      ),
      dividerColor: colors.border,
      extensions: const <ThemeExtension<dynamic>>[colors],
    );
  }

  /// Tema Light Mode ber-kontras tinggi yang nyaman dibaca di proyektor kelas.
  ThemeData _buildLightTheme() {
    const LabColors colors = LabColors.light;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.light(
        primary: colors.emerald,
        onPrimary: Colors.white,
        secondary: colors.cyan,
        onSecondary: Colors.white,
        error: colors.rose,
        onError: Colors.white,
        surface: colors.card,
        onSurface: colors.textPrimary,
      ),
      dividerColor: colors.border,
      extensions: const <ThemeExtension<dynamic>>[colors],
    );
  }
}
