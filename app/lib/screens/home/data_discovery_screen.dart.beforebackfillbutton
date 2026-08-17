import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'data_discovery_consent_screen.dart';

class DataDiscoveryScreen extends StatelessWidget {
  const DataDiscoveryScreen({super.key});

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
            const SizedBox(height: 28),
            const Text(
              'Welcome to Data Discovery Mode.',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: AppColors.appBarText,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You can compare data with others who have the Digital '
              'Lifelines app. Simply click "Search for other timelines", '
              'bump phones with the other user, and choose the data '
              'sources that you consent to share in the menu with your '
              'timelines. The person who you compare data with will also '
              'select data sources that they consent to share. You and '
              'the other user will receive questions to ask based on the '
              'data sources you both consented to share. Then, you will '
              'choose the questions you\'re interested in asking the '
              'other person. After the other person approves them, the '
              'app will display the answers to them.',
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.appBarText,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'We hope that this creates an experience where both '
              'people, making more out of their personal data, are able '
              'to learn new and cool insights about each other that they '
              'wouldn\'t have known otherwise.',
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.appBarText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
