import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'party_game_pair_code_screen.dart';

class PartyGameCategoryScreen extends StatelessWidget {
  const PartyGameCategoryScreen({super.key});

  void _pickPhoto(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PartyGamePairCodeScreen(),
      ),
    );
  }

  void _pickMusic(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Music questions are coming soon!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0.5,
        title: const Text(
          'Choose a Category',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.appBarText,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'What kind of questions do you want to ask?',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.appBarText,
              ),
            ),
            const SizedBox(height: 20),
            _CategoryCard(
              icon: Icons.photo_camera_rounded,
              title: 'Photo',
              subtitle: 'Questions based on your photo timeline',
              enabled: true,
              onTap: () => _pickPhoto(context),
            ),
            const SizedBox(height: 16),
            _CategoryCard(
              icon: Icons.music_note_rounded,
              title: 'Music',
              subtitle: 'Coming soon',
              enabled: false,
              onTap: () => _pickMusic(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.primary.withValues(alpha: 0.06)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: enabled
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: enabled
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: enabled ? AppColors.primary : AppColors.mutedText,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: enabled
                            ? AppColors.appBarText
                            : AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: enabled ? AppColors.primary : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
