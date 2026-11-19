import 'hill_cipher_engine.dart';

/// Laporan statistik frekuensi kemunculan huruf A-Z antara teks masukan (bersih)
/// dan teks keluaran murni (tanpa spasi/format).
class FrequencyAnalysisReport {
  const FrequencyAnalysisReport({
    required this.inputCounts,
    required this.outputCounts,
    required this.inputPercentages,
    required this.outputPercentages,
    required this.inputTotal,
    required this.outputTotal,
    required this.dominantInputLetters,
    required this.dominantInputCount,
    required this.dominantOutputLetters,
    required this.dominantOutputCount,
    required this.inputIoC,
    required this.outputIoC,
  });

  /// Jumlah kemunculan masing-masing huruf A..Z (indeks 0..25) pada teks masukan bersih.
  final List<int> inputCounts;

  /// Jumlah kemunculan masing-masing huruf A..Z (indeks 0..25) pada teks keluaran murni.
  final List<int> outputCounts;

  /// Persentase kemunculan huruf A..Z (0..100) pada teks masukan bersih.
  final List<double> inputPercentages;

  /// Persentase kemunculan huruf A..Z (0..100) pada teks keluaran murni.
  final List<double> outputPercentages;

  /// Total huruf alfabet pada teks masukan bersih.
  final int inputTotal;

  /// Total huruf alfabet pada teks keluaran murni.
  final int outputTotal;

  /// Daftar huruf paling dominan (termasuk jika seri) pada teks masukan.
  final List<String> dominantInputLetters;

  /// Frekuensi tertinggi pada teks masukan.
  final int dominantInputCount;

  /// Daftar huruf paling dominan (termasuk jika seri) pada teks keluaran.
  final List<String> dominantOutputLetters;

  /// Frekuensi tertinggi pada teks keluaran.
  final int dominantOutputCount;

  /// Index of Coincidence (IoC) teks masukan (nilai ideal acak/rata ≈ 0.0385).
  final double inputIoC;

  /// Index of Coincidence (IoC) teks keluaran (nilai lebih rendah menandakan lebih rata).
  final double outputIoC;
}

/// Penganalisis frekuensi huruf A-Z dan Index of Coincidence untuk membandingkan
/// distribusi karakter sebelum dan sesudah proses Hill Cipher.
class FrequencyAnalyzer {
  const FrequencyAnalyzer._();

  /// Menghitung perbandingan frekuensi huruf A-Z antara [cleanedInput] dan [pureOutput].
  static FrequencyAnalysisReport analyze({
    required String cleanedInput,
    required String pureOutput,
  }) {
    final String normalizedIn = HillCipherEngine.sanitizeAlphabet(cleanedInput);
    final String normalizedOut = HillCipherEngine.sanitizeAlphabet(pureOutput);

    final List<int> inputCounts = _countLetters(normalizedIn);
    final List<int> outputCounts = _countLetters(normalizedOut);

    final int inputTotal = normalizedIn.length;
    final int outputTotal = normalizedOut.length;

    final List<double> inputPercentages = _toPercentages(inputCounts, inputTotal);
    final List<double> outputPercentages =
        _toPercentages(outputCounts, outputTotal);

    final _DominantResult domInput = _findDominant(inputCounts);
    final _DominantResult domOutput = _findDominant(outputCounts);

    return FrequencyAnalysisReport(
      inputCounts: inputCounts,
      outputCounts: outputCounts,
      inputPercentages: inputPercentages,
      outputPercentages: outputPercentages,
      inputTotal: inputTotal,
      outputTotal: outputTotal,
      dominantInputLetters: domInput.letters,
      dominantInputCount: domInput.maxCount,
      dominantOutputLetters: domOutput.letters,
      dominantOutputCount: domOutput.maxCount,
      inputIoC: calculateIndexOfCoincidence(inputCounts, inputTotal),
      outputIoC: calculateIndexOfCoincidence(outputCounts, outputTotal),
    );
  }

  /// Menghitung frekuensi kemunculan 26 huruf kapital A-Z.
  static List<int> _countLetters(String uppercaseAlphabetText) {
    final List<int> counts = List<int>.filled(26, 0);
    for (final int unit in uppercaseAlphabetText.codeUnits) {
      final int idx = unit - 65;
      if (idx >= 0 && idx < 26) {
        counts[idx]++;
      }
    }
    return counts;
  }

  /// Mengonversi daftar hitungan huruf menjadi persentase 0.0..100.0.
  static List<double> _toPercentages(List<int> counts, int total) {
    if (total == 0) {
      return List<double>.filled(26, 0.0);
    }
    return counts
        .map((int count) => (count / total) * 100.0)
        .toList(growable: false);
  }

  /// Menemukan huruf dengan kemunculan terbanyak beserta nilai hitungannya.
  static _DominantResult _findDominant(List<int> counts) {
    int maxCount = 0;
    for (final int count in counts) {
      if (count > maxCount) {
        maxCount = count;
      }
    }
    if (maxCount == 0) {
      return const _DominantResult(letters: <String>[], maxCount: 0);
    }

    final List<String> letters = <String>[];
    for (int i = 0; i < 26; i++) {
      if (counts[i] == maxCount) {
        letters.add(String.fromCharCode(65 + i));
      }
    }
    return _DominantResult(letters: letters, maxCount: maxCount);
  }

  /// Menghitung Index of Coincidence (IoC):
  /// `IoC = sum(n_i * (n_i - 1)) / (N * (N - 1))`
  ///
  /// Nilai IoC teks alami bahasa Indonesia/Inggris umumnya sekitar 0.065 - 0.075,
  /// sedangkan distribusi acak/seragam 26 huruf mendekati 1/26 ≈ 0.0385.
  static double calculateIndexOfCoincidence(List<int> counts, int total) {
    if (total <= 1) {
      return 0.0;
    }

    int numerator = 0;
    for (final int count in counts) {
      numerator += count * (count - 1);
    }

    final int denominator = total * (total - 1);
    return numerator / denominator;
  }
}

class _DominantResult {
  const _DominantResult({
    required this.letters,
    required this.maxCount,
  });

  final List<String> letters;
  final int maxCount;
}
