import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hill_cipher_lab/core/frequency_analyzer.dart';
import 'package:hill_cipher_lab/core/hill_cipher_engine.dart';
import 'package:hill_cipher_lab/core/key_generator.dart';
import 'package:hill_cipher_lab/main.dart';
import 'package:hill_cipher_lab/models/cipher_models.dart';
import 'package:hill_cipher_lab/state/cipher_controller.dart';

void main() {
  group('HillCipherEngine - Aritmetika mod26 & Analisis Kunci', () {
    test('mod26 menangani bilangan positif, nol, dan negatif dengan aman', () {
      expect(HillCipherEngine.mod26(0), 0);
      expect(HillCipherEngine.mod26(25), 25);
      expect(HillCipherEngine.mod26(26), 0);
      expect(HillCipherEngine.mod26(53), 1);
      expect(HillCipherEngine.mod26(-1), 25);
      expect(HillCipherEngine.mod26(-26), 0);
      expect(HillCipherEngine.mod26(-27), 25);
      expect(HillCipherEngine.mod26(-121), 9);
    });

    test('kunci invalid [[2, 4], [1, 2]] memiliki determinan 0 dan ditolak', () {
      final KeyAnalysisResult analysis = HillCipherEngine.analyzeKey(
        const <List<int>>[
          <int>[2, 4],
          <int>[1, 2],
        ],
      );

      expect(analysis.isValid, isFalse);
      expect(analysis.detRaw, 0);
      expect(analysis.detMod, 0);
      expect(analysis.detInverse, isNull);
      expect(analysis.adjugateMatrix, isNull);
      expect(analysis.inverseMatrix, isNull);
      expect(analysis.errorMessage, isNotNull);
    });

    test('kunci berdeterminan genap atau 13 juga ditolak', () {
      final KeyAnalysisResult evenDet = HillCipherEngine.analyzeKey(
        const <List<int>>[
          <int>[2, 0],
          <int>[0, 1],
        ],
      );
      expect(evenDet.isValid, isFalse);
      expect(evenDet.detMod, 2);
      expect(evenDet.detInverse, isNull);

      final KeyAnalysisResult thirteenDet = HillCipherEngine.analyzeKey(
        const <List<int>>[
          <int>[13, 0],
          <int>[0, 1],
        ],
      );
      expect(thirteenDet.isValid, isFalse);
      expect(thirteenDet.detMod, 13);
      expect(thirteenDet.detInverse, isNull);
    });

    test('seluruh preset bawaan di CipherController valid di mod 26', () {
      for (final KeyPreset preset in CipherController.defaultPresets) {
        final KeyAnalysisResult analysis =
            HillCipherEngine.analyzeKey(preset.matrix);
        expect(
          analysis.isValid,
          isTrue,
          reason: 'Preset ${preset.name} harus valid di mod 26',
        );
        expect(analysis.inverseMatrix, isNotNull);
      }
    });
  });

  group('HillCipherEngine - Uji Standar 2x2 & 3x3', () {
    test('Uji 2x2: [[3,3],[2,5]] mengenkripsi "KODE" -> "UMVA" dan dekripsi balik',
        () {
      const List<List<int>> key2x2 = <List<int>>[
        <int>[3, 3],
        <int>[2, 5],
      ];

      final CipherResult encrypted = HillCipherEngine.process(
        inputText: 'KODE',
        keyMatrix: key2x2,
        isEncrypt: true,
      );

      expect(encrypted.cleanedText, 'KODE');
      expect(encrypted.paddingCount, 0);
      expect(encrypted.pureOutput, 'UMVA');
      expect(encrypted.formattedOutput, 'UMVA');
      expect(encrypted.steps.length, 2);
      expect(encrypted.keyAnalysis.detMod, 9);
      expect(encrypted.keyAnalysis.detInverse, 3);

      final CipherResult decrypted = HillCipherEngine.process(
        inputText: encrypted.pureOutput,
        keyMatrix: key2x2,
        isEncrypt: false,
      );

      expect(decrypted.pureOutput, 'KODE');
      expect(decrypted.formattedOutput, 'KODE');
    });

    test('Uji 3x3: kata kunci "GYBNQKURP" mengenkripsi "ACT" -> "POH" dan dekripsi balik',
        () {
      final List<List<int>> key3x3 =
          KeyGenerator.keywordToMatrix('GYBNQKURP', 3);

      expect(key3x3, const <List<int>>[
        <int>[6, 24, 1],
        <int>[13, 16, 10],
        <int>[20, 17, 15],
      ]);
      expect(KeyGenerator.matrixToKeyword(key3x3), 'GYBNQKURP');

      final CipherResult encrypted = HillCipherEngine.process(
        inputText: 'ACT',
        keyMatrix: key3x3,
        isEncrypt: true,
      );

      expect(encrypted.pureOutput, 'POH');
      expect(encrypted.paddingCount, 0);
      expect(encrypted.keyAnalysis.detMod, 25);
      expect(encrypted.keyAnalysis.detInverse, 25);

      final CipherResult decrypted = HillCipherEngine.process(
        inputText: 'POH',
        keyMatrix: key3x3,
        isEncrypt: false,
      );

      expect(decrypted.pureOutput, 'ACT');
    });
  });

  group('HillCipherEngine - Edge Cases & Smart Preserve', () {
    test('"halo dunia" pada 2x2 dengan preserveFormat: true dan padding +1 X', () {
      const List<List<int>> key2x2 = <List<int>>[
        <int>[3, 3],
        <int>[2, 5],
      ];

      final CipherResult encrypted = HillCipherEngine.process(
        inputText: 'halo dunia',
        keyMatrix: key2x2,
        isEncrypt: true,
        preserveFormat: true,
      );

      // "HALODUNIA" berjumlah 9 huruf -> butuh +1 padding 'X' agar kelipatan 2.
      expect(encrypted.cleanedText, 'HALODUNIA');
      expect(encrypted.paddingCount, 1);
      expect(encrypted.paddedText, 'HALODUNIAX');
      expect(encrypted.pureOutput.length, 10);

      // Spasi tetap di indeks ke-4 dan huruf padding di akhir (panjang 11).
      expect(encrypted.formattedOutput.length, 11);
      expect(encrypted.formattedOutput[4], ' ');
      expect(
        encrypted.formattedOutput.substring(0, 4),
        encrypted.formattedOutput.substring(0, 4).toLowerCase(),
      );
      expect(
        encrypted.formattedOutput.substring(5, 10),
        encrypted.formattedOutput.substring(5, 10).toLowerCase(),
      );
      expect(encrypted.formattedOutput[10], encrypted.pureOutput[9]);

      // Uji balik dekripsi dengan preserveFormat: true menghasilkan 'halo duniaX'.
      final CipherResult decrypted = HillCipherEngine.process(
        inputText: encrypted.formattedOutput,
        keyMatrix: key2x2,
        isEncrypt: false,
        preserveFormat: true,
      );
      expect(decrypted.pureOutput, 'HALODUNIAX');
      expect(decrypted.formattedOutput, 'halo duniaX');
    });

    test('"halo dunia" pada 3x3 dengan preserveFormat: true (tanpa padding)', () {
      final List<List<int>> key3x3 =
          KeyGenerator.keywordToMatrix('GYBNQKURP', 3);

      final CipherResult encrypted = HillCipherEngine.process(
        inputText: 'halo dunia',
        keyMatrix: key3x3,
        isEncrypt: true,
        preserveFormat: true,
      );

      // "HALODUNIA" berjumlah 9 huruf -> pas kelipatan 3, paddingCount == 0.
      expect(encrypted.paddingCount, 0);
      expect(encrypted.paddedText, 'HALODUNIA');
      expect(encrypted.formattedOutput.length, 10);
      expect(encrypted.formattedOutput[4], ' ');
      expect(
        encrypted.formattedOutput,
        encrypted.formattedOutput.toLowerCase(),
      );

      final CipherResult decrypted = HillCipherEngine.process(
        inputText: encrypted.formattedOutput,
        keyMatrix: key3x3,
        isEncrypt: false,
        preserveFormat: true,
      );
      expect(decrypted.formattedOutput, 'halo dunia');
    });

    test('input tanpa huruf alfabet "12345 !!!" melempar ArgumentError', () {
      const List<List<int>> key2x2 = <List<int>>[
        <int>[3, 3],
        <int>[2, 5],
      ];

      expect(
        () => HillCipherEngine.process(
          inputText: '12345 !!!',
          keyMatrix: key2x2,
          isEncrypt: true,
        ),
        throwsArgumentError,
      );
    });

    test('dekripsi ciphertext bukan kelipatan ordo melempar ArgumentError', () {
      const List<List<int>> key2x2 = <List<int>>[
        <int>[3, 3],
        <int>[2, 5],
      ];
      final List<List<int>> key3x3 =
          KeyGenerator.keywordToMatrix('GYBNQKURP', 3);

      expect(
        () => HillCipherEngine.process(
          inputText: 'ABC',
          keyMatrix: key2x2,
          isEncrypt: false,
        ),
        throwsArgumentError,
      );

      expect(
        () => HillCipherEngine.process(
          inputText: 'ABCD',
          keyMatrix: key3x3,
          isEncrypt: false,
        ),
        throwsArgumentError,
      );
    });

    test('enkripsi dengan kunci tidak valid melempar ArgumentError', () {
      expect(
        () => HillCipherEngine.process(
          inputText: 'KODE',
          keyMatrix: const <List<int>>[
            <int>[2, 4],
            <int>[1, 2],
          ],
          isEncrypt: true,
        ),
        throwsArgumentError,
      );
    });
  });

  group('KeyGenerator & FrequencyAnalyzer & CipherController', () {
    test('generateValidKey(2) dan generateValidKey(3) selalu menghasilkan kunci valid',
        () {
      final Random rng = Random(42);
      for (int i = 0; i < 20; i++) {
        final List<List<int>> k2 = KeyGenerator.generateValidKey(2, random: rng);
        expect(k2.length, 2);
        expect(HillCipherEngine.analyzeKey(k2).isValid, isTrue);

        final CipherResult enc = HillCipherEngine.process(
          inputText: 'KRIPTOGRAFI',
          keyMatrix: k2,
          isEncrypt: true,
        );
        final CipherResult dec = HillCipherEngine.process(
          inputText: enc.pureOutput,
          keyMatrix: k2,
          isEncrypt: false,
        );
        expect(dec.pureOutput.startsWith('KRIPTOGRAFI'), isTrue);
      }

      for (int i = 0; i < 20; i++) {
        final List<List<int>> k3 = KeyGenerator.generateValidKey(3, random: rng);
        expect(k3.length, 3);
        expect(HillCipherEngine.analyzeKey(k3).isValid, isTrue);

        final CipherResult enc = HillCipherEngine.process(
          inputText: 'MATEMATIKA',
          keyMatrix: k3,
          isEncrypt: true,
        );
        final CipherResult dec = HillCipherEngine.process(
          inputText: enc.pureOutput,
          keyMatrix: k3,
          isEncrypt: false,
        );
        expect(dec.pureOutput.startsWith('MATEMATIKA'), isTrue);
      }
    });

    test('FrequencyAnalyzer menghitung distribusi dan IoC secara akurat', () {
      final FrequencyAnalysisReport report = FrequencyAnalyzer.analyze(
        cleanedInput: 'AAAAABBC',
        pureOutput: 'ABCDEFGH',
      );

      expect(report.inputTotal, 8);
      expect(report.outputTotal, 8);
      expect(report.inputCounts[0], 5);
      expect(report.dominantInputLetters, <String>['A']);
      expect(report.dominantInputCount, 5);
      expect(report.inputIoC, greaterThan(report.outputIoC));
      expect(report.outputIoC, 0.0);
    });

    test('CipherController mempertahankan sel null tanpa memaksa 0 dan menjaga keySyncVersion',
        () {
      final CipherController controller = CipherController();
      final int initialSync = controller.keySyncVersion;

      // Mengosongkan sel [0][0] membuat kunci invalid tapi keySyncVersion tidak naik.
      controller.updateMatrixCell(0, 0, null);
      expect(controller.hasIncompleteCells, isTrue);
      expect(controller.canExecute, isFalse);
      expect(controller.keyAnalysis.isValid, isFalse);
      expect(controller.editableMatrix[0][0], isNull);
      expect(controller.keySyncVersion, initialSync);

      // Mengacak kunci menaikkan keySyncVersion dan mengembalikan validitas.
      controller.randomizeValidKey();
      expect(controller.hasIncompleteCells, isFalse);
      expect(controller.canExecute, isTrue);
      expect(controller.keySyncVersion, initialSync + 1);
    });
  });

  group('Smoke Test UI Widget', () {
    testWidgets('HillCipherLabApp merender tanpa error pada layout Desktop dan Mobile',
        (WidgetTester tester) async {
      // Uji layout Desktop (>= 800 px)
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const HillCipherLabApp());
      await tester.pumpAndSettle();

      expect(find.text('Hill Cipher Lab'), findsOneWidget);
      expect(find.byType(NavigationRail), findsOneWidget);

      // Uji layout Mobile (< 800 px)
      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });
}
