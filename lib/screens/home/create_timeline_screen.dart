import 'package:flutter/material.dart';

import '../../database/db_helper.dart';
import '../../models/field.dart';
import '../../models/timeline.dart';

class CreateTimelineScreen extends StatefulWidget {
  const CreateTimelineScreen({super.key});

  @override
  State<CreateTimelineScreen> createState() => _CreateTimelineScreenState();
}

class _CreateTimelineScreenState extends State<CreateTimelineScreen> {
  final DBHelper _dbHelper = DBHelper.instance;
  final TextEditingController _timelineNameController = TextEditingController();
  final List<_FieldDraft> _fieldDrafts = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _addFieldDraft();
  }

  @override
  void dispose() {
    _timelineNameController.dispose();
    for (final draft in _fieldDrafts) {
      draft.controller.dispose();
    }
    super.dispose();
  }

  // Adds one field row in the form.
  void _addFieldDraft() {
    setState(() {
      _fieldDrafts.add(_FieldDraft());
    });
  }

  // Removes a field row and disposes its controller.
  void _removeFieldDraft(int index) {
    final draft = _fieldDrafts[index];
    draft.controller.dispose();
    setState(() {
      _fieldDrafts.removeAt(index);
    });
  }

  // Validates form, creates timeline, then inserts all configured fields.
  Future<void> _saveTimeline() async {
    final timelineName = _timelineNameController.text.trim();
    if (timelineName.isEmpty) {
      _showMessage('Please enter timeline name');
      return;
    }

    final validDrafts = _fieldDrafts
        .where((draft) => draft.controller.text.trim().isNotEmpty)
        .toList();

    if (validDrafts.isEmpty) {
      _showMessage('Please add at least one field');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final timelineId = await _dbHelper.insertTimeline(
      Timeline(name: timelineName),
    );

    for (final draft in validDrafts) {
      await _dbHelper.insertField(
        TimelineField(
          timelineId: timelineId,
          name: draft.controller.text.trim(),
          type: draft.type,
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });
    Navigator.pop(context, true);
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Timeline')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'What would you like to name your lifeline?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _timelineNameController,
            decoration: const InputDecoration(
              hintText: 'Books, Movies, Songs...',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'List entry parameters',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._fieldDrafts.asMap().entries.map((entry) {
            final index = entry.key;
            final draft = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: draft.controller,
                      decoration: const InputDecoration(
                        labelText: 'Parameter Name',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: draft.type,
                      items: const [
                        DropdownMenuItem(value: 'text', child: Text('text')),
                        DropdownMenuItem(
                          value: 'number',
                          child: Text('number'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          draft.type = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Parameter Type',
                      ),
                    ),
                    if (_fieldDrafts.length > 1)
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => _removeFieldDraft(index),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Remove'),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
          OutlinedButton.icon(
            onPressed: _addFieldDraft,
            icon: const Icon(Icons.add),
            label: const Text('Add Parameter'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveTimeline,
            child: Text(_isSaving ? 'Saving...' : 'Save Lifeline'),
          ),
        ],
      ),
    );
  }
}

class _FieldDraft {
  final TextEditingController controller = TextEditingController();
  String type = 'text';
}
