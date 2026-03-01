import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _exportLoading = false;

  Future<void> _export() async {
    setState(() => _exportLoading = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final data = await db.exportAll();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      final now = DateTime.now();
      final date =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final filename = 'callibrate_export_$date.json';

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              utf8.encode(jsonString),
              name: filename,
              mimeType: 'application/json',
            ),
          ],
          subject: 'Callibrate-Export',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export fehlgeschlagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportLoading = false);
    }
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Datenbank zurücksetzen?'),
        content: const Text(
          'Alle Vorhersagen, Schätzungen und Auflösungen werden unwiderruflich gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final db = ref.read(appDatabaseProvider);
    await db.resetDatabase();
    ref.invalidate(predictionsStreamProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datenbank zurückgesetzt.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Daten',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Daten exportieren'),
            subtitle: const Text('Alle Vorhersagen als JSON-Datei teilen'),
            trailing: _exportLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _exportLoading ? null : _export,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Gefahrenzone',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: colorScheme.error),
            title: Text(
              'Datenbank zurücksetzen',
              style: TextStyle(color: colorScheme.error),
            ),
            subtitle: const Text('Löscht alle Vorhersagen unwiderruflich'),
            onTap: _confirmReset,
          ),
        ],
      ),
    );
  }
}
