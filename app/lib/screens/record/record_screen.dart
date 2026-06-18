import 'package:flutter/material.dart';

import '../../database/db_helper.dart';
import '../../models/entry.dart';
import '../../models/field.dart';
import '../../models/timeline.dart';
import '../../models/value.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final DBHelper _dbHelper = DBHelper.instance;
  final Map<int, TextEditingController> _controllers = {};

  List<Timeline> _timelines = [];
  List<TimelineField> _fields = [];
  int? _selectedTimelineId;
  bool _markFavorite = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTimelines();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTimelines() async {
    final timelines = await _dbHelper.getTimelines();
    if (!mounted) return;

    setState(() {
      _timelines = timelines;
      _selectedTimelineId = timelines.isEmpty ? null : timelines.first.id;
      _isLoading = false;
    });

    if (_selectedTimelineId != null) {
      await _loadFieldsForTimeline(_selectedTimelineId!);
    }
  }

  Future<void> _loadFieldsForTimeline(int timelineId) async {
    final fields = await _dbHelper.getFields(timelineId);

    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();

    for (final field in fields) {
      final id = field.id;
      if (id == null) continue;
      _controllers[id] = TextEditingController();
    }

    if (!mounted) return;
    setState(() {
      _fields = fields;
    });
  }

  Future<void> _saveLifePoint() async {
    final timelineId = _selectedTimelineId;
    if (timelineId == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final entryId = await _dbHelper.insertEntry(
        Entry(
          timelineId: timelineId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          isFavorite: _markFavorite,
        ),
      );

      for (final field in _fields) {
        final id = field.id;
        if (id == null) continue;
        await _dbHelper.insertValue(
          EntryValue(
            entryId: entryId,
            fieldId: id,
            value: _controllers[id]?.text.trim() ?? '',
          ),
        );
      }

      for (final controller in _controllers.values) {
        controller.clear();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Life point saved successfully')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Life Point'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isSaving ? null : _loadTimelines,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _timelines.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Create a lifeline first from the Lifelines tab, then you can record points here.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _selectedTimelineId,
                  decoration: const InputDecoration(labelText: 'Lifeline'),
                  items: _timelines
                      .where((t) => t.id != null)
                      .map(
                        (timeline) => DropdownMenuItem<int>(
                          value: timeline.id,
                          child: Text(timeline.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) async {
                    if (value == null) return;
                    setState(() {
                      _selectedTimelineId = value;
                    });
                    await _loadFieldsForTimeline(value);
                  },
                ),
                const SizedBox(height: 14),
                ..._fields.map((field) {
                  final id = field.id;
                  final controller = id == null ? null : _controllers[id];
                  if (controller == null) {
                    return const SizedBox.shrink();
                  }

                  final isNumber = field.type == 'number';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: controller,
                      keyboardType: isNumber
                          ? const TextInputType.numberWithOptions(decimal: true)
                          : TextInputType.text,
                      decoration: InputDecoration(labelText: field.name),
                    ),
                  );
                }),
                const SizedBox(height: 2),
                SwitchListTile(
                  value: _markFavorite,
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          setState(() {
                            _markFavorite = value;
                          });
                        },
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mark as Favorite'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveLifePoint,
                  child: Text(_isSaving ? 'Saving...' : 'Save Life Point'),
                ),
              ],
            ),
    );
  }
}
