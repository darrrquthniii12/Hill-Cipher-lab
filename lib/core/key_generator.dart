import 'dart:math';

import 'hill_cipher_engine.dart';

/// Utilitas untuk membangkitkan matriks kunci acak yang valid di modulo 26
/// serta mengonversi antara format kata kunci (huruf A-Z) dan matriks persegi.
class KeyGenerator {
  const KeyGenerator._();

  /// Menghasilkan matriks kunci berukuran [order]x[order] (2 atau 3) secara acak
  /// dengan elemen bernilai 0..25 yang dipastikan valid (invertible di mod 26).
  static List<List<int>> generateValidKey(int order, {Random? random}) {
    if (order != 2 && order != 3) {
      throw ArgumentError('Ordo matriks kunci harus 2 atau 3.');
    }

    final Random rng = random ?? Random();

    // Ulangi pembangkitan elemen acak 0..25 sampai determinan relatif prima dengan 26.
    while (true) {
      final List<List<int>> candidate = List<List<int>>.generate(
        order,
        (_) => List<int>.generate(order, (_) => rng.nextInt(26)),
      );

      if (HillCipherEngine.analyzeKey(candidate).isValid) {
        return candidate;
      }
    }
  }

  /// Mengonversi string kata kunci (minimal 4 huruf untuk 2x2 atau 9 huruf untuk 3x3)
  /// menjadi matriks integer [order]x[order] bernilai A=0 .. Z=25.
  ///
  /// Karakter non-alfabet diabaikan secara otomatis. Jika huruf kurang dari `order * order`,
  /// fungsi melempar `ArgumentError`.
  static List<List<int>> keywordToMatrix(String keyword, int order) {
    if (order != 2 && order != 3) {
      throw ArgumentError('Ordo matriks kunci harus 2 atau 3.');
    }

    final String cleaned = HillCipherEngine.sanitizeAlphabet(keyword);
    final int requiredLength = order * order;

    if (cleaned.length < requiredLength) {
      throw ArgumentError(
        'Kata kunci untuk ordo ${order}x$order wajib terdiri dari $requiredLength huruf A-Z.',
      );
    }

    return List<List<int>>.generate(order, (int r) {
      return List<int>.generate(order, (int c) {
        final int charIndex = (r * order) + c;
        return cleaned.codeUnitAt(charIndex) - 65;
      });
    });
  }

  /// Versi parsial dari `keywordToMatrix` untuk mendukung pengisian langsung di UI.
  ///
  /// Huruf yang belum diketik diisi `null` agar antarmuka menandai matriks belum lengkap
  /// tanpa memaksa angka kembali ke 0.
  static List<List<int?>> keywordToNullableMatrix(String keyword, int order) {
    final String cleaned = HillCipherEngine.sanitizeAlphabet(keyword);
    return List<List<int?>>.generate(order, (int r) {
      return List<int?>.generate(order, (int c) {
        final int charIndex = (r * order) + c;
        if (charIndex < cleaned.length) {
          return cleaned.codeUnitAt(charIndex) - 65;
        }
        return null;
      });
    });
  }

  /// Mengonversi matriks integer menjadi string huruf kapital A-Z secara berurutan per baris.
  static String matrixToKeyword(List<List<int>> matrix) {
    final StringBuffer buffer = StringBuffer();
    for (final List<int> row in matrix) {
      for (final int value in row) {
        buffer.writeCharCode(HillCipherEngine.mod26(value) + 65);
      }
    }
    return buffer.toString();
  }

  /// Mengonversi matriks yang mungkin memiliki sel kosong (`null`) menjadi huruf A-Z
  /// untuk sel yang terisi, digunakan saat berpindah dari mode Angka ke mode Kata Kunci.
  static String nullableMatrixToKeyword(List<List<int?>> matrix) {
    final StringBuffer buffer = StringBuffer();
    for (final List<int?> row in matrix) {
      for (final int? value in row) {
        if (value != null) {
          buffer.writeCharCode(HillCipherEngine.mod26(value) + 65);
        }
      }
    }
    return buffer.toString();
  }
}
