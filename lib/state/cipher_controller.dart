import 'package:flutter/material.dart';

import '../core/hill_cipher_engine.dart';
import '../core/key_generator.dart';
import '../models/cipher_models.dart';

/// Pengelola state terpusat untuk seluruh aplikasi Hill Cipher Lab.
///
/// Berjalan 100% di memori (RAM) tanpa database maupun penyimpanan eksternal.
class CipherController extends ChangeNotifier {
  CipherController() {
    _editableMatrix = _cloneNullableMatrix(_defaultMatrixForOrder(2));
    _keywordText = KeyGenerator.nullableMatrixToKeyword(_editableMatrix);
    _recalculateKeyAnalysis();
  }

  /// Daftar preset kunci bawaan yang selalu tersedia setiap aplikasi dijalankan.
  static final List<KeyPreset> defaultPresets = <KeyPreset>[
    const KeyPreset(
      id: 'builtin_2x2_classic',
      name: 'Klasik 2×2 [[3,3],[2,5]]',
      order: 2,
      matrix: <List<int>>[
        <int>[3, 3],
        <int>[2, 5],
      ],
      keyword: 'DDCF',
      description: 'Preset buku ajar standar • Det mod 26 = 9 (Det⁻¹ = 3)',
    ),
    const KeyPreset(
      id: 'builtin_2x2_hill',
      name: 'Kata Kunci "HILL"',
      order: 2,
      matrix: <List<int>>[
        <int>[7, 8],
        <int>[11, 11],
      ],
      keyword: 'HILL',
      description: 'Dari kata HILL (7,8,11,11) • Det mod 26 = 15 (Det⁻¹ = 7)',
    ),
    const KeyPreset(
      id: 'builtin_2x2_alt',
      name: 'Matriks 2×2 [[5,8],[17,3]]',
      order: 2,
      matrix: <List<int>>[
        <int>[5, 8],
        <int>[17, 3],
      ],
      keyword: 'FIRD',
      description: 'Matriks dengan invers bersih • Det mod 26 = 9 (Det⁻¹ = 3)',
    ),
    const KeyPreset(
      id: 'builtin_3x3_gybnqkurp',
      name: 'Kata Kunci "GYBNQKURP"',
      order: 3,
      matrix: <List<int>>[
        <int>[6, 24, 1],
        <int>[13, 16, 10],
        <int>[20, 17, 15],
      ],
      keyword: 'GYBNQKURP',
      description: 'Contoh klasik 3×3 (ACT → POH) • Det mod 26 = 25 (Det⁻¹ = 25)',
    ),
    const KeyPreset(
      id: 'builtin_3x3_alt',
      name: 'Matriks 3×3 [[2,4,5],[9,2,1],[3,17,7]]',
      order: 3,
      matrix: <List<int>>[
        <int>[2, 4, 5],
        <int>[9, 2, 1],
        <int>[3, 17, 7],
      ],
      keyword: 'CEFJCBDRH',
      description: 'Variasi 3×3 valid • Det mod 26 = 21 (Det⁻¹ = 5)',
    ),
  ];

  ThemeMode _themeMode = ThemeMode.dark;
  int _activeTabIndex = 0;
  int _order = 2;
  KeyInputMode _keyInputMode = KeyInputMode.numbers;

  late List<List<int?>> _editableMatrix;
  late KeyAnalysisResult _keyAnalysis;

  String _keywordText = '';
  String _inputText = '';
  bool _preserveFormat = false;
  CipherResult? _lastResult;

  /// Counter sinkronisasi untuk kotak matriks angka.
  /// HANYA bertambah saat kunci berubah dari luar (ganti ordo, acak kunci,
  /// pilih preset, muat riwayat, atau input dari mode Kata Kunci).
  int _keySyncVersion = 0;
  int _keywordSyncVersion = 0;
  int _inputSyncVersion = 0;

  int _idSequence = 0;
  final List<HistoryItem> _historyList = <HistoryItem>[];
  final List<KeyPreset> _sessionPresets = <KeyPreset>[];

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  int get activeTabIndex => _activeTabIndex;
  int get order => _order;
  KeyInputMode get keyInputMode => _keyInputMode;
  List<List<int?>> get editableMatrix => _editableMatrix;
  KeyAnalysisResult get keyAnalysis => _keyAnalysis;
  String get keywordText => _keywordText;
  String get inputText => _inputText;
  bool get preserveFormat => _preserveFormat;
  CipherResult? get lastResult => _lastResult;
  int get keySyncVersion => _keySyncVersion;
  int get keywordSyncVersion => _keywordSyncVersion;
  int get inputSyncVersion => _inputSyncVersion;
  List<HistoryItem> get historyList => List<HistoryItem>.unmodifiable(_historyList);
  List<KeyPreset> get sessionPresets =>
      List<KeyPreset>.unmodifiable(_sessionPresets);
  List<KeyPreset> get allPresets =>
      List<KeyPreset>.unmodifiable(<KeyPreset>[..._sessionPresets, ...defaultPresets]);

  /// True jika masih ada minimal satu sel matriks yang dikosongkan (`null`).
  bool get hasIncompleteCells {
    for (int r = 0; r < _order; r++) {
      for (int c = 0; c < _order; c++) {
        if (_editableMatrix[r][c] == null) {
          return true;
        }
      }
    }
    return false;
  }

  /// Tombol Enkripsi/Dekripsi hanya aktif bila seluruh sel terisi dan kunci valid.
  bool get canExecute => !hasIncompleteCells && _keyAnalysis.isValid;

  /// Mengganti tema antara Dark Mode dan Light Mode.
  void toggleThemeMode() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  /// Berpindah ke tab navigasi utama (0: Lab, 1: Bedah Rumus, 2: Frekuensi, 3: Riwayat).
  void setTabIndex(int index) {
    if (index < 0 || index > 3 || index == _activeTabIndex) {
      return;
    }
    _activeTabIndex = index;
    notifyListeners();
  }

  /// Mengubah ordo matriks (2 atau 3) dan memuat kunci bawaan yang sesuai.
  void setOrder(int newOrder) {
    if ((newOrder != 2 && newOrder != 3) || newOrder == _order) {
      return;
    }
    _order = newOrder;
    _editableMatrix = _cloneNullableMatrix(_defaultMatrixForOrder(newOrder));
    _keywordText = KeyGenerator.nullableMatrixToKeyword(_editableMatrix);
    _recalculateKeyAnalysis();
    _keySyncVersion++;
    _keywordSyncVersion++;
    notifyListeners();
  }

  /// Mengganti mode pengisian kunci antara input Angka dan Kata Kunci.
  void setKeyInputMode(KeyInputMode mode) {
    if (mode == _keyInputMode) {
      return;
    }
    _keyInputMode = mode;
    if (mode == KeyInputMode.keyword) {
      _keywordText = KeyGenerator.nullableMatrixToKeyword(_editableMatrix);
      _keywordSyncVersion++;
    } else {
      _keySyncVersion++;
    }
    notifyListeners();
  }

  /// Memperbarui satu sel matriks saat user mengetik di kotak angka.
  ///
  /// Sengaja TIDAK menaikkan [keySyncVersion] agar kursor pada `TextField`
  /// yang sedang fokus tidak terganggu atau melompat.
  void updateMatrixCell(int row, int col, int? value) {
    if (row < 0 || row >= _order || col < 0 || col >= _order) {
      return;
    }
    if (_editableMatrix[row][col] == value) {
      return;
    }
    _editableMatrix[row][col] = value;
    _keywordText = KeyGenerator.nullableMatrixToKeyword(_editableMatrix);
    _keywordSyncVersion++;
    _recalculateKeyAnalysis();
    notifyListeners();
  }

  /// Memperbarui matriks kunci berdasarkan masukan teks di mode Kata Kunci.
  ///
  /// Menaikkan [keySyncVersion] karena perubahan datang dari luar kotak angka.
  void updateFromKeyword(String rawKeyword) {
    final String cleaned = HillCipherEngine.sanitizeAlphabet(rawKeyword);
    final int maxLen = _order * _order;
    final String limited =
        cleaned.length > maxLen ? cleaned.substring(0, maxLen) : cleaned;

    _keywordText = limited;
    _editableMatrix = KeyGenerator.keywordToNullableMatrix(limited, _order);
    _recalculateKeyAnalysis();
    _keySyncVersion++;
    notifyListeners();
  }

  /// Membangkitkan matriks kunci acak yang dijamin valid di mod 26.
  void randomizeValidKey() {
    final List<List<int>> generated = KeyGenerator.generateValidKey(_order);
    _editableMatrix = _toNullableMatrix(generated);
    _keywordText = KeyGenerator.matrixToKeyword(generated);
    _recalculateKeyAnalysis();
    _keySyncVersion++;
    _keywordSyncVersion++;
    notifyListeners();
  }

  /// Menerapkan preset kunci, menaikkan [keySyncVersion], dan opsional pindah ke Tab Lab.
  void applyPreset(KeyPreset preset, {bool switchToLab = true}) {
    _order = preset.order;
    _editableMatrix = _toNullableMatrix(preset.matrix);
    _keywordText = preset.keyword ?? KeyGenerator.matrixToKeyword(preset.matrix);
    _recalculateKeyAnalysis();
    _keySyncVersion++;
    _keywordSyncVersion++;
    if (switchToLab) {
      _activeTabIndex = 0;
    }
    notifyListeners();
  }

  /// Menyimpan kunci aktif saat ini ke daftar preset sesi RAM.
  KeyPreset saveCurrentKeyPreset({String? customName}) {
    if (!canExecute) {
      throw StateError(
        'Kunci harus lengkap dan valid di mod 26 sebelum disimpan.',
      );
    }

    final List<List<int>> normalized = _keyAnalysis.matrix
        .map((List<int> row) => List<int>.from(row))
        .toList(growable: false);
    final String keyword = KeyGenerator.matrixToKeyword(normalized);
    final int nextNumber = _sessionPresets.length + 1;
    final String trimmed = (customName ?? '').trim();
    final String finalName = trimmed.isNotEmpty
        ? trimmed
        : 'Kunci Sesi #$nextNumber (${_order}×$_order)';

    final KeyPreset preset = KeyPreset(
      id: 'session_${++_idSequence}',
      name: finalName,
      order: _order,
      matrix: normalized,
      keyword: keyword,
      description:
          'Kata "$keyword" • Det mod 26 = ${_keyAnalysis.detMod} (Det⁻¹ = ${_keyAnalysis.detInverse})',
      isBuiltIn: false,
    );

    _sessionPresets.insert(0, preset);
    notifyListeners();
    return preset;
  }

  /// Menghapus preset buatan sesi berdasarkan ID.
  void removeSessionPreset(String presetId) {
    _sessionPresets.removeWhere((KeyPreset p) => p.id == presetId);
    notifyListeners();
  }

  /// Memperbarui teks masukan pengguna tanpa menaikkan [inputSyncVersion].
  void setInputText(String text) {
    _inputText = text;
  }

  /// Mengaktifkan atau menonaktifkan mode Smart Preserve Space & Capitalization.
  void setPreserveFormat(bool value) {
    if (_preserveFormat == value) {
      return;
    }
    _preserveFormat = value;
    notifyListeners();
  }

  /// Menjalankan enkripsi atau dekripsi menggunakan state kunci dan pesan aktif.
  CipherResult executeCipher({required bool isEncrypt}) {
    if (!canExecute) {
      throw ArgumentError(
        _keyAnalysis.errorMessage ?? 'Matriks kunci belum siap digunakan.',
      );
    }

    final List<List<int>> keyMatrix = List<List<int>>.generate(
      _order,
      (int r) => List<int>.generate(
        _order,
        (int c) => _editableMatrix[r][c]!,
      ),
    );

    final CipherResult result = HillCipherEngine.process(
      inputText: _inputText,
      keyMatrix: keyMatrix,
      isEncrypt: isEncrypt,
      preserveFormat: _preserveFormat,
    );

    _lastResult = result;
    _historyList.insert(
      0,
      HistoryItem(
        id: 'hist_${++_idSequence}',
        result: result,
        preserveFormat: _preserveFormat,
      ),
    );
    if (_historyList.length > 200) {
      _historyList.removeLast();
    }
    notifyListeners();
    return result;
  }

  /// Memindahkan output aktif ke kolom input untuk uji balik enkripsi/dekripsi cepat.
  bool swapOutputToInput() {
    final CipherResult? current = _lastResult;
    if (current == null) {
      return false;
    }
    _inputText = _preserveFormat ? current.formattedOutput : current.pureOutput;
    _inputSyncVersion++;
    notifyListeners();
    return true;
  }

  /// Memuat ulang item riwayat ke Lab Kriptografi (kunci, input, mode format)
  /// dan membuka Tab Lab.
  void loadHistoryItem(HistoryItem item) {
    final CipherResult res = item.result;
    _order = res.order;
    _editableMatrix = _toNullableMatrix(res.keyAnalysis.matrix);
    _keywordText = KeyGenerator.matrixToKeyword(res.keyAnalysis.matrix);
    _preserveFormat = item.preserveFormat;
    _inputText = res.originalInput;
    _lastResult = res;

    _recalculateKeyAnalysis();
    _keySyncVersion++;
    _keywordSyncVersion++;
    _inputSyncVersion++;
    _activeTabIndex = 0;
    notifyListeners();
  }

  /// Menghapus seluruh daftar riwayat di RAM.
  void clearHistory() {
    _historyList.clear();
    notifyListeners();
  }

  /// Mengosongkan kolom input dan hasil output terakhir di Tab Lab.
  void resetLab() {
    _inputText = '';
    _lastResult = null;
    _inputSyncVersion++;
    notifyListeners();
  }

  void _recalculateKeyAnalysis() {
    if (hasIncompleteCells) {
      _keyAnalysis = KeyAnalysisResult.incomplete(
        order: _order,
        editableMatrix: _editableMatrix,
      );
      return;
    }

    final List<List<int>> solid = List<List<int>>.generate(
      _order,
      (int r) => List<int>.generate(
        _order,
        (int c) => _editableMatrix[r][c]!,
      ),
    );
    _keyAnalysis = HillCipherEngine.analyzeKey(solid);
  }

  static List<List<int?>> _defaultMatrixForOrder(int order) {
    if (order == 2) {
      return <List<int?>>[
        <int?>[3, 3],
        <int?>[2, 5],
      ];
    }
    return <List<int?>>[
      <int?>[6, 24, 1],
      <int?>[13, 16, 10],
      <int?>[20, 17, 15],
    ];
  }

  static List<List<int?>> _cloneNullableMatrix(List<List<int?>> source) {
    return source
        .map((List<int?> row) => List<int?>.from(row))
        .toList(growable: false);
  }

  static List<List<int?>> _toNullableMatrix(List<List<int>> source) {
    return source
        .map((List<int> row) => row.map<int?>((int v) => v).toList())
        .toList(growable: false);
  }
}
