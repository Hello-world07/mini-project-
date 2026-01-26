import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'customer_segmentation_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<String> names = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      names = prefs.getStringList('history_names') ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload History"),
        backgroundColor: Colors.indigo,
        centerTitle: true,
      ),

      body: names.isEmpty
          ? const Center(
              child: Text(
                "No files uploaded yet",
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: names.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.history, color: Colors.indigo),
                    title: Text(names[index]),
                    subtitle: const Text("Tap to re-upload this CSV file"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomerSegmentationPage(),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
