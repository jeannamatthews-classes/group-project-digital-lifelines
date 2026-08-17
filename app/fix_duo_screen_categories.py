path = 'lib/screens/home/party_game_duo_screen.dart'
with open(path, 'r') as f:
    content = f.read()

original = content

# 1. Add selectedCategories field to class
old_class = """class PartyGameDuoScreen extends StatefulWidget {
  final int pairCode;
  const PartyGameDuoScreen({super.key, required this.pairCode});
  @override
  State<PartyGameDuoScreen> createState() => _PartyGameDuoScreenState();
}"""
new_class = """class PartyGameDuoScreen extends StatefulWidget {
  final int pairCode;
  final Set<String> selectedCategories;
  const PartyGameDuoScreen({
    super.key,
    required this.pairCode,
    this.selectedCategories = const {'photos'},
  });
  @override
  State<PartyGameDuoScreen> createState() => _PartyGameDuoScreenState();
}"""
if old_class not in content:
    print("ERROR: class block not found")
else:
    content = content.replace(old_class, new_class)
    print("Added selectedCategories field to PartyGameDuoScreen")

# 2. Add import for party_questions.dart if not already present
if "import '../../data/party_questions.dart';" not in content:
    content = content.replace(
        "import '../../theme/app_theme.dart';",
        "import '../../theme/app_theme.dart';\nimport '../../data/party_questions.dart';"
    )
    print("Added party_questions.dart import")
else:
    print("party_questions.dart import already present")

# 3. Filter the question picker by selectedCategories
old_picker = """  void _showQuestionPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: partyQuestions.length,
            itemBuilder: (context, index) {
              final q = partyQuestions[index];
              return ListTile(
                leading: const Icon(Icons.help_outline_rounded,
                    color: AppColors.primary),
                title: Text(q.question),
                subtitle: Text(q.hint),
                onTap: () {
                  Navigator.pop(context);
                  _pickQuestion(q);
                },
              );
            },
          ),
        );
      },"""
new_picker = """  void _showQuestionPicker() {
    final filteredQuestions =
        findQuestionsByCategories(widget.selectedCategories);
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: filteredQuestions.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No questions available for the selected categories yet.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredQuestions.length,
                  itemBuilder: (context, index) {
                    final q = filteredQuestions[index];
                    return ListTile(
                      leading: const Icon(Icons.help_outline_rounded,
                          color: AppColors.primary),
                      title: Text(q.question),
                      subtitle: Text(q.hint),
                      onTap: () {
                        Navigator.pop(context);
                        _pickQuestion(q);
                      },
                    );
                  },
                ),
        );
      },"""
if old_picker not in content:
    print("ERROR: question picker block not found")
else:
    content = content.replace(old_picker, new_picker)
    print("Updated question picker to filter by selectedCategories")

if content == original:
    print("NOTHING CHANGED")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
