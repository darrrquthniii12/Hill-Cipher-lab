import 'package:flutter/material.dart';

import '../../models/cipher_models.dart';
import '../../state/cipher_controller.dart';
import '../widgets/common_widgets.dart';

/// Tab 4 — Riwayat & Brankas Kunci: preset kunci bawaan 2x2 & 3x3, penyimpanan
/// kunci aktif ke sesi RAM, serta daftar riwayat enkripsi/dekripsi sesi.
class HistoryVaultPage extends StatelessWidget {
  const HistoryVaultPage({
    super.key,
    required this.controller,
  });

  final CipherController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
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
                        child: _buildVaultCard(context),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 6,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _buildHistoryCard(context),
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
                    _buildVaultCard(context),
                    const SizedBox(height: 16),
                    _buildHistoryCard(context),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVaultCard(BuildContext context) {
    final LabColors colors = labColorsOf(context);
    final List<KeyPreset> presets = controller.allPresets;

    return LabSectionCard(
      title: 'Brankas Preset Kunci',
      subtitle: 'Tersedia ${presets.length} preset (bawaan & sesi RAM)',
      icon: Icons.vpn_key_rounded,
      accentColor: colors.emerald,
      trailing: FilledButton.icon(
        onPressed: () => _handleSaveActiveKey(context),
        icon: const Icon(Icons.bookmark_add_outlined, size: 18),
        label: const Text('Simpan Kunci Aktif'),
        style: FilledButton.styleFrom(
          backgroundColor: colors.emerald,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < presets.length; i++) ...<Widget>[
            _PresetTile(
              preset: presets[i],
              onApply: () {
                controller.applyPreset(presets[i]);
                showLabSnackBar(
                  context,
                  'Preset "${presets[i].name}" diterapkan ke Lab',
                );
              },
              onDelete: presets[i].isBuiltIn
                  ? null
                  : () {
                      final String name = presets[i].name;
                      controller.removeSessionPreset(presets[i].id);
                      showLabSnackBar(context, 'Preset "$name" dihapus');
                    },
            ),
            if (i < presets.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context) {
    final LabColors colors = labColorsOf(context);
    final List<HistoryItem> history = controller.historyList;

    return LabSectionCard(
      title: 'Riwayat Sesi (RAM)',
      subtitle:
          'Disimpan sementara di memori selama aplikasi terbuka (${history.length} item)',
      icon: Icons.history_rounded,
      accentColor: colors.cyan,
      trailing: OutlinedButton.icon(
        onPressed: history.isEmpty
            ? null
            : () {
                controller.clearHistory();
                showLabSnackBar(context, 'Riwayat sesi dibersihkan');
              },
        icon: const Icon(Icons.delete_sweep_outlined, size: 18),
        label: const Text('Bersihkan Riwayat'),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.rose,
          side: BorderSide(
            color: history.isEmpty
                ? colors.border
                : colors.rose.withAlpha(140),
          ),
        ),
      ),
      child: history.isEmpty
          ? Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.cardAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.inbox_outlined,
                    size: 40,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Riwayat Sesi Masih Kosong',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Setiap operasi Enkripsi atau Dekripsi di Tab Lab otomatis tercatat di sini untuk uji balik cepat.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => controller.setTabIndex(0),
                    icon: const Icon(Icons.science_outlined, size: 18),
                    label: const Text('Ke Tab Lab Kriptografi'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.cyan,
                      foregroundColor: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < history.length; i++) ...<Widget>[
                  _HistoryTile(
                    item: history[i],
                    onReload: () {
                      controller.loadHistoryItem(history[i]);
                      showLabSnackBar(
                        context,
                        'Riwayat dimuat ulang ke Tab Lab',
                      );
                    },
                  ),
                  if (i < history.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }

  Future<void> _handleSaveActiveKey(BuildContext context) async {
    if (!controller.canExecute) {
      showLabSnackBar(
        context,
        controller.keyAnalysis.errorMessage ??
            'Lengkapi dan pastikan kunci aktif valid sebelum disimpan.',
        isError: true,
      );
      return;
    }

    final String defaultName =
        'Kunci Sesi #${controller.sessionPresets.length + 1} (${controller.order}×${controller.order})';

    final String? confirmedName = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _SavePresetDialog(initialName: defaultName);
      },
    );

    if (confirmedName == null || !context.mounted) {
      return;
    }

    try {
      final KeyPreset saved =
          controller.saveCurrentKeyPreset(customName: confirmedName);
      showLabSnackBar(
        context,
        'Kunci "${saved.name}" disimpan ke Brankas Sesi RAM',
      );
    } on StateError catch (e) {
      showLabSnackBar(context, e.message, isError: true);
    }
  }
}

class _SavePresetDialog extends StatefulWidget {
  const _SavePresetDialog({required this.initialName});

  final String initialName;

  @override
  State<_SavePresetDialog> createState() => _SavePresetDialogState();
}

class _SavePresetDialogState extends State<_SavePresetDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LabColors colors = labColorsOf(context);
    return AlertDialog(
      backgroundColor: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      title: Text(
        'Simpan Kunci Aktif ke RAM',
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
      ),
      content: TextField(
        controller: _nameController,
        autofocus: true,
        maxLength: 40,
        style: TextStyle(color: colors.textPrimary),
        decoration: InputDecoration(
          labelText: 'Nama Preset',
          filled: true,
          fillColor: colors.cardAlt,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_nameController.text),
          style: FilledButton.styleFrom(
            backgroundColor: colors.emerald,
            foregroundColor: Colors.white,
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.preset,
    required this.onApply,
    this.onDelete,
  });

  final KeyPreset preset;
  final VoidCallback onApply;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final LabColors colors = labColorsOf(context);
    final String matrixInline = preset.matrix
        .map((List<int> r) => '[${r.join(', ')}]')
        .join(' ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.cardAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (preset.isBuiltIn ? colors.cyan : colors.emerald)
                      .withAlpha(32),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${preset.order}×${preset.order}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: preset.isBuiltIn ? colors.cyan : colors.emerald,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            preset.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.border.withAlpha(110),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            preset.isBuiltIn ? 'Bawaan' : 'Sesi RAM',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preset.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'K = [$matrixInline]',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (onDelete != null) ...<Widget>[
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'Hapus preset sesi',
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: colors.rose,
                    size: 20,
                  ),
                ),
              ],
              FilledButton.icon(
                onPressed: onApply,
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Pakai Kunci'),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.emerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.item,
    required this.onReload,
  });

  final HistoryItem item;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final LabColors colors = labColorsOf(context);
    final CipherResult res = item.result;
    final Color modeColor = res.isEncrypt ? colors.emerald : colors.cyan;
    final String timeStr = _formatTime(res.timestamp);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.cardAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: modeColor.withAlpha(32),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  res.isEncrypt ? 'ENKRIPSI' : 'DEKRIPSI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: modeColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${res.order}×${res.order} • ${res.steps.length} blok',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                timeStr,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Input: ${_truncate(res.originalInput, 60)}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Output: ${_truncate(res.formattedOutput, 60)}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onReload,
              icon: const Icon(Icons.replay_rounded, size: 17),
              label: const Text('Muat Ulang / Uji Balik'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.cyan,
                side: BorderSide(color: colors.cyan.withAlpha(140)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  static String _truncate(String value, int maxLen) {
    final String singleLine = value.replaceAll('\n', ' ');
    if (singleLine.length <= maxLen) {
      return singleLine;
    }
    return '${singleLine.substring(0, maxLen)}…';
  }
}
