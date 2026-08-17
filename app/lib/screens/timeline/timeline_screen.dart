import 'package:flutter/material.dart';

import '../../database/db_helper.dart';
import '../../models/entry.dart';
import '../../models/field.dart';
import '../../models/timeline.dart';
import '../../theme/app_theme.dart';
import 'widgets/entry_card.dart';
import 'add_entry_screen.dart';

enum _ViewMode { perPhoto, perDay, perMonth, perYear, perPlace }

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
  _ViewMode _viewMode = _ViewMode.perPhoto;

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
    if (created == true) await _loadData();
  }

  Future<void> _openEditEntry(Entry entry) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEntryScreen(timeline: widget.timeline, entry: entry),
      ),
    );
    if (updated == true) await _loadData();
  }

  Future<void> _deleteEntry(Entry entry) async {
    final entryId = entry.id;
    if (entryId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _dbHelper.deleteEntry(entryId);
    await _loadData();
  }

  Future<void> _toggleFavorite(Entry entry) async {
    final entryId = entry.id;
    if (entryId == null) return;
    await _dbHelper.setEntryFavorite(
      entryId: entryId,
      isFavorite: !entry.isFavorite,
    );
    await _loadData();
  }

  List<_EntryData> get _visibleEntries {
    final query = _searchQuery.trim().toLowerCase();
    return _entries.where((item) {
      if (_showFavoritesOnly && !item.entry.isFavorite) return false;
      if (query.isEmpty) return true;
      return item.values.values.join(' ').toLowerCase().contains(query);
    }).toList();
  }

  // Find field ID by name (case-insensitive)
  int? _fieldIdByName(String name) {
    try {
      return _fields
          .firstWhere(
            (f) => f.name.toLowerCase() == name.toLowerCase(),
          )
          .id;
    } catch (_) {
      return null;
    }
  }

  // Group entries by day: key = "date|country|city"
  List<_GroupedEntry> get _groupedByDay {
    final dateId = _fieldIdByName('date');
    final countryId = _fieldIdByName('country');
    final cityId = _fieldIdByName('city');

    final map = <String, _GroupedEntry>{};

    for (final item in _visibleEntries) {
      final date = dateId != null ? (item.values[dateId] ?? '') : '';
      final country = countryId != null ? (item.values[countryId] ?? '') : '';
      final city = cityId != null ? (item.values[cityId] ?? '') : '';
      final key = '$date|$country|$city';

      if (map.containsKey(key)) {
        map[key]!.count++;
      } else {
        map[key] = _GroupedEntry(
          label: date,
          country: country,
          city: city,
          count: 1,
        );
      }
    }

    final result = map.values.toList();
    result.sort((a, b) => b.label.compareTo(a.label));
    return result;
  }

  // Group entries by month: key = "yyyy-MM|country|city"
  List<_GroupedEntry> get _groupedByMonth {
    final dateId = _fieldIdByName('date');
    final countryId = _fieldIdByName('country');
    final cityId = _fieldIdByName('city');

    final map = <String, _GroupedEntry>{};

    for (final item in _visibleEntries) {
      final date = dateId != null ? (item.values[dateId] ?? '') : '';
      final country = countryId != null ? (item.values[countryId] ?? '') : '';
      final city = cityId != null ? (item.values[cityId] ?? '') : '';

      // Convert "2024-12-15" → "2024-12"
      final month = date.length >= 7 ? date.substring(0, 7) : date;
      final key = '$month|$country|$city';

      if (map.containsKey(key)) {
        map[key]!.count++;
      } else {
        map[key] = _GroupedEntry(
          label: month,
          country: country,
          city: city,
          count: 1,
        );
      }
    }

    final result = map.values.toList();
    result.sort((a, b) => b.label.compareTo(a.label));
    return result;
  }

List<_GroupedEntry> get _groupedByYear {
  final dateId = _fieldIdByName('date');
  final countryId = _fieldIdByName('country');
  final cityId = _fieldIdByName('city');

  final map = <String, _GroupedEntry>{};

  for (final item in _visibleEntries) {
    final date = dateId != null ? (item.values[dateId] ?? '') : '';
    final country = countryId != null ? (item.values[countryId] ?? '') : '';
    final city = cityId != null ? (item.values[cityId] ?? '') : '';

    // Convert "2024-12-15" → "2024"
    final year = date.length >= 4 ? date.substring(0, 4) : date;
    final key = '$year|$country|$city';

    if (map.containsKey(key)) {
      map[key]!.count++;
    } else {
      map[key] = _GroupedEntry(
        label: year,
        country: country,
        city: city,
        count: 1,
      );
    }
  }

  final result = map.values.toList();
  result.sort((a, b) => b.label.compareTo(a.label));
  return result;
}
  List<_GroupedEntry> get _groupedByPlace {
  final countryId = _fieldIdByName('country');
  final cityId = _fieldIdByName('city');

  final map = <String, _GroupedEntry>{};

  for (final item in _visibleEntries) {
    final country = countryId != null ? (item.values[countryId] ?? '') : '';
    final city = cityId != null ? (item.values[cityId] ?? '') : '';
    final key = '$country|$city';

    if (map.containsKey(key)) {
      map[key]!.count++;
    } else {
      map[key] = _GroupedEntry(
        label: city,
        country: country,
        city: city,
        count: 1,
      );
    }
  }

  final result = map.values.toList();
  result.sort((a, b) => b.count.compareTo(a.count));
  return result;
}

  // Check if this timeline has date/country/city fields (i.e. My Places)
  bool get _isPlacesTimeline {
    final names = _fields.map((f) => f.name.toLowerCase()).toSet();
    return names.contains('date') &&
        names.contains('country') &&
        names.contains('city');
  }

  Widget _buildGroupedCard(_GroupedEntry group) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.place_rounded,
                color: AppColors.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                     // color: AppColors.primaryText,
                     color: AppColors.appBarText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _chip(group.country),
                      const SizedBox(width: 6),
                      _chip(group.city),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                const Icon(
                  Icons.photo_library_rounded,
                  size: 16,
                  color: AppColors.mutedText,
                ),
                const SizedBox(height: 2),
                Text(
                  '${group.count}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.accent,
                  ),
                ),
                const Text(
                  'photos',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.mutedText,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _visibleEntries;
    final groupedDay = _groupedByDay;
    final groupedMonth = _groupedByMonth;

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
              icon: const Icon(Icons.refresh_rounded, color: AppColors.mutedText),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.accent, size: 16),
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
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search points...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.mutedText),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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

                // Favorites toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      ChoiceChip(
                        selected: !_showFavoritesOnly,
                        onSelected: (_) => setState(() => _showFavoritesOnly = false),
                        label: const Text('All Points', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        selected: _showFavoritesOnly,
                        onSelected: (_) => setState(() => _showFavoritesOnly = true),
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: 16, color: AppColors.accent),
                            SizedBox(width: 4),
                            Text('Favorites', style: TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // View mode toggle — only show for My Places timeline
                if (_isPlacesTimeline) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    _viewChip('Per Photo', _ViewMode.perPhoto),
    _viewChip('Per Day', _ViewMode.perDay),
    _viewChip('Per Month', _ViewMode.perMonth),
    _viewChip('Per Year', _ViewMode.perYear),
    _viewChip('Places', _ViewMode.perPlace),
  ],
),
                  ),
                ],

                const SizedBox(height: 6),

                // Entry list
                Expanded(
                  child: _viewMode == _ViewMode.perPhoto
                      ? (entries.isEmpty
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
                                  onToggleFavorite: () => _toggleFavorite(item.entry),
                                  onEdit: () => _openEditEntry(item.entry),
                                  onDelete: () => _deleteEntry(item.entry),
                                );
                              },
                            ))
                      : _viewMode == _ViewMode.perDay
                          ? (groupedDay.isEmpty
                              ? const Center(child: Text('No matching entries.'))
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 92),
                                  itemCount: groupedDay.length,
                                  itemBuilder: (context, index) =>
                                      _buildGroupedCard(groupedDay[index]),
                                ))
                          : _viewMode == _ViewMode.perMonth
    ? (groupedMonth.isEmpty
        ? const Center(child: Text('No matching entries.'))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 92),
            itemCount: groupedMonth.length,
            itemBuilder: (context, index) =>
                _buildGroupedCard(groupedMonth[index]),
          ))
    : _viewMode == _ViewMode.perYear
        ? (_groupedByYear.isEmpty
            ? const Center(child: Text('No matching entries.'))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 92),
                itemCount: _groupedByYear.length,
                itemBuilder: (context, index) =>
                    _buildGroupedCard(_groupedByYear[index]),
              ))
    : (_groupedByPlace.isEmpty
        ? const Center(child: Text('No matching entries.'))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 92),
            itemCount: _groupedByPlace.length,
            itemBuilder: (context, index) =>
                _buildGroupedCard(_groupedByPlace[index]),
          )),

                          
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

  Widget _viewChip(String label, _ViewMode mode) {
    final selected = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.grey.shade300,
          ),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 6)]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.mutedText,
          ),
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

class _GroupedEntry {
  final String label;
  final String country;
  final String city;
  int count;

  _GroupedEntry({
    required this.label,
    required this.country,
    required this.city,
    required this.count,
  });
}