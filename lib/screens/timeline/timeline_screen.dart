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

  // Loads fields and entries for the active timeline and prepares value maps.
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

  // Navigates to add-entry form.
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

  // Navigates to edit-entry form.
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

  // Deletes one entry after user confirmation.
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shadowColor: Colors.red.withValues(alpha: 0.3),
              ),
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

  // Toggles favorite flag and reloads list ordering.
  Future<void> _toggleFavorite(Entry entry) async {
    final entryId = entry.id;
    if (entryId == null) return;

    final nextFavorite = !entry.isFavorite;
    await _dbHelper.setEntryFavorite(
      entryId: entryId,
      isFavorite: nextFavorite,
    );
    await _loadData();
  }

  // Applies favorites filter + text search for the rendered list.
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
        elevation: 0,
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0.5,
        title: Text(
          widget.timeline.name,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.appBarText,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                ),
              ],
            ),
            child: IconButton(
              tooltip: 'Refresh',
              onPressed: _loadData,
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppColors.mutedText,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.accent,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_entries.where((e) => e.entry.isFavorite).length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                        fontSize: 14,
                      ),
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search points...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.mutedText,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      ChoiceChip(
                        selected: !_showFavoritesOnly,
                        onSelected: (_) {
                          setState(() {
                            _showFavoritesOnly = false;
                          });
                        },
                        label: const Text(
                          'All Points',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        selected: _showFavoritesOnly,
                        onSelected: (_) {
                          setState(() {
                            _showFavoritesOnly = true;
                          });
                        },
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: AppColors.accent,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Favorites',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
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
                              timelineName: widget.timeline.name,
                              onToggleFavorite: () =>
                                  _toggleFavorite(item.entry),
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
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Entry',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
    );
  }
}

class _EntryData {
  final Entry entry;
  final Map<int, String> values;

  _EntryData({required this.entry, required this.values});
}
