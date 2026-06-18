import 'package:flutter/material.dart';

import '../../database/db_helper.dart';
import '../../models/entry.dart';
import '../../models/field.dart';
import '../../models/timeline.dart';
import '../../models/value.dart';
import 'widgets/field_input.dart';

class AddEntryScreen extends StatefulWidget {
  final Timeline timeline;
  final Entry? entry;

  const AddEntryScreen({super.key, required this.timeline, this.entry});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final DBHelper _dbHelper = DBHelper.instance;
  final Map<int, TextEditingController> _controllers = {};

  List<TimelineField> _fields = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isFavorite = false;

  bool get _isEditMode => widget.entry != null;

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadFields() async {
    final timelineId = widget.timeline.id;
    if (timelineId == null) return;

    final fields = await _dbHelper.getFields(timelineId);
    for (final field in fields) {
      _controllers[field.id!] = TextEditingController();
    }

    if (_isEditMode) {
      final entryId = widget.entry!.id;
      _isFavorite = widget.entry!.isFavorite;
      if (entryId != null) {
        final existingValues = await _dbHelper.getValueMap(entryId);
        for (final field in fields) {
          final fieldId = field.id;
          if (fieldId == null) continue;
          _controllers[fieldId]?.text = existingValues[fieldId] ?? '';
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _fields = fields;
      _isLoading = false;
    });
  }

  Future<void> _saveEntry() async {
    final timelineId = widget.timeline.id;
    if (timelineId == null) return;

    setState(() {
      _isSaving = true;
    });

    int entryId;
    if (_isEditMode) {
      final id = widget.entry!.id;
      if (id == null) return;
      entryId = id;
    } else {
      entryId = await _dbHelper.insertEntry(
        Entry(
          timelineId: timelineId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          isFavorite: _isFavorite,
        ),
      );
    }

    if (_isEditMode) {
      await _dbHelper.setEntryFavorite(
        entryId: entryId,
        isFavorite: _isFavorite,
      );
    }

    for (final field in _fields) {
      final fieldId = field.id;
      if (fieldId == null) continue;

      final text = _controllers[fieldId]?.text.trim() ?? '';

      if (_isEditMode) {
        await _dbHelper.upsertValue(
          entryId: entryId,
          fieldId: fieldId,
          value: text,
        );
      } else {
        await _dbHelper.insertValue(
          EntryValue(entryId: entryId, fieldId: fieldId, value: text),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit Entry' : 'Add Entry')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SwitchListTile(
                    value: _isFavorite,
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() {
                              _isFavorite = value;
                            });
                          },
                    title: const Text('Mark as Favorite'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 14),
                if (_fields.isEmpty)
                  const Text('No fields found for this timeline.')
                else
                  ..._fields.map((field) {
                    final controller = _controllers[field.id];
                    if (controller == null) return const SizedBox.shrink();
                    return FieldInput(field: field, controller: controller);
                  }),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _fields.isEmpty || _isSaving ? null : _saveEntry,
                  child: Text(
                    _isSaving
                        ? 'Saving...'
                        : (_isEditMode ? 'Save Changes' : 'Save Entry'),
                  ),
                ),
              ],
            ),
    );
  }
}
