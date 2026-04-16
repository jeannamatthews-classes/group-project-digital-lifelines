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

    await _dbHelper.deleteTimeline(id);
    await _loadTimelines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0.5,
        title: const Text(
          'Digital Lifelines',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 24,
            letterSpacing: -0.5,
            color: AppColors.appBarText,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              tooltip: 'Refresh',
              onPressed: _loadTimelines,
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppColors.mutedText,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              tooltip: 'New Lifeline',
              onPressed: _openCreateTimeline,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _timelines.isEmpty
          ? _EmptyHomeState(onCreate: _openCreateTimeline)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 94),
              itemCount: _timelines.length,
              itemBuilder: (context, index) {
                final timeline = _timelines[index];
                final stats =
                    _statsByTimelineId[timeline.id] ??
                    const _TimelineStats(totalEntries: 0, favoriteEntries: 0);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.grey.shade100,
                        width: 1.5,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => _openTimeline(timeline),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primary.withValues(alpha: 0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.menu_book_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      timeline.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.appBarText,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            '${stats.totalEntries} entries',
                                            style: const TextStyle(
                                              color: AppColors.mutedText,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (stats.favoriteEntries > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.accent
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.star_rounded,
                                                  size: 12,
                                                  color: AppColors.accent,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${stats.favoriteEntries}',
                                                  style: const TextStyle(
                                                    color: AppColors.accent,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert_rounded,
                                  color: AppColors.mutedText,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
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
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit_rounded,
                                          size: 18,
                                          color: AppColors.mutedText,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Edit',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.create_new_folder_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No Lifelines Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.appBarText,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Start mapping your digital life by creating your first custom collection.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Create Lifeline',
                style: TextStyle(letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
