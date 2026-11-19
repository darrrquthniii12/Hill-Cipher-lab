import 'package:flutter/material.dart';

/// Ekstensi tema khusus Hill Cipher Lab agar palet Dark Mode (Modern Crypto Lab)
/// dan Light Mode (Ramah Proyektor Kelas) konsisten di seluruh halaman.
class LabColors extends ThemeExtension<LabColors> {
  const LabColors({
    required this.background,
    required this.card,
    required this.cardAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.emerald,
    required this.cyan,
    required this.rose,
    required this.amber,
  });

  final Color background;
  final Color card;
  final Color cardAlt;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color emerald;
  final Color cyan;
  final Color rose;
  final Color amber;

  /// Palet default Dark Mode: latar #0F172A, kartu #1E293B, aksen Emerald/Cyan/Rose.
  static const LabColors dark = LabColors(
    background: Color(0xFF0F172A),
    card: Color(0xFF1E293B),
    cardAlt: Color(0xFF162033),
    border: Color(0xFF334155),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    emerald: Color(0xFF10B981),
    cyan: Color(0xFF38BDF8),
    rose: Color(0xFFF43F5E),
    amber: Color(0xFFF59E0B),
  );

  /// Palet Light Mode kontras tinggi yang ramah tampilan proyektor kelas.
  static const LabColors light = LabColors(
    background: Color(0xFFF8FAFC),
    card: Color(0xFFFFFFFF),
    cardAlt: Color(0xFFF1F5F9),
    border: Color(0xFFCBD5E1),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    emerald: Color(0xFF059669),
    cyan: Color(0xFF0284C7),
    rose: Color(0xFFE11D48),
    amber: Color(0xFFD97706),
  );

  @override
  LabColors copyWith({
    Color? background,
    Color? card,
    Color? cardAlt,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? emerald,
    Color? cyan,
    Color? rose,
    Color? amber,
  }) {
    return LabColors(
      background: background ?? this.background,
      card: card ?? this.card,
      cardAlt: cardAlt ?? this.cardAlt,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      emerald: emerald ?? this.emerald,
      cyan: cyan ?? this.cyan,
      rose: rose ?? this.rose,
      amber: amber ?? this.amber,
    );
  }

  @override
  LabColors lerp(ThemeExtension<LabColors>? other, double t) {
    if (other is! LabColors) {
      return this;
    }
    return LabColors(
      background: Color.lerp(background, other.background, t) ?? background,
      card: Color.lerp(card, other.card, t) ?? card,
      cardAlt: Color.lerp(cardAlt, other.cardAlt, t) ?? cardAlt,
      border: Color.lerp(border, other.border, t) ?? border,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      emerald: Color.lerp(emerald, other.emerald, t) ?? emerald,
      cyan: Color.lerp(cyan, other.cyan, t) ?? cyan,
      rose: Color.lerp(rose, other.rose, t) ?? rose,
      amber: Color.lerp(amber, other.amber, t) ?? amber,
    );
  }
}

/// Mengambil palet [LabColors] aktif dari [BuildContext].
LabColors labColorsOf(BuildContext context) {
  return Theme.of(context).extension<LabColors>() ??
      (Theme.of(context).brightness == Brightness.dark
          ? LabColors.dark
          : LabColors.light);
}

/// Menampilkan notifikasi SnackBar ringkas dan menggantikan SnackBar sebelumnya
/// agar tidak terjadi penumpukan antrean pesan.
void showLabSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final LabColors colors = labColorsOf(context);
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? colors.rose : colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isError ? colors.rose : colors.border,
        ),
      ),
      duration: const Duration(seconds: 3),
      content: Row(
        children: <Widget>[
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? Colors.white : colors.emerald,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? Colors.white : colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Kartu standar bernuansa lab kriptografi dengan border tegas dan header opsional.
class LabSectionCard extends StatelessWidget {
  const LabSectionCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.icon,
    this.accentColor,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Color? accentColor;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final LabColors colors = labColorsOf(context);
    final Color effectiveAccent = accentColor ?? colors.emerald;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: effectiveAccent.withAlpha(32),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: effectiveAccent),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

/// Tampilan kosong ramah pengguna saat belum ada data operasi/riwayat.
class LabEmptyState extends StatelessWidget {
  const LabEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final LabColors colors = labColorsOf(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: LabSectionCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.cyan.withAlpha(28),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 42, color: colors.cyan),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.science_outlined),
                  label: Text(actionLabel),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Painter untuk menggambar tanda kurung siku besar `[ ... ]` mengapit grid matriks.
class MatrixBracketPainter extends CustomPainter {
  const MatrixBracketPainter({
    required this.color,
    this.strokeWidth = 2.4,
    this.capLength = 9.0,
  });

  final Color color;
  final double strokeWidth;
  final double capLength;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const double pad = 2.0;
    final double top = pad;
    final double bottom = size.height - pad;
    final double left = pad;
    final double right = size.width - pad;

    // Kurung siku kiri '['
    final Path leftBracket = Path()
      ..moveTo(left + capLength, top)
      ..lineTo(left, top)
      ..lineTo(left, bottom)
      ..lineTo(left + capLength, bottom);

    // Kurung siku kanan ']'
    final Path rightBracket = Path()
      ..moveTo(right - capLength, top)
      ..lineTo(right, top)
      ..lineTo(right, bottom)
      ..lineTo(right - capLength, bottom);

    canvas.drawPath(leftBracket, paint);
    canvas.drawPath(rightBracket, paint);
  }

  @override
  bool shouldRepaint(covariant MatrixBracketPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.capLength != capLength;
  }
}

/// Widget read-only untuk menampilkan matriks 2x2 atau 3x3 diapit kurung siku `[ ... ]`.
class ReadOnlyMatrixView extends StatelessWidget {
  const ReadOnlyMatrixView({
    super.key,
    required this.matrix,
    required this.accentColor,
    this.cellWidth = 40,
    this.cellHeight = 34,
    this.fontSize = 14,
  });

  final List<List<int>> matrix;
  final Color accentColor;
  final double cellWidth;
  final double cellHeight;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final LabColors colors = labColorsOf(context);
    return CustomPaint(
      painter: MatrixBracketPainter(color: accentColor),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int r = 0; r < matrix.length; r++)
              Padding(
                padding: EdgeInsets.only(bottom: r < matrix.length - 1 ? 6 : 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (int c = 0; c < matrix[r].length; c++)
                      Container(
                        width: cellWidth,
                        height: cellHeight,
                        margin: EdgeInsets.only(
                          right: c < matrix[r].length - 1 ? 6 : 0,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.cardAlt,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: accentColor.withAlpha(90),
                          ),
                        ),
                        child: Text(
                          '${matrix[r][c]}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: fontSize,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
