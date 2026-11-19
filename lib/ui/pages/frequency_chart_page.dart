import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/frequency_analyzer.dart';
import '../../models/cipher_models.dart';
import '../../state/cipher_controller.dart';
import '../widgets/common_widgets.dart';

/// Tab 3 — Analisis Frekuensi: grafik batang ganda A–Z membandingkan distribusi
/// huruf `cleanedText` (sebelum) vs `pureOutput` (sesudah) serta Index of Coincidence.
class FrequencyChartPage extends StatelessWidget {
  const FrequencyChartPage({
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
            icon: Icons.bar_chart_rounded,
            title: 'Belum Ada Data Frekuensi',
            description:
                'Jalankan proses Enkripsi atau Dekripsi pada Tab Lab terlebih dahulu untuk membandingkan distribusi huruf A–Z sebelum dan sesudah proses.',
            actionLabel: 'Kembali ke Tab Lab',
            onAction: () => controller.setTabIndex(0),
          );
        }

        final LabColors colors = labColorsOf(context);
        final FrequencyAnalysisReport report = FrequencyAnalyzer.analyze(
          cleanedInput: result.cleanedText,
          pureOutput: result.pureOutput,
        );

        double maxPct = 0.0;
        for (int i = 0; i < 26; i++) {
          maxPct = math.max(maxPct, report.inputPercentages[i]);
          maxPct = math.max(maxPct, report.outputPercentages[i]);
        }
        final double chartCeilingPct = maxPct <= 0.0 ? 100.0 : maxPct;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Penjelasan 1 kalimat ringkas tentang perataan frekuensi Hill Cipher
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.cyan.withAlpha(24),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.cyan.withAlpha(110)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: colors.cyan,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Karena setiap huruf keluaran merupakan kombinasi linear dari satu blok huruf masukan (enkripsi poligrafik), huruf yang sama dapat terpetakan menjadi huruf berbeda di blok lain sehingga puncak frekuensi huruf tunggal menjadi lebih rata.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Kartu metrik ringkas
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool isWide = constraints.maxWidth >= 700;
                    final List<Widget> metricCards = <Widget>[
                      _SummaryMetricCard(
                        title: 'Total Huruf (A–Z)',
                        icon: Icons.text_fields_rounded,
                        accentColor: colors.textPrimary,
                        beforeLabel: 'Sebelum (cleaned)',
                        beforeValue: '${report.inputTotal} huruf',
                        afterLabel: 'Sesudah (pure)',
                        afterValue: '${report.outputTotal} huruf',
                      ),
                      _SummaryMetricCard(
                        title: 'Huruf Paling Dominan',
                        icon: Icons.leaderboard_rounded,
                        accentColor: colors.amber,
                        beforeLabel: 'Sebelum',
                        beforeValue: _formatDominant(
                          report.dominantInputLetters,
                          report.dominantInputCount,
                          report.inputTotal,
                        ),
                        afterLabel: 'Sesudah',
                        afterValue: _formatDominant(
                          report.dominantOutputLetters,
                          report.dominantOutputCount,
                          report.outputTotal,
                        ),
                      ),
                      _SummaryMetricCard(
                        title: 'Skor Kerataan (IoC)',
                        icon: Icons.balance_rounded,
                        accentColor: colors.emerald,
                        beforeLabel: 'Sebelum',
                        beforeValue: report.inputIoC.toStringAsFixed(4),
                        afterLabel: 'Sesudah (ideal ≈ 0.0385)',
                        afterValue: report.outputIoC.toStringAsFixed(4),
                      ),
                    ];

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(child: metricCards[0]),
                          const SizedBox(width: 12),
                          Expanded(child: metricCards[1]),
                          const SizedBox(width: 12),
                          Expanded(child: metricCards[2]),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        metricCards[0],
                        const SizedBox(height: 12),
                        metricCards[1],
                        const SizedBox(height: 12),
                        metricCards[2],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Grafik Batang Ganda A-Z (Murni Widget Flutter)
                LabSectionCard(
                  title: 'Distribusi Frekuensi Huruf A–Z',
                  subtitle:
                      'Sentuh atau arahkan kursor pada batang huruf untuk melihat jumlah dan persentase',
                  icon: Icons.bar_chart_rounded,
                  accentColor: colors.emerald,
                  trailing: _ChartLegend(
                    beforeColor: colors.cyan,
                    afterColor: colors.emerald,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(
                        height: 240,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            // Skala sumbu Y persentase
                            SizedBox(
                              width: 48,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 28),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    Text(
                                      '${chartCeilingPct.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '${(chartCeilingPct / 2).toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '0%',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Grafik horizontal scrollable 26 huruf A-Z
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: List<Widget>.generate(26, (int i) {
                                    final String letter =
                                        String.fromCharCode(65 + i);
                                    final int inCount = report.inputCounts[i];
                                    final int outCount = report.outputCounts[i];
                                    final double inPct =
                                        report.inputPercentages[i];
                                    final double outPct =
                                        report.outputPercentages[i];

                                    const double maxBarHeight = 176.0;
                                    final double inHeight =
                                        (inPct / chartCeilingPct) *
                                            maxBarHeight;
                                    final double outHeight =
                                        (outPct / chartCeilingPct) *
                                            maxBarHeight;

                                    return Tooltip(
                                      message:
                                          'Huruf $letter\nSebelum: $inCount (${inPct.toStringAsFixed(1)}%)\nSesudah: $outCount (${outPct.toStringAsFixed(1)}%)',
                                      child: Container(
                                        width: 34,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: <Widget>[
                                            SizedBox(
                                              height: maxBarHeight,
                                              child: Stack(
                                                alignment:
                                                    Alignment.bottomCenter,
                                                children: <Widget>[
                                                  // Garis dasar
                                                  Align(
                                                    alignment:
                                                        Alignment.bottomCenter,
                                                    child: Container(
                                                      height: 1,
                                                      color: colors.border,
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: <Widget>[
                                                      AnimatedContainer(
                                                        duration: const Duration(
                                                          milliseconds: 350,
                                                        ),
                                                        curve: Curves
                                                            .easeOutCubic,
                                                        width: 11,
                                                        height: inCount > 0
                                                            ? math.max(
                                                                inHeight, 4.0)
                                                            : 2.0,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: inCount > 0
                                                              ? colors.cyan
                                                              : colors.border
                                                                  .withAlpha(
                                                                  110,
                                                                ),
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .vertical(
                                                            top:
                                                                Radius.circular(
                                                              4,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 3),
                                                      AnimatedContainer(
                                                        duration: const Duration(
                                                          milliseconds: 350,
                                                        ),
                                                        curve: Curves
                                                            .easeOutCubic,
                                                        width: 11,
                                                        height: outCount > 0
                                                            ? math.max(
                                                                outHeight, 4.0)
                                                            : 2.0,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: outCount > 0
                                                              ? colors.emerald
                                                              : colors.border
                                                                  .withAlpha(
                                                                  110,
                                                                ),
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .vertical(
                                                            top:
                                                                Radius.circular(
                                                              4,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              letter,
                                              style: TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: (inCount > 0 ||
                                                        outCount > 0)
                                                    ? colors.textPrimary
                                                    : colors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ],
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
    );
  }

  static String _formatDominant(List<String> letters, int count, int total) {
    if (letters.isEmpty || total == 0) {
      return '-';
    }
    final double pct = (count / total) * 100.0;
    final String joined =
        letters.length <= 3 ? letters.join(', ') : '${letters.take(3).join(', ')}…';
    return '$joined ($count× • ${pct.toStringAsFixed(1)}%)';
  }
}

class _SummaryMetricCard extends StatelessWidget {
  const _SummaryMetricCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.beforeLabel,
    required this.beforeValue,
    required this.afterLabel,
    required this.afterValue,
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final String beforeLabel;
  final String beforeValue;
  final String afterLabel;
  final String afterValue;

  @override
  Widget build(BuildContext context) {
    final LabColors colors = labColorsOf(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 17, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            beforeLabel,
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
          ),
          Text(
            beforeValue,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.cyan,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            afterLabel,
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
          ),
          Text(
            afterValue,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.emerald,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({
    required this.beforeColor,
    required this.afterColor,
  });

  final Color beforeColor;
  final Color afterColor;

  @override
  Widget build(BuildContext context) {
    final LabColors colors = labColorsOf(context);
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: beforeColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'Sebelum',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: afterColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'Sesudah',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}
