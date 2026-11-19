import 'package:flutter/material.dart';

import '../../models/cipher_models.dart';
import '../../state/cipher_controller.dart';
import '../widgets/common_widgets.dart';

/// Tab 2 — Bedah Rumus: menjabarkan transformasi teks, determinan, adjoin,
/// matriks invers K^-1, dan rincian perkalian baris x kolom per blok secara lazy.
class MathInspectorPage extends StatelessWidget {
  const MathInspectorPage({
    super.key,
    required this.controller,
  });

  final CipherController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, _) {
        final CipherResult? result = controller.lastResult;
        if (result == null) {
          return LabEmptyState(
            icon: Icons.functions_rounded,
            title: 'Belum Ada Proses untuk Dibedah',
            description:
                'Jalankan proses Enkripsi atau Dekripsi pada Tab Lab terlebih dahulu agar rincian determinan, adjoin, K⁻¹, dan perkalian per blok dapat ditampilkan di sini.',
            actionLabel: 'Kembali ke Tab Lab',
            onAction: () => controller.setTabIndex(0),
          );
        }

        final LabColors colors = labColorsOf(context);
        final KeyAnalysisResult analysis = result.keyAnalysis;
        final Color modeColor =
            result.isEncrypt ? colors.emerald : colors.cyan;

        return SafeArea(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // 1. Kartu Transformasi Teks & Rumus Utama
                      LabSectionCard(
                        title: 'Transformasi Teks & Rumus Aktif',
                        subtitle: result.isEncrypt
                            ? 'Enkripsi: C = (K × P) mod 26'
                            : 'Dekripsi: P = (K⁻¹ × C) mod 26',
                        icon: Icons.transform_rounded,
                        accentColor: modeColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _StepFlowRow(
                              label: '1. Input Asli',
                              value: result.originalInput,
                              badge: '${result.originalInput.length} kar',
                              badgeColor: colors.textSecondary,
                            ),
                            const SizedBox(height: 8),
                            _StepFlowRow(
                              label: '2. Sanitasi (A–Z)',
                              value: result.cleanedText,
                              badge: '${result.cleanedText.length} huruf',
                              badgeColor: colors.cyan,
                            ),
                            const SizedBox(height: 8),
                            _StepFlowRow(
                              label: '3. Padded Blok (${result.order}×${result.order})',
                              value: result.paddedText,
                              badge: result.paddingCount > 0
                                  ? '+${result.paddingCount} \'X\''
                                  : 'Pas (${result.steps.length} blok)',
                              badgeColor: result.paddingCount > 0
                                  ? colors.amber
                                  : colors.emerald,
                            ),
                            const SizedBox(height: 8),
                            _StepFlowRow(
                              label: '4. Output Murni',
                              value: result.pureOutput,
                              badge: '${result.pureOutput.length} huruf',
                              badgeColor: modeColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Kartu Analisis Determinan, Adjoin, dan Matriks Invers K^-1
                      LabSectionCard(
                        title: 'Analisis Matriks Kunci & Invers mod 26',
                        subtitle:
                            'Kunci ${analysis.order}×${analysis.order} yang dinormalisasi ke rentang 0..25',
                        icon: Icons.calculate_outlined,
                        accentColor: colors.cyan,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            // Ringkasan angka determinan dan invers modular
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colors.cardAlt,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.border),
                              ),
                              child: Wrap(
                                spacing: 18,
                                runSpacing: 10,
                                children: <Widget>[
                                  _MetricChip(
                                    label: 'Determinan Mentah (detRaw)',
                                    value: '${analysis.detRaw}',
                                    color: colors.textPrimary,
                                  ),
                                  _MetricChip(
                                    label: 'detMod = detRaw mod 26',
                                    value: '${analysis.detMod}',
                                    color: colors.emerald,
                                  ),
                                  _MetricChip(
                                    label: 'det⁻¹ mod 26',
                                    value: '${analysis.detInverse}',
                                    color: colors.cyan,
                                  ),
                                  _MetricChip(
                                    label: 'Verifikasi',
                                    value:
                                        '(${analysis.detMod} × ${analysis.detInverse}) mod 26 = 1',
                                    color: colors.amber,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Tiga matriks berdampingan (Wrap agar responsif di layar sempit)
                            Wrap(
                              spacing: 20,
                              runSpacing: 16,
                              alignment: WrapAlignment.spaceAround,
                              children: <Widget>[
                                _LabeledMatrixBlock(
                                  title: 'Matriks Kunci (K)',
                                  subtitle: result.isEncrypt
                                      ? 'Dipakai untuk Enkripsi'
                                      : 'Kunci Asal',
                                  matrix: analysis.matrix,
                                  accentColor: colors.emerald,
                                ),
                                if (analysis.adjugateMatrix != null)
                                  _LabeledMatrixBlock(
                                    title: 'Matriks Adjoin Adj(K)',
                                    subtitle: analysis.order == 3
                                        ? 'Minor → Kofaktor → Transpose'
                                        : '[[d, -b], [-c, a]] mod 26',
                                    matrix: analysis.adjugateMatrix!,
                                    accentColor: colors.amber,
                                  ),
                                if (analysis.inverseMatrix != null)
                                  _LabeledMatrixBlock(
                                    title: 'Matriks Invers (K⁻¹)',
                                    subtitle: !result.isEncrypt
                                        ? 'Dipakai untuk Dekripsi'
                                        : '(${analysis.detInverse} × Adj(K)) mod 26',
                                    matrix: analysis.inverseMatrix!,
                                    accentColor: colors.cyan,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Header daftar langkah per blok (lazy via SliverList.builder)
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.view_list_rounded,
                            size: 20,
                            color: modeColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Rincian Perkalian Matriks Per Blok (${result.steps.length} Blok)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ketuk tiap blok untuk melihat jabaran perkalian baris × kolom modulo 26.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Daftar lazy langkah per blok — anti-lag meskipun teks sangat panjang
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                sliver: SliverList.builder(
                  itemCount: result.steps.length,
                  itemBuilder: (BuildContext context, int index) {
                    final BlockStep step = result.steps[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.border),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: index == 0,
                          shape: const Border(),
                          collapsedShape: const Border(),
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            14,
                            0,
                            14,
                            14,
                          ),
                          leading: Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: modeColor.withAlpha(32),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${step.blockIndex + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: modeColor,
                              ),
                            ),
                          ),
                          title: Text(
                            'Blok #${step.blockIndex + 1}: "${step.inputChars}" → "${step.outputChars}"',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'Vektor [${step.inputVector.join(', ')}] → mod 26 [${step.modResults.join(', ')}]',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                          children: <Widget>[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colors.cardAlt,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: colors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Pemetaan Masukan: ${_formatCharVector(step.inputChars, step.inputVector)}',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: colors.cyan,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SelectableText(
                                    step.equationText,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12.5,
                                      height: 1.55,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Hasil Mentah: [${step.rawResults.join(', ')}]  •  Hasil Blok: "${step.outputChars}"',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: modeColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatCharVector(String chars, List<int> vector) {
    final List<String> pairs = <String>[];
    for (int i = 0; i < chars.length && i < vector.length; i++) {
      pairs.add('${chars[i]}=${vector[i]}');
    }
    return pairs.join(', ');
  }
}

class _StepFlowRow extends StatelessWidget {
  const _StepFlowRow({
    required this.label,
    required this.value,
    required this.badge,
    required this.badgeColor,
  });

  final String label;
  final String value;
  final String badge;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    final LabColors colors = labColorsOf(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.cardAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final LabColors colors = labColorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _LabeledMatrixBlock extends StatelessWidget {
  const _LabeledMatrixBlock({
    required this.title,
    required this.subtitle,
    required this.matrix,
    required this.accentColor,
  });

  final String title;
  final String subtitle;
  final List<List<int>> matrix;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final LabColors colors = labColorsOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ReadOnlyMatrixView(
          matrix: matrix,
          accentColor: accentColor,
        ),
      ],
    );
  }
}
