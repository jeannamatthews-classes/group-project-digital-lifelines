path = 'lib/screens/home/party_game_duo_screen.dart'
with open(path, 'r') as f:
    content = f.read()

old = """        title: const Text(
          'Ask & Answer',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.appBarText,
            letterSpacing: -0.5,
          ),
        ),
      ),"""

new = """        title: Text(
          'Ask & Answer  \\u2022  Code ${widget.pairCode}',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.appBarText,
            letterSpacing: -0.5,
            fontSize: 16,
          ),
        ),
      ),"""

if old not in content:
    print("ERROR: appbar title block not found")
else:
    content = content.replace(old, new)
    with open(path, 'w') as f:
        f.write(content)
    print("Done! Pair code now shown in the app bar.")
