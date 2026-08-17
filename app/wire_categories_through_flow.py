import re

# ---- 1. DataDiscoveryConsentScreen: convert chosen labels -> category keys, pass through ----
path1 = 'lib/screens/home/data_discovery_consent_screen.dart'
with open(path1, 'r') as f:
    c1 = f.read()
orig1 = c1

old_submit = """  void _submit() {
    final chosen = _categories.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PartyGameWelcomeScreen(),
      ),
    );
  }"""
new_submit = """  static const Map<String, String> _labelToCategoryKey = {
    'Photos': 'photos',
    'Location': 'photos',
    'Books': 'books',
    'Movies': 'movies',
  };

  void _submit() {
    final chosenLabels = _categories.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final categoryKeys = chosenLabels
        .map((label) => _labelToCategoryKey[label])
        .whereType<String>()
        .toSet();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PartyGameWelcomeScreen(
          selectedCategories: categoryKeys,
        ),
      ),
    );
  }"""
if old_submit not in c1:
    print("ERROR: consent screen _submit block not found")
else:
    c1 = c1.replace(old_submit, new_submit)
    print("Updated consent screen _submit")

if c1 != orig1:
    with open(path1, 'w') as f:
        f.write(c1)

# ---- 2. PartyGameWelcomeScreen: accept selectedCategories, pass to pair code screen ----
path2 = 'lib/screens/home/party_game_welcome_screen.dart'
with open(path2, 'r') as f:
    c2 = f.read()
orig2 = c2

old_class = """import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'party_game_category_screen.dart';

class PartyGameWelcomeScreen extends StatelessWidget {
  const PartyGameWelcomeScreen({super.key});"""
new_class = """import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'party_game_pair_code_screen.dart';

class PartyGameWelcomeScreen extends StatelessWidget {
  final Set<String> selectedCategories;

  const PartyGameWelcomeScreen({
    super.key,
    this.selectedCategories = const {'photos'},
  });"""
if old_class not in c2:
    print("ERROR: welcome screen class block not found")
else:
    c2 = c2.replace(old_class, new_class)
    print("Updated welcome screen to accept selectedCategories")

old_button = """                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PartyGameCategoryScreen(),
                    ),
                  );
                },
                child: const Text('Choose a category'),"""
new_button = """                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PartyGamePairCodeScreen(
                        selectedCategories: selectedCategories,
                      ),
                    ),
                  );
                },
                child: const Text('Continue'),"""
if old_button not in c2:
    print("ERROR: welcome screen button block not found")
else:
    c2 = c2.replace(old_button, new_button)
    print("Updated welcome screen button to go to pair code screen")

if c2 != orig2:
    with open(path2, 'w') as f:
        f.write(c2)

print("Done with files 1 and 2.")
