/// Mode pengisian matriks kunci pada Lab Kriptografi.
enum KeyInputMode {
  numbers,
  keyword,
}

/// Hasil analisis matematis terhadap matriks kunci Hill Cipher (ordo 2x2 atau 3x3).
class KeyAnalysisResult {
  const KeyAnalysisResult({
    required this.order,
    required this.matrix,
    required this.detRaw,
    required this.detMod,
    required this.detInverse,
    required this.adjugateMatrix,
    required this.inverseMatrix,
    required this.isValid,
    required this.errorMessage,
  });

  /// Ordo matriks persegi (2 untuk 2x2, 3 untuk 3x3).
  final int order;

  /// Matriks kunci K yang sudah dinormalisasi ke modulo 26 (rentang 0..25).
  final List<List<int>> matrix;

  /// Determinan mentah matriks sebelum dikenakan operasi modulo 26.
  final int detRaw;

  /// Determinan matriks setelah dinormalisasi dengan mod 26 (rentang 0..25).
  final int detMod;

  /// Invers perkalian modular dari detMod terhadap 26 (null jika tidak ada).
  final int? detInverse;

  /// Matriks adjoin Adj(K) mod 26 (null jika kunci tidak valid).
  final List<List<int>>? adjugateMatrix;

  /// Matriks kunci invers K^-1 mod 26 untuk proses dekripsi (null jika tidak valid).
  final List<List<int>>? inverseMatrix;

  /// Menandakan apakah matriks kunci valid dan dapat diinvers di Z_26.
  final bool isValid;

  /// Pesan error berbahasa Indonesia apabila kunci tidak valid.
  final String? errorMessage;

  /// Membuat representasi analisis tidak valid saat masih ada sel matriks kosong.
  factory KeyAnalysisResult.incomplete({
    required int order,
    required List<List<int?>> editableMatrix,
  }) {
    final List<List<int>> preview = List<List<int>>.generate(
      order,
      (int r) => List<int>.generate(
        order,
        (int c) => editableMatrix[r][c] ?? 0,
      ),
    );
    return KeyAnalysisResult(
      order: order,
      matrix: preview,
      detRaw: 0,
      detMod: 0,
      detInverse: null,
      adjugateMatrix: null,
      inverseMatrix: null,
      isValid: false,
      errorMessage:
          'Masih ada sel matriks yang kosong. Lengkapi seluruh angka terlebih dahulu.',
    );
  }
}

/// Rincian langkah perkalian matriks untuk 1 blok huruf (2 atau 3 huruf).
class BlockStep {
  const BlockStep({
    required this.blockIndex,
    required this.inputChars,
    required this.inputVector,
    required this.rawResults,
    required this.modResults,
    required this.outputChars,
    required this.equationText,
  });

  /// Indeks blok berbasis 0 (0, 1, 2, ...).
  final int blockIndex;

  /// Potongan huruf masukan pada blok ini (sudah huruf kapital A-Z).
  final String inputChars;

  /// Representasi vektor numerik (A=0 .. Z=25) dari inputChars.
  final List<int> inputVector;

  /// Hasil perkalian baris x kolom sebelum operasi modulo 26.
  final List<int> rawResults;

  /// Hasil akhir tiap komponen vektor setelah operasi modulo 26 (0..25).
  final List<int> modResults;

  /// Huruf keluaran (A-Z) hasil konversi modResults.
  final String outputChars;

  /// Jabaran teks rumus perkalian baris x kolom untuk Tab Bedah Rumus.
  final String equationText;
}

/// Hasil lengkap proses enkripsi atau dekripsi Hill Cipher.
class CipherResult {
  const CipherResult({
    required this.isEncrypt,
    required this.order,
    required this.originalInput,
    required this.cleanedText,
    required this.paddedText,
    required this.paddingCount,
    required this.pureOutput,
    required this.formattedOutput,
    required this.keyAnalysis,
    required this.steps,
    required this.timestamp,
  });

  /// true jika operasi enkripsi, false jika operasi dekripsi.
  final bool isEncrypt;

  /// Ordo matriks kunci yang digunakan (2 atau 3).
  final int order;

  /// Teks asli persis seperti yang dimasukkan pengguna.
  final String originalInput;

  /// Teks alfabet A-Z murni hasil sanitasi tanpa spasi/tanda baca dan tanpa padding.
  final String cleanedText;

  /// Teks alfabet A-Z setelah penambahan padding 'X' (jika diperlukan saat enkripsi).
  final String paddedText;

  /// Jumlah huruf padding 'X' yang ditambahkan (0 jika tidak ada padding).
  final int paddingCount;

  /// Keluaran huruf kapital A-Z murni tanpa spasi/format.
  final String pureOutput;

  /// Keluaran dengan posisi spasi, tanda baca, dan kapitalisasi asli (jika Smart Preserve aktif).
  final String formattedOutput;

  /// Hasil analisis matriks kunci yang digunakan pada operasi ini.
  final KeyAnalysisResult keyAnalysis;

  /// Daftar langkah perkalian matriks per blok untuk visualisasi di Tab Bedah Rumus.
  final List<BlockStep> steps;

  /// Waktu eksekusi operasi.
  final DateTime timestamp;
}

/// Item riwayat operasi enkripsi/dekripsi yang disimpan di RAM selama sesi berjalan.
class HistoryItem {
  const HistoryItem({
    required this.id,
    required this.result,
    required this.preserveFormat,
  });

  /// Pengenal unik item riwayat pada sesi RAM.
  final String id;

  /// Hasil proses cipher yang direkam.
  final CipherResult result;

  /// Status saklar Smart Preserve saat operasi dilakukan.
  final bool preserveFormat;
}

/// Preset matriks kunci bawaan maupun yang disimpan pengguna selama sesi RAM.
class KeyPreset {
  const KeyPreset({
    required this.id,
    required this.name,
    required this.order,
    required this.matrix,
    this.keyword,
    required this.description,
    this.isBuiltIn = true,
  });

  /// Pengenal unik preset.
  final String id;

  /// Nama tampilan preset kunci.
  final String name;

  /// Ordo matriks kunci (2 atau 3).
  final int order;

  /// Matriks kunci bernilai integer.
  final List<List<int>> matrix;

  /// Representasi kata kunci jika berasal dari kata (opsional).
  final String? keyword;

  /// Keterangan singkat preset (misalnya nilai determinan).
  final String description;

  /// true jika preset bawaan aplikasi, false jika disimpan oleh pengguna di sesi RAM.
  final bool isBuiltIn;
}
