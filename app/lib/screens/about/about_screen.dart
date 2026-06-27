import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'widgets/about_actions_section.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  int _refreshToken = 0;

  // Rebuilds AboutActionsSection with a new key to refresh its local state.
  void _refresh() {
    setState(() {
      _refreshToken++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Info'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          const _HeroHeader(),
          const SizedBox(height: 14),
          const _InfoCard(),
          const SizedBox(height: 14),
          AboutActionsSection(key: ValueKey(_refreshToken)),
          const SizedBox(height: 14),
          const _FooterNote(),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEDF2FF), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE3FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_graph_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Digital Lifelines',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 3),
                Text(
                  'Capture what matters and keep your favorite moments close.',
                  style: TextStyle(color: AppColors.mutedText, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What is Digital Lifelines?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Digital Lifelines is a flexible journaling app where each lifeline can have custom fields. Save entries quickly, mark favorites, and keep your records offline.',
            style: TextStyle(color: AppColors.mutedText, height: 1.35),
          ),
          SizedBox(height: 12),
          Text('How it works', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text(
            '1) Create lifelines and define fields\n2) Record life points and mark favorites\n3) Export or import JSON for backup and migration',
            style: TextStyle(color: AppColors.mutedText, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Digital Lifelines Project',
        style: TextStyle(color: AppColors.mutedText, fontSize: 12),
      ),
    );
  }
}
