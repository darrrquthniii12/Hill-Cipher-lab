import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'common_widgets.dart';

/// Grid input matriks 2x2 atau 3x3 yang diapit tanda kurung siku `[ ... ]`.
///
/// Mematuhi aturan anti-loncat kursor:
/// - Teks pada `TextEditingController` TIDAK pernah ditimpa saat kotak masih fokus diketik.
/// - Mengizinkan sel dalam keadaan kosong (`null`) tanpa memaksanya kembali ke `"0"`.
/// - Sinkronisasi teks dari state eksternal HANYA dijalankan ketika [syncVersion] berubah.
class MatrixGridWidget extends StatefulWidget {
  const MatrixGridWidget({
    super.key,
    required this.order,
    required this.matrix,
    required this.syncVersion,
    required this.onCellChanged,
    this.accentColor,
  });

  final int order;
  final List<List<int?>> matrix;
  final int syncVersion;
  final void Function(int row, int col, int? value) onCellChanged;
  final Color? accentColor;

  @override
  State<MatrixGridWidget> createState() => _MatrixGridWidgetState();
}

class _MatrixGridWidgetState extends State<MatrixGridWidget> {
  static const int _maxOrder = 3;

  late final List<List<TextEditingController>> _controllers;
  late final List<List<FocusNode>> _focusNodes;
  late int _lastSyncedVersion;

  @override
  void initState() {
    super.initState();
    _lastSyncedVersion = widget.syncVersion;
    _controllers = List<List<TextEditingController>>.generate(
      _maxOrder,
      (int r) => List<TextEditingController>.generate(_maxOrder, (int c) {
        final String initial = _cellText(r, c);
        return TextEditingController(text: initial);
      }),
    );
    _focusNodes = List<List<FocusNode>>.generate(
      _maxOrder,
      (int r) => List<FocusNode>.generate(_maxOrder, (int c) => FocusNode()),
    );
  }

  @override
  void didUpdateWidget(covariant MatrixGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Sinkronkan controller HANYA jika keySyncVersion berubah dari sumber eksternal
    // (ganti ordo, acak kunci, pilih preset, muat riwayat, atau mode kata kunci).
    if (widget.syncVersion != _lastSyncedVersion) {
      _lastSyncedVersion = widget.syncVersion;
      for (int r = 0; r < widget.order; r++) {
        for (int c = 0; c < widget.order; c++) {
          // Jangan pernah menimpa kotak yang sedang aktif diketik oleh pengguna.
          if (!_focusNodes[r][c].hasFocus) {
            final String nextText = _cellText(r, c);
            if (_controllers[r][c].text != nextText) {
              _controllers[r][c].value = TextEditingValue(
                text: nextText,
                selection: TextSelection.collapsed(offset: nextText.length),
              );
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    for (int r = 0; r < _maxOrder; r++) {
      for (int c = 0; c < _maxOrder; c++) {
        _controllers[r][c].dispose();
        _focusNodes[r][c].dispose();
      }
    }
    super.dispose();
  }

  String _cellText(int r, int c) {
    if (r < widget.matrix.length && c < widget.matrix[r].length) {
      final int? val = widget.matrix[r][c];
      return val?.toString() ?? '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final LabColors colors = labColorsOf(context);
    final Color bracketColor = widget.accentColor ?? colors.emerald;
    final double cellSize = widget.order == 2 ? 64 : 56;

    return CustomPaint(
      painter: MatrixBracketPainter(color: bracketColor),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int r = 0; r < widget.order; r++)
              Padding(
                padding: EdgeInsets.only(bottom: r < widget.order - 1 ? 8 : 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (int c = 0; c < widget.order; c++)
                      Container(
                        width: cellSize,
                        height: cellSize,
                        margin: EdgeInsets.only(
                          right: c < widget.order - 1 ? 8 : 0,
                        ),
                        child: TextField(
                          controller: _controllers[r][c],
                          focusNode: _focusNodes[r][c],
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: true,
                          ),
                          textInputAction: (r == widget.order - 1 &&
                                  c == widget.order - 1)
                              ? TextInputAction.done
                              : TextInputAction.next,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^-?\d*'),
                            ),
                            LengthLimitingTextInputFormatter(4),
                          ],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: widget.order == 2 ? 20 : 18,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colors.cardAlt,
                            hintText: '•',
                            hintStyle: TextStyle(
                              color: colors.rose.withAlpha(170),
                            ),
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: colors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: widget.matrix[r][c] == null
                                    ? colors.rose
                                    : colors.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: bracketColor,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (String raw) {
                            final String trimmed = raw.trim();
                            if (trimmed.isEmpty) {
                              // Biarkan sel bernilai null saat user menghapus angka.
                              widget.onCellChanged(r, c, null);
                              return;
                            }
                            final int? parsed = int.tryParse(trimmed);
                            widget.onCellChanged(r, c, parsed);
                          },
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
