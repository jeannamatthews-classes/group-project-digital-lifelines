import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'data_discovery_consent_screen.dart';

class DataDiscoverySearchScreen extends StatelessWidget {
  const DataDiscoverySearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0.5,
        title: const Text(
          'Data Discovery Mode',
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
              'Search for other lifelines to connect with.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 24),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DataDiscoveryConsentScreen(
                      friendName: 'Bob',
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search_rounded,
                        color: AppColors.mutedText, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Search for other timelines',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
