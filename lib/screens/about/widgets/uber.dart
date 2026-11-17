part of 'about_actions_section.dart';

extension _AboutActionsSectionUber on _AboutActionsSectionState {
  Future<void> _importUberCsvFromFile() => _importCsvFromFile(
    title: 'Import Uber CSV',
    source: 'Uber CSV',
    description:
        'Choose an Uber Eats order details or Rider lifetime trips CSV. '
        'Eats orders go to Favorite Restaurants; completed rides go to Places.',
    parser: parseUberCsv,
  );

  Future<void> _importDoorDashCsvFromFile() => _importCsvFromFile(
    title: 'Import DoorDash CSV',
    source: 'DoorDash CSV',
    description:
        'Choose a DoorDash consumer_order_details CSV. Orders go to Favorite '
        'Restaurants. Delivery addresses are not restaurant addresses and '
        'will not be imported.',
    parser: parseDoorDashCsv,
  );

  Future<void> _importCsvFromFile({
    required String title,
    required String source,
    required String description,
    required Map<String, dynamic> Function(String) parser,
  }) async {
    var importMode = ImportMode.mergeSkipDuplicates;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(description),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ImportMode>(
                      isExpanded: true,
                      initialValue: importMode,
                      decoration: const InputDecoration(
                        labelText: 'Import mode',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: ImportMode.mergeSkipDuplicates,
                          child: Text('Merge & Skip Duplicates'),
                        ),
                        DropdownMenuItem(
                          value: ImportMode.mergeUpdateDuplicates,
                          child: Text('Merge & Update Existing'),
                        ),
                        DropdownMenuItem(
                          value: ImportMode.replaceAll,
                          child: Text('Overwrite Everything'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => importMode = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Choose CSV'),
                ),
              ],
            );
          },
        );
      },
    );
    if (proceed != true) return;

    FilePickerResult? picked;
    try {
      picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File picker unavailable on this platform build'),
        ),
      );
      return;
    }

    if (picked == null || picked.files.isEmpty) return;
    String? csvText;
    try {
      csvText = await _readPickedText(picked.files.first);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to read $source: $error')));
      return;
    }
    if (csvText == null || csvText.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected CSV is empty or unreadable')),
      );
      return;
    }

    Map<String, dynamic> payload;
    try {
      payload = parser(csvText);
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid $source: ${error.message}')),
      );
      return;
    }
    await _runImport(jsonEncode(payload), importMode: importMode);
  }
}
