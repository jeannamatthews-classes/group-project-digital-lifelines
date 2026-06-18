import 'package:flutter/material.dart';

import '../../database/db_helper.dart';
import '../../models/timeline.dart';
import '../../theme/app_theme.dart';
import 'create_timeline_screen.dart';
import '../timeline/timeline_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DBHelper _dbHelper = DBHelper.instance;
  List<Timeline> _timelines = [];
  Map<int, _TimelineStats> _statsByTimelineId = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimelines();
  }

  Future<void> _loadTimelines() async {
    final timelines = await _dbHelper.getTimelines();
    final stats = <int, _TimelineStats>{};
    for (final timeline in timelines) {
      final id = timeline.id;
      if (id == null) continue;
      final result = await _dbHelper.getTimelineStats(id);
      stats[id] = _TimelineStats(
        totalEntries: result['total'] ?? 0,
        favoriteEntries: result['favorites'] ?? 0,
      );
    }

    if (!mounted) return;
    setState(() {
      _timelines = timelines;
      _statsByTimelineId = stats;
      _isLoading = false;
    });
  }

  Future<void> _openCreateTimeline() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateTimelineScreen()),
    );

    if (created == true) {
      await _loadTimelines();
    }
  }

  Future<void> _openTimeline(Timeline timeline) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TimelineScreen(timeline: timeline)),
    );
    await _loadTimelines();
  }

  Future<void> _editTimeline(Timeline timeline) async {
    final id = timeline.id;
    if (id == null) return;

    final controller = TextEditingController(text: timeline.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Timeline'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Timeline Name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (newName == null || newName.isEmpty) return;

    await _dbHelper.updateTimelineName(timelineId: id, name: newName);
    await _loadTimelines();
  }

  Future<void> _deleteTimeline(Timeline timeline) async {
    final id = timeline.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Timeline'),
          content: Text('Delete "${timeline.name}" and all its entries?'),
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

    await _dbHelper.deleteTimeline(id);
    await _loadTimelines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Lifelines'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadTimelines,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'New Lifeline',
            onPressed: _openCreateTimeline,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _timelines.isEmpty
          ? _EmptyHomeState(onCreate: _openCreateTimeline)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 94),
              itemCount: _timelines.length,
              itemBuilder: (context, index) {
                final timeline = _timelines[index];
                final stats = _statsByTimelineId[timeline.id] ??
                    const _TimelineStats(totalEntries: 0, favoriteEntries: 0);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _openTimeline(timeline),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.auto_stories_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    timeline.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${stats.totalEntries} entries',
                                    style: const TextStyle(
                                      color: AppColors.mutedText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.favorite_rounded,
                                  size: 14,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${stats.favoriteEntries}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_horiz),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _editTimeline(timeline);
                                } else if (value == 'delete') {
                                  _deleteTimeline(timeline);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _TimelineStats {
  final int totalEntries;
  final int favoriteEntries;

  const _TimelineStats({
    required this.totalEntries,
    required this.favoriteEntries,
  });
}

class _EmptyHomeState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyHomeState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_copy_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'No Lifelines Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first custom lifeline and start recording your favorite moments.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedText),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onCreate,
              child: const Text('Create Lifeline'),
            ),
          ],
        ),
      ),
    );
  }
}
