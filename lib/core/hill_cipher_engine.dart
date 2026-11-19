import '../models/cipher_models.dart';

/// Mesin kriptografi Hill Cipher murni Dart untuk ordo matriks 2x2 dan 3x3
/// pada ruang aritmetika modulo 26 (alfabet A-Z = 0..25).
class HillCipherEngine {
  const HillCipherEngine._();

  /// Menghitung sisa bagi modulo 26 yang selalu berada pada rentang 0..25.
  ///
  /// Rumus `((n % 26) + 26) % 26` memastikan bilangan negatif tetap menghasilkan
  /// residu positif yang valid dalam aritmetika modular Z_26 (contoh: -3 -> 23).
  static int mod26(int n) => ((n % 26) + 26) % 26;

  /// Mengecek apakah kode Unicode merupakan huruf alfabet ASCII A-Z atau a-z.
  static bool _isAsciiLetter(int rune) =>
      (rune >= 65 && rune <= 90) || (rune >= 97 && rune <= 122);

  /// Mengecek apakah kode Unicode merupakan huruf kapital ASCII A-Z.
  static bool _isUpperCaseAscii(int rune) => rune >= 65 && rune <= 90;

  /// Membersihkan teks masukan sehingga hanya menyisakan huruf kapital A-Z.
  static String sanitizeAlphabet(String input) {
    final StringBuffer buffer = StringBuffer();
    for (final int rune in input.runes) {
      if (rune >= 65 && rune <= 90) {
        buffer.writeCharCode(rune);
      } else if (rune >= 97 && rune <= 122) {
        // Konversi huruf kecil (97..122) menjadi kapital (65..90).
        buffer.writeCharCode(rune - 32);
      }
    }
    return buffer.toString();
  }

  /// Menganalisis validitas matriks kunci Hill Cipher (2x2 atau 3x3) di mod 26.
  ///
  /// Tahapan perhitungan:
  /// 1. Normalisasi seluruh elemen matriks dengan `mod26`.
  /// 2. Hitung determinan mentah (2x2: a*d - b*c; 3x3: ekspansi kofaktor baris pertama).
  /// 3. Cari invers perkalian modular `detInv` di rentang 1..25 sehingga `(detMod * detInv) mod 26 == 1`.
  /// 4. Jika `detInv` tidak ada (detMod bernilai 0, genap, atau 13), matriks tidak dapat diinvers.
  /// 5. Hitung matriks adjoin (untuk 3x3: minor -> pola tanda kofaktor -> transpose).
  /// 6. Kalikan adjoin dengan `detInv` lalu kenakan `mod26` untuk memperoleh matriks invers K^-1.
  static KeyAnalysisResult analyzeKey(List<List<int>> rawMatrix) {
    final int order = rawMatrix.length;
    if (order != 2 && order != 3) {
      return KeyAnalysisResult(
        order: order,
        matrix: rawMatrix,
        detRaw: 0,
        detMod: 0,
        detInverse: null,
        adjugateMatrix: null,
        inverseMatrix: null,
        isValid: false,
        errorMessage: 'Ordo matriks kunci harus 2x2 atau 3x3.',
      );
    }

    for (final List<int> row in rawMatrix) {
      if (row.length != order) {
        return KeyAnalysisResult(
          order: order,
          matrix: rawMatrix,
          detRaw: 0,
          detMod: 0,
          detInverse: null,
          adjugateMatrix: null,
          inverseMatrix: null,
          isValid: false,
          errorMessage: 'Matriks kunci harus berbentuk persegi ${order}x$order.',
        );
      }
    }

    // 1. Normalisasi setiap elemen matriks kunci ke rentang 0..25.
    final List<List<int>> matrix = List<List<int>>.generate(
      order,
      (int r) => List<int>.generate(
        order,
        (int c) => mod26(rawMatrix[r][c]),
      ),
    );

    // 2. Hitung determinan mentah sesuai ordo matriks.
    final int detRaw;
    if (order == 2) {
      // Determinan 2x2: (a * d) - (b * c)
      detRaw = (matrix[0][0] * matrix[1][1]) - (matrix[0][1] * matrix[1][0]);
    } else {
      // Determinan 3x3 menggunakan ekspansi kofaktor baris pertama:
      // det = a(ei - fh) - b(di - fg) + c(dh - eg)
      final int a = matrix[0][0];
      final int b = matrix[0][1];
      final int c = matrix[0][2];
      final int d = matrix[1][0];
      final int e = matrix[1][1];
      final int f = matrix[1][2];
      final int g = matrix[2][0];
      final int h = matrix[2][1];
      final int i = matrix[2][2];
      detRaw = a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g);
    }

    // 3. Normalisasi determinan dengan modulo 26.
    final int detMod = mod26(detRaw);

    // 4. Cari modular multiplicative inverse (detInv) dengan mencoba x = 1..25.
    // Syarat eksistensi invers di mod 26 adalah FPB(detMod, 26) == 1.
    int? detInverse;
    for (int x = 1; x < 26; x++) {
      if (mod26(detMod * x) == 1) {
        detInverse = x;
        break;
      }
    }

    // Jika detInverse tidak ditemukan (detMod == 0, bilangan genap, atau 13), kunci invalid.
    if (detInverse == null) {
      final String reason;
      if (detMod == 0) {
        reason =
            'Determinan mod 26 bernilai 0, sehingga matriks singular dan tidak memiliki invers di mod 26.';
      } else if (detMod % 2 == 0) {
        reason =
            'Determinan mod 26 bernilai $detMod (bilangan genap), tidak relatif prima terhadap 26 (FPB($detMod, 26) ≠ 1).';
      } else {
        reason =
            'Determinan mod 26 bernilai 13 yang membagi habis 26 (FPB(13, 26) = 13), sehingga tidak memiliki invers.';
      }
      return KeyAnalysisResult(
        order: order,
        matrix: matrix,
        detRaw: detRaw,
        detMod: detMod,
        detInverse: null,
        adjugateMatrix: null,
        inverseMatrix: null,
        isValid: false,
        errorMessage: reason,
      );
    }

    // 5. Hitung matriks adjoin mod 26.
    final List<List<int>> adjugateMatrix;
    if (order == 2) {
      // Adjoin 2x2: [[d, -b], [-c, a]] lalu dikenakan mod 26.
      adjugateMatrix = <List<int>>[
        <int>[mod26(matrix[1][1]), mod26(-matrix[0][1])],
        <int>[mod26(-matrix[1][0]), mod26(matrix[0][0])],
      ];
    } else {
      // Adjoin 3x3:
      // Langkah A: Hitung matriks minor 3x3 (determinan submatriks 2x2).
      final List<List<int>> minors = List<List<int>>.generate(3, (int r) {
        return List<int>.generate(3, (int c) {
          final List<int> subRows = <int>[
            for (int i = 0; i < 3; i++)
              if (i != r) i,
          ];
          final List<int> subCols = <int>[
            for (int j = 0; j < 3; j++)
              if (j != c) j,
          ];
          return (matrix[subRows[0]][subCols[0]] *
                  matrix[subRows[1]][subCols[1]]) -
              (matrix[subRows[0]][subCols[1]] *
                  matrix[subRows[1]][subCols[0]]);
        });
      });

      // Langkah B: Terapkan pola tanda kofaktor [[+, -, +], [-, +, -], [+, -, +]].
      final List<List<int>> cofactors = List<List<int>>.generate(3, (int r) {
        return List<int>.generate(3, (int c) {
          final int sign = ((r + c) % 2 == 0) ? 1 : -1;
          return sign * minors[r][c];
        });
      });

      // Langkah C: TRANSPOSE baris menjadi kolom (adj[r][c] = cofactors[c][r])
      // dan normalkan ke mod 26.
      adjugateMatrix = List<List<int>>.generate(3, (int r) {
        return List<int>.generate(3, (int c) => mod26(cofactors[c][r]));
      });
    }

    // 6. Hitung matriks invers kunci: K^-1 = (detInv * Adj(K)) mod 26.
    final int validDetInverse = detInverse;
    final List<List<int>> inverseMatrix = List<List<int>>.generate(
      order,
      (int r) => List<int>.generate(
        order,
        (int c) => mod26(validDetInverse * adjugateMatrix[r][c]),
      ),
    );

    return KeyAnalysisResult(
      order: order,
      matrix: matrix,
      detRaw: detRaw,
      detMod: detMod,
      detInverse: detInverse,
      adjugateMatrix: adjugateMatrix,
      inverseMatrix: inverseMatrix,
      isValid: true,
      errorMessage: null,
    );
  }

  /// Menjalankan proses enkripsi (`isEncrypt: true`) atau dekripsi (`isEncrypt: false`)
  /// menggunakan matriks kunci `keyMatrix`.
  ///
  /// Melempar `ArgumentError` apabila:
  /// - Matriks kunci tidak valid di mod 26.
  /// - Teks masukan tidak memiliki huruf alfabet A-Z.
  /// - Mode dekripsi menerima ciphertext yang panjang hurufnya bukan kelipatan ordo matriks.
  static CipherResult process({
    required String inputText,
    required List<List<int>> keyMatrix,
    required bool isEncrypt,
    bool preserveFormat = false,
  }) {
    // Validasi kunci terlebih dahulu untuk memastikan matriks invertible di Z_26.
    final KeyAnalysisResult keyAnalysis = analyzeKey(keyMatrix);
    if (!keyAnalysis.isValid) {
      throw ArgumentError(
        keyAnalysis.errorMessage ?? 'Matriks kunci tidak valid.',
      );
    }

    // Sanitasi teks masukan menjadi huruf kapital A-Z murni.
    final String cleanedText = sanitizeAlphabet(inputText);
    if (cleanedText.isEmpty) {
      throw ArgumentError('Masukkan minimal 1 huruf alfabet A-Z');
    }

    final int order = keyAnalysis.order;
    final int paddingCount;
    final String paddedText;

    if (isEncrypt) {
      // Pada enkripsi, jika panjang teks belum kelipatan ordo, tambahkan padding 'X'.
      final int remainder = cleanedText.length % order;
      paddingCount = remainder == 0 ? 0 : order - remainder;
      paddedText = '$cleanedText${'X' * paddingCount}';
    } else {
      // Pada dekripsi, panjang ciphertext wajib kelipatan ordo agar blok utuh.
      if (cleanedText.length % order != 0) {
        throw ArgumentError('Panjang ciphertext harus kelipatan $order');
      }
      paddingCount = 0;
      paddedText = cleanedText;
    }

    // Pilih matriks K untuk enkripsi atau matriks invers K^-1 untuk dekripsi.
    final List<List<int>> activeMatrix =
        isEncrypt ? keyAnalysis.matrix : keyAnalysis.inverseMatrix!;

    final List<BlockStep> steps = <BlockStep>[];
    final StringBuffer pureOutputBuffer = StringBuffer();

    // Iterasi blok demi blok berukuran `order` huruf.
    for (int offset = 0; offset < paddedText.length; offset += order) {
      final int blockIndex = offset ~/ order;
      final String blockChars = paddedText.substring(offset, offset + order);
      final List<int> inputVector = blockChars.codeUnits
          .map((int codeUnit) => codeUnit - 65)
          .toList(growable: false);

      final List<int> rawResults = <int>[];
      final List<int> modResults = <int>[];
      final StringBuffer outCharsBuffer = StringBuffer();
      final StringBuffer equationBuffer = StringBuffer();

      // Perkalian matriks aktif (baris r) dengan vektor kolom masukan.
      for (int r = 0; r < order; r++) {
        int rawSum = 0;
        final List<String> termStrings = <String>[];

        for (int c = 0; c < order; c++) {
          final int kVal = activeMatrix[r][c];
          final int pVal = inputVector[c];
          rawSum += kVal * pVal;
          termStrings.add('($kVal × $pVal)');
        }

        final int modVal = mod26(rawSum);
        final String outChar = String.fromCharCode(modVal + 65);

        rawResults.add(rawSum);
        modResults.add(modVal);
        outCharsBuffer.write(outChar);

        if (r > 0) {
          equationBuffer.writeln();
        }
        equationBuffer.write(
          'Baris ${r + 1}: ${termStrings.join(' + ')} = $rawSum ≡ $modVal (mod 26) → $outChar',
        );
      }

      final String blockOutChars = outCharsBuffer.toString();
      pureOutputBuffer.write(blockOutChars);

      steps.add(
        BlockStep(
          blockIndex: blockIndex,
          inputChars: blockChars,
          inputVector: inputVector,
          rawResults: rawResults,
          modResults: modResults,
          outputChars: blockOutChars,
          equationText: equationBuffer.toString(),
        ),
      );
    }

    final String pureOutput = pureOutputBuffer.toString();

    // Bentuk formattedOutput sesuai mode Smart Preserve.
    final String formattedOutput;
    if (!preserveFormat) {
      formattedOutput = pureOutput;
    } else {
      formattedOutput = _applySmartFormat(
        originalInput: inputText,
        pureOutput: pureOutput,
      );
    }

    return CipherResult(
      isEncrypt: isEncrypt,
      order: order,
      originalInput: inputText,
      cleanedText: cleanedText,
      paddedText: paddedText,
      paddingCount: paddingCount,
      pureOutput: pureOutput,
      formattedOutput: formattedOutput,
      keyAnalysis: keyAnalysis,
      steps: steps,
      timestamp: DateTime.now(),
    );
  }

  /// Mengembalikan posisi spasi, tanda baca, dan kapitalisasi sesuai teks asli,
  /// lalu menempelkan sisa karakter hasil padding 'X' (jika ada) di bagian paling akhir
  /// agar posisi spasi asli tidak bergeser dan tetap dapat didekripsi balik secara utuh.
  static String _applySmartFormat({
    required String originalInput,
    required String pureOutput,
  }) {
    final StringBuffer buffer = StringBuffer();
    int letterIndex = 0;

    for (final int rune in originalInput.runes) {
      if (_isAsciiLetter(rune)) {
        final String outChar = pureOutput[letterIndex++];
        final bool isUpper = _isUpperCaseAscii(rune);
        buffer.write(isUpper ? outChar : outChar.toLowerCase());
      } else {
        buffer.writeCharCode(rune);
      }
    }

    // Jika terjadi penambahan padding saat enkripsi, tempelkan huruf output
    // hasil blok padding di paling akhir teks terformat.
    if (letterIndex < pureOutput.length) {
      buffer.write(pureOutput.substring(letterIndex));
    }

    return buffer.toString();
  }
}
