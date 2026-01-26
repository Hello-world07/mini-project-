import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CustomerSegmentationPage extends StatefulWidget {
  const CustomerSegmentationPage({super.key});

  @override
  State<CustomerSegmentationPage> createState() =>
      _CustomerSegmentationPageState();
}

class _CustomerSegmentationPageState extends State<CustomerSegmentationPage> {
  bool loading = false;
  Map<String, dynamic>? result;

  // Your NGROK backend URL
final String backendURL = "https://gwyn-unfallen-effusively.ngrok-free.dev/upload_csv/";


  // Pick CSV
  void pickCSV() async {
    final picked = await FilePicker.platform.pickFiles(
      allowedExtensions: ['csv'],
      type: FileType.custom,
      withData: true,
    );

    if (picked == null) return;
    uploadCSV(picked.files.single.bytes!, picked.files.single.name);
  }

  // Save history (only filename)
  Future<void> saveToHistory(String filename) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> names = prefs.getStringList('history_names') ?? [];

    if (names.length >= 5) {
      names.removeAt(0);
    }

    names.add("${DateTime.now()} - $filename");

    await prefs.setStringList('history_names', names);
  }

  // Upload CSV to backend
  Future<void> uploadCSV(Uint8List data, String filename) async {
    setState(() {
      loading = true;
      result = null;
    });

    final url = Uri.parse(backendURL);
    final request = http.MultipartRequest("POST", url);

    request.files.add(http.MultipartFile.fromBytes(
      "file",
      data,
      filename: filename,
    ));

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      setState(() => result = jsonDecode(resBody));
      await saveToHistory(filename);
    } else {
      setState(() => result = {"error": resBody});
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text(
          "Customer Segmentation",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _introCard(),
            const SizedBox(height: 20),
            _uploadCard(),
            const SizedBox(height: 20),
            if (loading) const CircularProgressIndicator(color: Colors.indigo),
            if (result != null) _dashboard(),
          ],
        ),
      ),
    );
  }

  // INTRO CARD
  Widget _introCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What is Customer Segmentation?",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Customer Segmentation groups customers based on behavior such as Spending, Orders, Visits, Age, Income, etc.\n\n"
              "This project uses K-Means Clustering and automatically generates:\n"
              "• Cluster Summary\n"
              "• Cluster Count\n"
              "• Scatter Plot\n"
              "• Heatmap\n"
              "• Box Plot\n"
              "• Bar Chart\n\n"
              "These help analyze customers easily.",
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // UPLOAD CARD
  Widget _uploadCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              "Upload CSV File",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Steps:\n"
              "1. Prepare a CSV file with numeric columns.\n"
              "2. Avoid emojis or special characters.\n"
              "3. Click 'Choose CSV'.\n"
              "4. The ML model generates clusters & charts.",
              textAlign: TextAlign.left,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: pickCSV,
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: const Text(
                "Choose CSV",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                minimumSize: const Size(180, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // DASHBOARD
  Widget _dashboard() {
    if (result!["error"] != null) {
      return Text(
        result!["error"],
        style: const TextStyle(color: Colors.red, fontSize: 16),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Segmentation Results",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _clusterSummaryCard(),
        const SizedBox(height: 12),
        _clusterCountCard(),
        const SizedBox(height: 20),
        const Text(
          "Charts",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _chartTile("Scatter Plot", result!["charts"]["scatter"]),
        _chartTile("Heatmap", result!["charts"]["heatmap"]),
        _chartTile("Box Plot", result!["charts"]["boxplot"]),
        _chartTile("Bar Chart", result!["charts"]["bar"]),
      ],
    );
  }

  // CLUSTER SUMMARY
  Widget _clusterSummaryCard() {
    final summary = result!["cluster_summary"] as Map<String, dynamic>;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Cluster Summary",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...summary.entries.map(
              (e) => Text("Cluster ${e.key}: ${e.value.toString()}"),
            ),
          ],
        ),
      ),
    );
  }

  // CLUSTER COUNT
  Widget _clusterCountCard() {
    final count = result!["cluster_count"] as Map<String, dynamic>;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Cluster Count",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...count.entries.map((e) => Text("Cluster ${e.key}: ${e.value}")),
          ],
        ),
      ),
    );
  }

  // CHART TILE
  Widget _chartTile(String title, String base64img) {
    final bytes = base64Decode(base64img);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(bytes, height: 260, fit: BoxFit.cover),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}