import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../database/db_helper.dart';
import 'data_discovery_search_screen.dart';

class DataDiscoveryScreen extends StatefulWidget {
  const DataDiscoveryScreen({super.key});

  @override
  State<DataDiscoveryScreen> createState() => _DataDiscoveryScreenState();
}

class _DataDiscoveryScreenState extends State<DataDiscoveryScreen> {
  bool _isBackfilling = false;

  Future<void> _runBackfill() async {
    setState(() {
      _isBackfilling = true;
    });
    final count = await DBHelper.instance.backfillPhotoCoordinates();
    if (!mounted) return;
    setState(() {
      _isBackfilling = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Backfilled coordinates for $count photos')),
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
          'Discover something you didn\'t know',
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
            const Text(
              'One question. One yes. One real answer.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _StepIcon(
                  icon: Icons.radio_button_unchecked_rounded,
                  label: 'Connect',
                  caption: 'Bump phones',
                ),
                _StepIcon(
                  icon: Icons.crop_square_rounded,
                  label: 'Ask',
                  caption: 'Send a question',
                ),
                _StepIcon(
                  icon: Icons.access_time_rounded,
                  label: 'Reveal',
                  caption: 'Get an answer',
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Divider(height: 1),
            const SizedBox(height: 24),
            const Text(
              'WHY IT\'S DIFFERENT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'They choose what to share, before they know what '
              'you\'ll ask.',
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.appBarText,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'They approve answering before they even see the answer.',
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.appBarText,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Say no, and we\'ll show you who already knows anyway.',
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.appBarText,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DataDiscoverySearchScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Start discovering',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isBackfilling ? null : _runBackfill,
                icon: _isBackfilling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded, size: 18),
                label: Text(_isBackfilling
                    ? 'Backfilling...'
                    : 'Backfill photo coordinates (dev)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final String caption;

  const _StepIcon({
    required this.icon,
    required this.label,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.appBarText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          caption,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.mutedText,
          ),
        ),
      ],
    );
  }
}
