import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' show join;
import 'package:sqflite/sqflite.dart';

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
  static const MethodChannel _filesChannel = MethodChannel(
    'digitallifelines/files',
  );

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
            onPressed: _isBusy ? null : _exportJsonToPhone,
            icon: Icons.upload_file_outlined,
            text: 'Export Data JSON to Phone',
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
}