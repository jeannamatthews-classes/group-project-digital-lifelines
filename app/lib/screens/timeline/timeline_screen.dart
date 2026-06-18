import 'package:flutter/material.dart';

import '../../database/db_helper.dart';
import '../../models/entry.dart';
import '../../models/field.dart';
import '../../models/timeline.dart';
import '../../theme/app_theme.dart';
import 'widgets/entry_card.dart';
import 'add_entry_screen.dart';

class TimelineScreen extends StatefulWidget {
  final Timeline timeline;

  const TimelineScreen({super.key, required this.timeline});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final DBHelper _dbHelper = DBHelper.instance;

  List<TimelineField> _fields = [];
  List<_EntryData> _entries = [];
  bool _isLoading = true;
  bool _showFavoritesOnly = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final timelineId = widget.timeline.id;
    if (timelineId == null) return;

    final fields = await _dbHelper.getFields(timelineId);
    final entries = await _dbHelper.getEntries(timelineId);

    final entryData = <_EntryData>[];
    for (final entry in entries) {
      final values = await _dbHelper.getValues(entry.id!);
      final map = <int, String>{for (final v in values) v.fieldId: v.value};
      entryData.add(_EntryData(entry: entry, values: map));
    }

    if (!mounted) return;
    setState(() {
      _fields = fields;
      _entries = entryData;
      _isLoading = false;
    });
  }

  Future<void> _openAddEntry() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEntryScreen(timeline: widget.timeline),
      ),
    );

    if (created == true) {
      await _loadData();
    }
  }

  Future<void> _openEditEntry(Entry entry) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEntryScreen(timeline: widget.timeline, entry: entry),
      ),
    );

    if (updated == true) {
      await _loadData();
    }
  }

  Future<void> _deleteEntry(Entry entry) async {
    final entryId = entry.id;
    if (entryId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Entry'),
          content: const Text('Are you sure you want to delete this entry?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _dbHelper.deleteEntry(entryId);
    await _loadData();
  }

  Future<void> _toggleFavorite(Entry entry) async {
    final entryId = entry.id;
    if (entryId == null) return;

    final nextFavorite = !entry.isFavorite;
    await _dbHelper.setEntryFavorite(entryId: entryId, isFavorite: nextFavorite);
    await _loadData();
  }

  List<_EntryData> get _visibleEntries {
    final query = _searchQuery.trim().toLowerCase();

    return _entries.where((item) {
      if (_showFavoritesOnly && !item.entry.isFavorite) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final fieldText = item.values.values.join(' ').toLowerCase();
      return fieldText.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _visibleEntries;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.timeline.name),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.accent,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_entries.where((e) => e.entry.isFavorite).length}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search life points...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      ChoiceChip(
                        selected: !_showFavoritesOnly,
                        onSelected: (_) {
                          setState(() {
                            _showFavoritesOnly = false;
                          });
                        },
                        label: const Text('All'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        selected: _showFavoritesOnly,
                        onSelected: (_) {
                          setState(() {
                            _showFavoritesOnly = true;
                          });
                        },
                        label: const Text('Favorites'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: entries.isEmpty
                      ? const Center(child: Text('No matching entries.'))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 92),
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final item = entries[index];

                            return EntryCard(
                              entry: item.entry,
                              fields: _fields,
                              valuesByFieldId: item.values,
                              onToggleFavorite: () => _toggleFavorite(item.entry),
                              onEdit: () => _openEditEntry(item.entry),
                              onDelete: () => _deleteEntry(item.entry),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddEntry,
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }
}

class _EntryData {
  final Entry entry;
  final Map<int, String> values;

  _EntryData({required this.entry, required this.values});
}
