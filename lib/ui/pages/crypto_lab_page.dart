import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/cipher_models.dart';
import '../../state/cipher_controller.dart';
import '../widgets/common_widgets.dart';
import '../widgets/matrix_grid_widget.dart';

/// Tab 1 — Lab Kriptografi: input kunci (angka/kata), validasi determinan real-time,
/// masukan pesan dengan mode Smart Preserve, eksekusi enkripsi/dekripsi, dan panel output.
class CryptoLabPage extends StatefulWidget {
  const CryptoLabPage({
    super.key,
    required this.controller,
  });

  final CipherController controller;

  @override
  State<CryptoLabPage> createState() => _CryptoLabPageState();
}

class _CryptoLabPageState extends State<CryptoLabPage> {
  late final TextEditingController _inputController;
  late final FocusNode _inputFocusNode;
  late final TextEditingController _keywordController;
  late final FocusNode _keywordFocusNode;

  late int _lastInputSyncVersion;
  late int _lastKeywordSyncVersion;

  @override
  void initState() {
    super.initState();
    _lastInputSyncVersion = widget.controller.inputSyncVersion;
    _lastKeywordSyncVersion = widget.controller.keywordSyncVersion;

    _inputController = TextEditingController(text: widget.controller.inputText);
    _inputFocusNode = FocusNode();

    _keywordController =
        TextEditingController(text: widget.controller.keywordText);
    _keywordFocusNode = FocusNode();

    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant CryptoLabPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _syncControllersIfNeeded();
    }
  }

  void _onControllerChanged() {
    _syncControllersIfNeeded();
  }

  void _syncControllersIfNeeded() {
    final CipherController ctrl = widget.controller;

    if (ctrl.inputSyncVersion != _lastInputSyncVersion) {
      _lastInputSyncVersion = ctrl.inputSyncVersion;
      if (!_inputFocusNode.hasFocus && _inputController.text != ctrl.inputText) {
        _inputController.value = TextEditingValue(
          text: ctrl.inputText,
          selection: TextSelection.collapsed(offset: ctrl.inputText.length),
        );
      }
    }

    if (ctrl.keywordSyncVersion != _lastKeywordSyncVersion) {
      _lastKeywordSyncVersion = ctrl.keywordSyncVersion;
      if (!_keywordFocusNode.hasFocus &&
          _keywordController.text != ctrl.keywordText) {
        _keywordController.value = TextEditingValue(
          text: ctrl.keywordText,
          selection: TextSelection.collapsed(offset: ctrl.keywordText.length),
        );
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _inputController.dispose();
    _inputFocusNode.dispose();
    _keywordController.dispose();
    _keywordFocusNode.dispose();
    super.dispose();
  }

  void _runWithUnfocus(VoidCallback action) {
    FocusScope.of(context).unfocus();
    unawaited(
      Future<void>.microtask(() {
        if (mounted) {
          action();
        }
      }),
    );
  }

  void _executeCipher({required bool isEncrypt}) {
    FocusScope.of(context).unfocus();
    try {
      final CipherResult result =
          widget.controller.executeCipher(isEncrypt: isEncrypt);
      final String modeLabel = isEncrypt ? 'Enkripsi' : 'Dekripsi';
      showLabSnackBar(
        context,
        '$modeLabel selesai (${result.steps.length} blok diproses)',
      );
    } on ArgumentError catch (e) {
      showLabSnackBar(
        context,
        e.message?.toString() ?? 'Input tidak valid.',
        isError: true,
      );
    } catch (e) {
      showLabSnackBar(context, 'Terjadi kesalahan: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, _) {
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isWide = constraints.maxWidth >= 800;

            if (isWide) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _buildKeyPanel(context),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 6,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _buildMessagePanel(context),
                            const SizedBox(height: 16),
                            _buildOutputPanel(context),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildKeyPanel(context),
                    const SizedBox(height: 16),
                    _buildMessagePanel(context),
                    const SizedBox(height: 16),
                    _buildOutputPanel(context),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildKeyPanel(BuildContext context) {
    final LabColors colors = labColorsOf(context);
    final CipherController ctrl = widget.controller;
    final KeyAnalysisResult analysis = ctrl.keyAnalysis;
    final bool hasIncomplete = ctrl.hasIncompleteCells;
    final int requiredLetters = ctrl.order * ctrl.order;
    final Color statusAccent =
        (!hasIncomplete && analysis.isValid) ? colors.emerald : colors.rose;

    return LabSectionCard(
      title: 'Matriks Kunci (K)',
      subtitle: 'Ordo ${ctrl.order}×${ctrl.order} pada aritmetika mod 26',
      icon: Icons.grid_on_rounded,
      accentColor: statusAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Pemilih ordo 2x2 / 3x3 dan mode input Angka / Kata Kunci
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const <ButtonSegment<int>>[
                  ButtonSegment<int>(value: 2, label: Text('2×2')),
                  ButtonSegment<int>(value: 3, label: Text('3×3')),
                ],
                selected: <int>{ctrl.order},
                onSelectionChanged: (Set<int> selection) {
                  _runWithUnfocus(() => ctrl.setOrder(selection.first));
                },
              ),
              SegmentedButton<KeyInputMode>(
                showSelectedIcon: false,
                segments: const <ButtonSegment<KeyInputMode>>[
                  ButtonSegment<KeyInputMode>(
                    value: KeyInputMode.numbers,
                    icon: Icon(Icons.dialpad, size: 16),
                    label: Text('Angka'),
                  ),
                  ButtonSegment<KeyInputMode>(
                    value: KeyInputMode.keyword,
                    icon: Icon(Icons.abc, size: 16),
                    label: Text('Kata Kunci'),
                  ),
                ],
                selected: <KeyInputMode>{ctrl.keyInputMode},
                onSelectionChanged: (Set<KeyInputMode> selection) {
                  _runWithUnfocus(
                    () => ctrl.setKeyInputMode(selection.first),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Area input matriks: Mode Angka atau Mode Kata Kunci
          if (ctrl.keyInputMode == KeyInputMode.numbers)
            Center(
              child: MatrixGridWidget(
                order: ctrl.order,
                matrix: ctrl.editableMatrix,
                syncVersion: ctrl.keySyncVersion,
                accentColor: statusAccent,
                onCellChanged: ctrl.updateMatrixCell,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  controller: _keywordController,
                  focusNode: _keywordFocusNode,
                  maxLength: requiredLetters,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                    _UpperCaseTextFormatter(),
                  ],
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: colors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Masukkan $requiredLetters huruf kunci (A–Z)',
                    hintText: ctrl.order == 2 ? 'Contoh: HILL' : 'GYBNQKURP',
                    counterText:
                        '${ctrl.keywordText.length}/$requiredLetters huruf',
                    filled: true,
                    fillColor: colors.cardAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: statusAccent, width: 2),
                    ),
                  ),
                  onChanged: ctrl.updateFromKeyword,
                ),
                const SizedBox(height: 10),
                Center(
                  child: _NullableMatrixPreview(
                    order: ctrl.order,
                    matrix: ctrl.editableMatrix,
                    accentColor: statusAccent,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 16),

          // Tombol acak kunci valid
          OutlinedButton.icon(
            onPressed: () {
              _runWithUnfocus(() {
                ctrl.randomizeValidKey();
                showLabSnackBar(
                  context,
                  'Kunci acak ${ctrl.order}×${ctrl.order} yang valid berhasil dibuat',
                );
              });
            },
            icon: const Icon(Icons.casino_outlined),
            label: const Text('Acak Kunci Valid'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.cyan,
              side: BorderSide(color: colors.cyan.withAlpha(140)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Badge status validitas kunci real-time
          _KeyValidityBadge(
            analysis: analysis,
            hasIncompleteCells: hasIncomplete,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagePanel(BuildContext context) {
    final LabColors colors = labColorsOf(context);
    final CipherController ctrl = widget.controller;

    return LabSectionCard(
      title: 'Pesan Masukan',
      subtitle: 'Hanya huruf A–Z yang diproses oleh mesin Hill Cipher',
      icon: Icons.edit_note_rounded,
      accentColor: colors.cyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: _inputController,
            focusNode: _inputFocusNode,
            minLines: 3,
            maxLines: 6,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 15,
              color: colors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Ketik plaintext atau ciphertext di sini...',
              hintStyle: TextStyle(color: colors.textSecondary),
              filled: true,
              fillColor: colors.cardAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.cyan, width: 2),
              ),
            ),
            onChanged: ctrl.setInputText,
          ),
          const SizedBox(height: 10),

          // Saklar Smart Preserve Format Spasi & Kapitalisasi
          Container(
            decoration: BoxDecoration(
              color: colors.cardAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: SwitchListTile.adaptive(
              value: ctrl.preserveFormat,
              onChanged: ctrl.setPreserveFormat,
              title: Text(
                'Pertahankan Format Spasi (Smart Preserve)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Pertahankan posisi spasi, tanda baca, dan huruf besar/kecil asli',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 2,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Tombol Enkripsi, Dekripsi, dan Reset
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                onPressed: ctrl.canExecute
                    ? () => _executeCipher(isEncrypt: true)
                    : null,
                icon: const Icon(Icons.lock_outline_rounded),
                label: const Text('Enkripsi'),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.emerald,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: colors.border,
                  disabledForegroundColor: colors.textSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: ctrl.canExecute
                    ? () => _executeCipher(isEncrypt: false)
                    : null,
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text('Dekripsi'),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.cyan,
                  foregroundColor: const Color(0xFF0F172A),
                  disabledBackgroundColor: colors.border,
                  disabledForegroundColor: colors.textSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _runWithUnfocus(() {
                    ctrl.resetLab();
                    showLabSnackBar(context, 'Input dan hasil lab direset');
                  });
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reset'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textSecondary,
                  side: BorderSide(color: colors.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
          if (!ctrl.canExecute) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Tombol Enkripsi & Dekripsi dinonaktifkan otomatis hingga matriks kunci lengkap dan valid.',
              style: TextStyle(
                fontSize: 12,
                color: colors.rose,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOutputPanel(BuildContext context) {
    final LabColors colors = labColorsOf(context);
    final CipherController ctrl = widget.controller;
    final CipherResult? result = ctrl.lastResult;
    final KeyAnalysisResult analysis = ctrl.keyAnalysis;

    return LabSectionCard(
      title: 'Hasil Keluaran & Matriks Invers',
      subtitle: result == null
          ? 'Jalankan Enkripsi atau Dekripsi untuk melihat hasil'
          : '${result.isEncrypt ? 'Ciphertext' : 'Plaintext'} • ${result.steps.length} blok (${result.order}×${result.order})',
      icon: Icons.terminal_rounded,
      accentColor: result == null
          ? colors.emerald
          : (result.isEncrypt ? colors.emerald : colors.cyan),
      trailing: result == null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (result.isEncrypt ? colors.emerald : colors.cyan)
                    .withAlpha(32),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                result.isEncrypt ? 'ENKRIPSI' : 'DEKRIPSI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: result.isEncrypt ? colors.emerald : colors.cyan,
                ),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (result == null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.cardAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                'Belum ada output. Masukkan teks di atas lalu tekan Enkripsi atau Dekripsi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            )
          else ...<Widget>[
            // Kotak hasil teks output
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.cardAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (result.isEncrypt ? colors.emerald : colors.cyan)
                      .withAlpha(110),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SelectableText(
                    result.formattedOutput,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (result.formattedOutput != result.pureOutput) ...<Widget>[
                    const SizedBox(height: 8),
                    Divider(color: colors.border, height: 1),
                    const SizedBox(height: 8),
                    SelectableText(
                      'Murni A–Z: ${result.pureOutput}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Badge informasi padding apabila ada penambahan huruf 'X'
            if (result.paddingCount > 0) ...<Widget>[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.amber.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.amber.withAlpha(120)),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: colors.amber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "+${result.paddingCount} huruf padding 'X' ditambahkan agar kelipatan ordo (${result.order})",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Tombol Salin Hasil, Tukar ke Input, dan pintasan Bedah Rumus
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: () {
                    final String textToCopy = ctrl.preserveFormat
                        ? result.formattedOutput
                        : result.pureOutput;
                    unawaited(Clipboard.setData(ClipboardData(text: textToCopy)));
                    showLabSnackBar(context, 'Hasil disalin ke clipboard');
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Salin Hasil'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.emerald,
                    side: BorderSide(color: colors.emerald.withAlpha(140)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    _runWithUnfocus(() {
                      if (ctrl.swapOutputToInput()) {
                        showLabSnackBar(
                          context,
                          'Output dipindahkan ke kolom input untuk uji balik',
                        );
                      }
                    });
                  },
                  icon: const Icon(Icons.swap_vert_rounded, size: 18),
                  label: const Text('Tukar ke Input'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.cyan,
                    side: BorderSide(color: colors.cyan.withAlpha(140)),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => ctrl.setTabIndex(1),
                  icon: const Icon(Icons.functions_rounded, size: 18),
                  label: const Text('Lihat Bedah Rumus'),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ],

          // Ringkasan matriks invers K^-1
          if (analysis.isValid && analysis.inverseMatrix != null) ...<Widget>[
            const SizedBox(height: 16),
            Divider(color: colors.border, height: 1),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Ringkasan Matriks Invers K⁻¹ (mod 26)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.cyan,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dipakai otomatis saat proses Dekripsi:\nK⁻¹ = (${analysis.detInverse} × Adj(K)) mod 26',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ReadOnlyMatrixView(
                  matrix: analysis.inverseMatrix!,
                  accentColor: colors.cyan,
                  cellWidth: 36,
                  cellHeight: 30,
                  fontSize: 13,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _KeyValidityBadge extends StatelessWidget {
  const _KeyValidityBadge({
    required this.analysis,
    required this.hasIncompleteCells,
  });

  final KeyAnalysisResult analysis;
  final bool hasIncompleteCells;

  @override
  Widget build(BuildContext context) {
    final LabColors colors = labColorsOf(context);
    final bool isValid = !hasIncompleteCells && analysis.isValid;
    final Color badgeColor = isValid ? colors.emerald : colors.rose;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withAlpha(130)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            isValid ? Icons.verified_rounded : Icons.warning_amber_rounded,
            color: badgeColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  hasIncompleteCells
                      ? 'Matriks Belum Lengkap'
                      : (isValid
                          ? 'Kunci Valid (Invertible di mod 26)'
                          : 'Kunci Tidak Valid'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
                const SizedBox(height: 4),
                if (hasIncompleteCells)
                  Text(
                    analysis.errorMessage ??
                        'Isi seluruh sel matriks untuk menghitung determinan.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  )
                else if (isValid)
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: <Widget>[
                      Text(
                        'Det(K) = ${analysis.detRaw} ≡ ${analysis.detMod} (mod 26)',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        'Det⁻¹ mod 26 = ${analysis.detInverse}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.emerald,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Det(K) = ${analysis.detRaw} ≡ ${analysis.detMod} (mod 26)\n${analysis.errorMessage ?? ''}',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NullableMatrixPreview extends StatelessWidget {
  const _NullableMatrixPreview({
    required this.order,
    required this.matrix,
    required this.accentColor,
  });

  final int order;
  final List<List<int?>> matrix;
  final Color accentColor;

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
            for (int r = 0; r < order; r++)
              Padding(
                padding: EdgeInsets.only(bottom: r < order - 1 ? 6 : 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (int c = 0; c < order; c++)
                      Container(
                        width: 44,
                        height: 36,
                        margin: EdgeInsets.only(right: c < order - 1 ? 6 : 0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.cardAlt,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: matrix[r][c] == null
                                ? colors.rose
                                : accentColor.withAlpha(90),
                          ),
                        ),
                        child: Text(
                          matrix[r][c]?.toString() ?? '•',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: matrix[r][c] == null
                                ? colors.rose
                                : colors.textPrimary,
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

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
