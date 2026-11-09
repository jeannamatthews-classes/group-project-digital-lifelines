import 'dart:convert';
import 'dart:io';

import 'package:file_saver/file_saver.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../data/timeline_export_archive.dart';
import '../../../database/db_helper.dart';
import '../../../theme/app_theme.dart';

part 'shared.dart';
part 'goodreads.dart';
part 'spotify.dart';
part 'widgets.dart';

class AboutActionsSection extends StatefulWidget {
  const AboutActionsSection({super.key});

  @override
  State<AboutActionsSection> createState() => _AboutActionsSectionState();
}

class _AboutActionsSectionState extends State<AboutActionsSection> {
  final DBHelper _dbHelper = DBHelper.instance;
  bool _isBusy = false;
  String? _lastExportPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Example Lifeline Categories',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniTag(label: 'Books', color: Color(0xFFFF7B7B)),
              _MiniTag(label: 'Movies', color: Color(0xFF6F79FF)),
              _MiniTag(label: 'Songs', color: Color(0xFFFFBF53)),
              _MiniTag(label: 'Places', color: Color(0xFF5CC48E)),
            ],
          ),
          const SizedBox(height: 14),
          _ActionButton(
            onPressed: _isBusy ? null : _showTemplateJson,
            icon: Icons.description_outlined,
            text: 'Show Template JSON',
          ),
          const SizedBox(height: 10),
          _ActionButton(
            onPressed: _isBusy ? null : _exportZipToPhone,
            icon: Icons.archive_outlined,
            text: 'Export Data ZIP to Phone',
          ),
          const SizedBox(height: 10),
          _ActionButton(
            onPressed: _isBusy ? null : _importJson,
            icon: Icons.download_for_offline_outlined,
            text: 'Import JSON (Paste)',
          ),
          const SizedBox(height: 10),
          _ActionButton(
            onPressed: _isBusy ? null : _importJsonFromFile,
            icon: Icons.folder_open_outlined,
            text: 'Import JSON From File',
          ),
          const SizedBox(height: 10),
          _ActionButton(
            onPressed: _isBusy ? null : _importSpotifyJsonFromFile,
            imageAsset: 'assets/spotify.png',
            text: 'Import Spotify JSON',
          ),
          const SizedBox(height: 10),
          _ActionButton(
            onPressed: _isBusy ? null : _importGoodreadsJsonFromFile,
            imageAsset: 'assets/goodreads.png',
            text: 'Import Goodreads JSON',
          ),
          const SizedBox(height: 10),
          _ActionButton(
            onPressed: _isBusy ? null : _importFromPhotos,
            icon: Icons.photo_library_outlined,
            text: 'Import Places from Photos',
          ),
          const SizedBox(height: 10),
          _ActionButton(
            onPressed: _isBusy ? null : _backupToFirebase,
            icon: Icons.cloud_upload_outlined,
            text: 'Backup to Firebase',
          ),
          if (_lastExportPath != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Last export: $_lastExportPath',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_isBusy) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Future<void> _importFromPhotos() async {
    // Shown on every tap so the user can review or change photo access first.
    final proceed = await showDialog<bool>(
      context: context,
      builder: (_) => const _PhotoImportDialog(),
    );
    if (proceed != true || !mounted) return;

    setState(() => _isBusy = true);
    try {
      final result = await _dbHelper.importFromPhotos();
      if (!mounted) return;
      if (!result.permissionGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Photo access is off, so no locations could be read.',
            ),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: PhotoManager.openSetting,
            ),
          ),
        );
        return;
      }
      await _showPhotoImportResult(result);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _showPhotoImportResult(PhotoImportResult result) {
    final scanned = result.photosScanned;
    final withLocation = result.photosWithLocation;
    final photoWord = scanned == 1 ? 'photo' : 'photos';

    final String title;
    final String message;
    if (scanned == 0) {
      title = 'No photos to scan';
      message = result.limitedAccess
          ? 'No photos are shared with the app yet. Tap "Import Places from '
                'Photos" again and use "Choose photos" to pick some.'
          : 'We couldn\'t find any photos on this device.';
    } else if (withLocation == 0) {
      title = '🎉 Nice work!';
      message =
          'None of your $scanned $photoWord have location metadata, '
          'so they don\'t reveal where they were taken. Your locations are '
          'staying private!';
    } else {
      title = 'Scan complete';
      final added = result.placesAdded;
      final addedText = added == 0
          ? 'They were all already in your My Places timeline.'
          : 'Added $added new ${added == 1 ? 'place' : 'places'} to your '
                'My Places timeline.';
      message =
          '$withLocation of your $scanned $photoWord '
          '${withLocation == 1 ? 'has' : 'have'} location metadata, which can '
          'reveal where ${withLocation == 1 ? 'it was' : 'they were'} '
          'taken.\n\n$addedText';
    }

    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _backupToFirebase() async {
    final timelines = await _dbHelper.getTimelines();
    if (timelines.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No timelines to back up!')));
      return;
    }

    final selected = List<bool>.filled(timelines.length, true);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('⚠️ Privacy Notice'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your selected timelines will be sent to Firebase (Google servers). '
                'Choose which ones to back up:',
              ),
              const SizedBox(height: 12),
              ...List.generate(
                timelines.length,
                (i) => CheckboxListTile(
                  title: Text(timelines[i].name),
                  value: selected[i],
                  onChanged: (val) => setStateDialog(() => selected[i] = val!),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes, back up'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final selectedTimelines = [
      for (int i = 0; i < timelines.length; i++)
        if (selected[i]) timelines[i],
    ];

    if (selectedTimelines.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No timelines selected!')));
      return;
    }

    setState(() => _isBusy = true);
    try {
      await _dbHelper.backupSelectedToFirebase(selectedTimelines);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Backed up ${selectedTimelines.length} timeline(s)!',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }
}

/// Explains what the photo import reads and lets the user review or change
/// photo access before importing. Refreshes when the user comes back from
/// the Settings app.
class _PhotoImportDialog extends StatefulWidget {
  const _PhotoImportDialog();

  @override
  State<_PhotoImportDialog> createState() => _PhotoImportDialogState();
}

class _PhotoImportDialogState extends State<_PhotoImportDialog>
    with WidgetsBindingObserver {
  PermissionState? _state;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final state = await PhotoManager.getPermissionState(
      requestOption: DBHelper.photoPermissionOption,
    );
    if (mounted) setState(() => _state = state);
  }

  Future<void> _choosePhotos() async {
    await PhotoManager.presentLimited(type: RequestType.image);
    await _refresh();
  }

  String get _statusText {
    switch (_state) {
      case null:
        return 'Checking photo access…';
      case PermissionState.authorized:
        return 'Full access: all photos will be scanned.';
      case PermissionState.limited:
        return 'Limited access: only the photos you selected will be scanned.';
      case PermissionState.notDetermined:
        return 'You\'ll be asked to allow photo access next.';
      case PermissionState.denied:
      case PermissionState.restricted:
        return 'Photo access is off. Turn it on in Settings to import.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final blocked =
        state == PermissionState.denied || state == PermissionState.restricted;

    return AlertDialog(
      title: const Text('Import Places from Photos'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'We read only the location and date saved in your photos to build '
            'your My Places timeline. Your photos themselves are never '
            'imported, copied, or uploaded.',
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                blocked ? Icons.block : Icons.photo_library_outlined,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _statusText,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          if (state != null && state != PermissionState.notDetermined) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (state == PermissionState.limited)
                  TextButton.icon(
                    onPressed: _choosePhotos,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Choose photos'),
                  ),
                TextButton.icon(
                  onPressed: PhotoManager.openSetting,
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Change access'),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: state == null || blocked
              ? null
              : () => Navigator.pop(context, true),
          child: Text(
            state == PermissionState.notDetermined ? 'Continue' : 'Import',
          ),
        ),
      ],
    );
  }
}
