import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Lifelines',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Digital Lifelines'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final List<String> lifelines = [
    "Interstellar - Movie",
    "I Feel It Coming - Song",
    "The Alchemist - Book",
    "New York City - Place"
  ];

  void addLifeline() {
    setState(() {
      lifelines.add("New Lifeline ${lifelines.length + 1}");
    });
  }

  void removeLifeline() {
    setState(() {
      lifelines.removeAt(lifelines.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),

      body: ListView.builder(
        itemCount: lifelines.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: const Icon(Icons.favorite),
              title: Text(lifelines[index]),
              subtitle: const Text("Tap to view details"),
            ),
          );
        },
      ),

      floatingActionButton: Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    FloatingActionButton(
      onPressed: removeLifeline,
      tooltip: 'Remove Lifeline',
      child: const Icon(Icons.remove),
    ),
    const SizedBox(width: 10),
    FloatingActionButton(
      onPressed: addLifeline,
      tooltip: 'Add Lifeline',
      child: const Icon(Icons.add),
    ),
  ],
),
    );
  }
}